/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowRsv_ampseq.initialise(params, log)

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

// Config file
ch_summary_dummy_file = file("$baseDir/assets/summary_dummy_file.tsv", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Loaded from modules/local
//
include { EDIT_IVAR_VARIANTS        } from '../modules/local/editivarvariants'
include { SUMMARY                   } from '../modules/local/summary'
include { SUMMARY_CLEANUP           } from '../modules/local/summary_cleanup'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK               } from '../subworkflows/local/input_check'
include { PREPARE_GENOME            } from '../subworkflows/local/prepare_genome'
include { SELECT_REFERENCE          } from '../subworkflows/local/select_reference'
include { IVAR_PRIMER_TRIM          } from '../subworkflows/local/ivar_primer_trim'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { IVAR_VARIANTS             } from '../modules/nf-core/ivar/variants/main'
include { IVAR_CONSENSUS            } from '../modules/nf-core/ivar/consensus/main'
include { BCFTOOLS_MPILEUP          } from '../modules/nf-core/bcftools/mpileup/main'

//
// SUBWORKFLOW: Consisting of entirely of nf-core/modules
//
include { FASTQ_TRIM_FASTP_FASTQC   } from '../subworkflows/nf-core/fastq_trim_fastp_fastqc/main'
include { FASTQ_ALIGN_BOWTIE2       } from '../subworkflows/nf-core/fastq_align_bowtie2/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow RSV_AMPSEQ {

    INPUT_CHECK (
        ch_input
    )

    PREPARE_GENOME () 

    FASTQ_TRIM_FASTP_FASTQC (
        INPUT_CHECK.out.reads,
        file(params.adapter_fasta),
        params.save_trimmed_fail,
        params.save_merged,
        params.skip_fastp,
        params.skip_fastqc
    )

    FASTQ_TRIM_FASTP_FASTQC.out.trim_reads_fail_min
        .collect()
        .set { ch_trim_fail_min_summary }

    SELECT_REFERENCE (
        FASTQ_TRIM_FASTP_FASTQC.out.trim_reads_pass_min,
        PREPARE_GENOME.out.RSVA_RSVB_ref
    )

	FASTQ_ALIGN_BOWTIE2 ( 
        SELECT_REFERENCE.out.reads,
        PREPARE_GENOME.out.bowtie2_index_RSVA,
        PREPARE_GENOME.out.bowtie2_index_RSVB,
		params.save_bowtie2_unaligned,
		false
	)

    FASTQ_ALIGN_BOWTIE2.out.flagstat
        .map { meta, ref, flagstat -> [ meta, ref ] + CheckReads.getFlagstatMappedReads(flagstat, params) }
        .set { ch_mapped_reads }

    ch_mapped_reads
        .map { meta, ref, mapped, pass -> if (!pass) [ meta, ref, mapped ] }
        .join(FASTQ_TRIM_FASTP_FASTQC.out.reads_num, by: [0])
        .map {
            meta, ref, mapped, num_reads, num_trimmed_reads ->
            [ "$meta.id\t$ref.type\t$num_reads\t$num_trimmed_reads\t0\t$mapped\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0" ]
        }
        .collect()
        .set { ch_align_ref_fail_summary }

    ch_mapped_reads
        .map { meta, ref, mapped, pass -> if (pass) [ meta, ref ] }
        .join(FASTQ_ALIGN_BOWTIE2.out.bam, by: [0, 1])
        .join(FASTQ_ALIGN_BOWTIE2.out.bai, by: [0, 1])
        .multiMap { meta, ref, bam, bai -> 
            bam:    [ meta, ref, bam ]
            bai:    [ meta, ref, bai ]
        }.set { ch_variants_consensus }

    if (!params.skip_ivar_trim) {
        IVAR_PRIMER_TRIM (
            ch_variants_consensus.bam,
            ch_variants_consensus.bai,
            PREPARE_GENOME.out.primer_bed_RSVA,
            PREPARE_GENOME.out.primer_bed_RSVB,
            []
        )
        ch_bam = IVAR_PRIMER_TRIM.out.bam
        ch_bai = IVAR_PRIMER_TRIM.out.bai
    } else {
        ch_bam = ch_variants_consensus.bam
        ch_bai = ch_variants_consensus.bai
    }

    BCFTOOLS_MPILEUP (
        ch_bam,
        PREPARE_GENOME.out.RSVA_ref,
        PREPARE_GENOME.out.RSVB_ref,
        params.save_mpileup
    )

    IVAR_VARIANTS (
        ch_bam,
        PREPARE_GENOME.out.RSVA_ref,
        PREPARE_GENOME.out.RSVB_ref,
        PREPARE_GENOME.out.ref_gff_RSVA,
        PREPARE_GENOME.out.ref_gff_RSVB,
        false
    )

    EDIT_IVAR_VARIANTS (
        IVAR_VARIANTS.out.tsv,
        PREPARE_GENOME.out.ref_gff_RSVA,
        PREPARE_GENOME.out.ref_gff_RSVB
    )

    IVAR_CONSENSUS (
        ch_bam,
        PREPARE_GENOME.out.RSVA_ref,
        PREPARE_GENOME.out.RSVB_ref,
        params.save_mpileup
    ) 

    ch_bam
        .join(ch_bai, by: [0,1])
        .join(IVAR_CONSENSUS.out.fasta, by: [0,1])
        .join(FASTQ_TRIM_FASTP_FASTQC.out.trim_log)
        .set { ch_summary }
    
    SUMMARY ( ch_summary )

    ch_align_ref_fail_summary
        .concat( ch_trim_fail_min_summary )
        .map { tsvdata -> CheckReads.tsvFromList(tsvdata) }
        .collectFile(storeDir: "${params.output}/summary", name:"fail_summary.tsv", keepHeader: true, sort: false)
        .set { ch_fail_summary }

    SUMMARY.out.summary_tsv
        .collectFile(storeDir: "${params.output}/summary", name:"pass_summary.tsv", keepHeader: true, sort: true)
        .set { ch_pass_summary }

    SUMMARY_CLEANUP (
        ch_fail_summary.ifEmpty(ch_summary_dummy_file),
        ch_pass_summary.ifEmpty(ch_summary_dummy_file)
    )

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.adaptivecard(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

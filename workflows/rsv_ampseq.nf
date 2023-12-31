/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
WorkflowRsv_ampseq.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config, params.fasta ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

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

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK               } from '../subworkflows/local/input_check'
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

    FASTQ_TRIM_FASTP_FASTQC (
        INPUT_CHECK.out.reads,
        file(params.adapter_fasta),
        params.save_trimmed_fail,
        params.save_merged,
        params.skip_fastp,
        params.skip_fastqc
    )

    SELECT_REFERENCE (
        FASTQ_TRIM_FASTP_FASTQC.out.reads,
        file(params.fasta)
    )

	FASTQ_ALIGN_BOWTIE2 ( 
        SELECT_REFERENCE.out.reads,
        params.bowtie2_index_RSVA,
        params.bowtie2_index_RSVB,
		params.save_bowtie2_unaligned,
		false
	)

	IVAR_PRIMER_TRIM (
		FASTQ_ALIGN_BOWTIE2.out.bam,
        FASTQ_ALIGN_BOWTIE2.out.bai,
        params.primer_bed_RSVA,
        params.primer_bed_RSVB,
        []
	)

    BCFTOOLS_MPILEUP (
        IVAR_PRIMER_TRIM.out.bam,
        params.ref_RSVA,
        params.ref_RSVB,
        params.save_mpileup
    )

    IVAR_VARIANTS (
        IVAR_PRIMER_TRIM.out.bam,
        params.ref_RSVA,
        params.ref_RSVB,
        params.ref_gff_RSVA,
        params.ref_gff_RSVB,
        false
    )

    EDIT_IVAR_VARIANTS (
        IVAR_VARIANTS.out.tsv,
        params.ref_gff_RSVA,
        params.ref_gff_RSVB
    )

    IVAR_CONSENSUS (
        IVAR_PRIMER_TRIM.out.bam,
        params.ref_RSVA,
        params.ref_RSVB,
        params.save_mpileup
    ) 

    IVAR_PRIMER_TRIM.out.bam
        .join(IVAR_PRIMER_TRIM.out.bai, by: [0,1])
        .join(IVAR_CONSENSUS.out.fasta, by: [0,1])
        .join(FASTQ_TRIM_FASTP_FASTQC.out.trim_log)
        .set { ch_summary }
    
    SUMMARY ( ch_summary )

    SUMMARY.out.summary_tsv
        .collectFile(storeDir: "${params.output}", name:"${params.run_name}_summary.tsv", keepHeader: true, sort: true)

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

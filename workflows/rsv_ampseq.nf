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
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Loaded from modules/local
//
include { PICK_REF } from '../modules/local/pickref'
include { EDIT_IVAR_VARIANTS } from '../modules/local/editivarvariants'
include { SUMMARY } from '../modules/local/summary'
include { CLEANUP } from '../modules/local/cleanup'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { IVAR_PRIMER_TRIM } from '../subworkflows/local/ivar_primer_trim'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { BBMAP_ALIGN                 } from '../modules/nf-core/bbmap/align/main'
include { IVAR_VARIANTS               } from '../modules/nf-core/ivar/variants/main'
include { IVAR_CONSENSUS              } from '../modules/nf-core/ivar/consensus/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { BCFTOOLS_MPILEUP            } from '../modules/nf-core/bcftools/mpileup/main'

//
// SUBWORKFLOW: Consisting of entirely of nf-core/modules
//
include { FASTQ_TRIM_FASTP_FASTQC     } from '../subworkflows/nf-core/fastq_trim_fastp_fastqc/main'
include { FASTQ_ALIGN_BOWTIE2		  } from '../subworkflows/nf-core/fastq_align_bowtie2/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow RSV_AMPSEQ {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    INPUT_CHECK (
        ch_input
    )
    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    //ch_fastqc_multiqc = Channel.empty()
    //ch_fastp_multiqc  = Channel.empty()
    FASTQ_TRIM_FASTP_FASTQC (
        INPUT_CHECK.out.reads,
        params.adapter_fasta,
        params.save_trimmed_fail,
        params.save_merged,
        params.skip_fastp,
        params.skip_fastqc
    )
    //ch_fastqc_multiqc = FASTQ_TRIM_FASTP_FASTQC.out.trim_json
    //ch_fastp_multiqc.mix(FASTQ_TRIM_FASTP_FASTQC.out.fastqc_raw_zip, FASTQ_TRIM_FASTP_FASTQC.out.fastqc_trim_zip)
    ch_versions = ch_versions.mix(FASTQ_TRIM_FASTP_FASTQC.out.versions.first())

	BBMAP_ALIGN (
		FASTQ_TRIM_FASTP_FASTQC.out.reads,
		params.fasta
	)

	PICK_REF (
		BBMAP_ALIGN.out.align_covstats,
		params.fasta,
		params.primer_bed_RSVA,
		params.ref_gff_RSVA,
		params.primer_bed_RSVB,
		params.ref_gff_RSVB
	)
	
    FASTQ_TRIM_FASTP_FASTQC.out.reads.join(PICK_REF.out.rsv_ref_bowtie2_index).set{ch_fastq_bowtie2_index}
	FASTQ_ALIGN_BOWTIE2 ( 
        ch_fastq_bowtie2_index,
		//FASTQ_TRIM_FASTP_FASTQC.out.reads,
        //PICK_REF.out.rsv_ref_bowtie2_index,
		//ch_fastq_align_bowtie2_index,
		params.save_bowtie2_unaligned,
		false,
        []
	)

	FASTQ_ALIGN_BOWTIE2.out.bam.join(FASTQ_ALIGN_BOWTIE2.out.bai).join(PICK_REF.out.rsv_primer_bed).set{ch_ivar_primer_trim_bam_bed}
	IVAR_PRIMER_TRIM (
		ch_ivar_primer_trim_bam_bed,
        []
	)

    BCFTOOLS_MPILEUP (
        IVAR_PRIMER_TRIM.out.bam,
        params.fasta,
        params.save_mpileup
    )

    IVAR_PRIMER_TRIM.out.bam.join(PICK_REF.out.rsv_ref_fasta).join(PICK_REF.out.rsv_ref_gff).set{ch_ivar_variants_bam_fasta_gff}
    //IVAR_PRIMER_TRIM.out.bam.join(PICK_REF.out.rsv_ref_gff).map { meta, reads, gff -> [ meta, gff ] }.set { ch_ivar_variants_ref_gff }

    IVAR_VARIANTS (
        ch_ivar_variants_bam_fasta_gff,
        [],
        //IVAR_PRIMER_TRIM.out.bam,
        //ch_ivar_variants_ref_fasta,
        //ch_ivar_variants_ref_gff,
        false
    )

    IVAR_VARIANTS.out.tsv.join(PICK_REF.out.rsv_ref_gff).set{ch_edit_ivar_variants_tsv_gff} 
    EDIT_IVAR_VARIANTS (
        ch_edit_ivar_variants_tsv_gff,
    )

    IVAR_PRIMER_TRIM.out.bam.join(PICK_REF.out.rsv_ref_fasta).set{ch_ivar_consensus_bam_fasta}
    IVAR_CONSENSUS (
        ch_ivar_consensus_bam_fasta,
        //IVAR_PRIMER_TRIM.out.bam,
        //ch_ivar_consensus_ref_fasta,
        params.save_mpileup
    ) 

    FASTQ_TRIM_FASTP_FASTQC.out.trim_log
        .join(IVAR_PRIMER_TRIM.out.bam)
        .join(IVAR_PRIMER_TRIM.out.bai)
        .join(IVAR_CONSENSUS.out.fasta)
        .join(PICK_REF.out.rsv_type)
        .map { meta, trim_log, bam, bai, fasta, rsv_type -> [ meta, trim_log, bam, bai, fasta, rsv_type] }
        .set {ch_summary}
    //IVAR_PRIMER_TRIM.out.bam.join(IVAR_CONSENSUS.out.fasta).map { meta, bam, fasta -> [ meta, fasta ]}.set {ch_summary_consensus}
    //IVAR_PRIMER_TRIM.out.bam.join(PICK_REF.out.rsv_type).map { meta, bam, rsv_type -> [ meta, rsv_type] }.set {ch_summary_rsv_type}
    
    SUMMARY (
        ch_summary
    )
        
    CLEANUP ( SUMMARY.out.summary_tsv.collect() )

    //CUSTOM_DUMPSOFTWAREVERSIONS (
    //    ch_versions.unique().collectFile(name: 'collated_versions.yml')
    //)

    //
    // MODULE: MultiQC
    //
    //workflow_summary    = WorkflowRsv_ampseq.paramsSummaryMultiqc(workflow, summary_params)
    //ch_workflow_summary = Channel.value(workflow_summary)

    //methods_description    = WorkflowRsv_ampseq.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    //ch_methods_description = Channel.value(methods_description)

    //ch_multiqc_files = Channel.empty()
    //ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    //ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    //ch_multiqc_files = ch_multiqc_files.mix(ch_fastqc_multiqc.collect{it[1]}.ifEmpty([]))
    //ch_multiqc_files = ch_multiqc_files.mix(ch_fastp_multiqc.collect{it[1]}.ifEmpty([]))

    //MULTIQC (
    //    ch_multiqc_files.collect(),
    //    ch_multiqc_config.collect().ifEmpty([]),
    //    ch_multiqc_custom_config.collect().ifEmpty([]),
    //    ch_multiqc_logo.collect().ifEmpty([])
    //)
    //multiqc_report = MULTIQC.out.report.toList()
    //ch_versions    = ch_versions.mix(MULTIQC.out.versions)

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

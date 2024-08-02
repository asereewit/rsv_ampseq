//
// Read QC and trimming
//

include { FASTQC as FASTQC_RAW  } from '../../../modules/nf-core/fastqc/main'
include { FASTQC as FASTQC_TRIM } from '../../../modules/nf-core/fastqc/main'
include { FASTP                 } from '../../../modules/nf-core/fastp/main'

workflow FASTQ_TRIM_FASTP_FASTQC {
    take:
    ch_reads              // channel: [ val(meta), path(reads)  ]
    ch_adapter_fasta      // channel: [ path(fasta) ]
    val_save_trimmed_fail // value: boolean
    val_save_merged       // value: boolean
    val_skip_fastp        // value: boolean
    val_skip_fastqc       // value: boolean

    main:

    ch_versions = Channel.empty()

    ch_fastqc_raw_html = Channel.empty()
    ch_fastqc_raw_zip  = Channel.empty()

    if (!val_skip_fastqc) {
        FASTQC_RAW (
            ch_reads
        )
        ch_fastqc_raw_html  = FASTQC_RAW.out.html
        ch_fastqc_raw_zip   = FASTQC_RAW.out.zip
        ch_versions         = ch_versions.mix(FASTQC_RAW.out.versions.first())
    }

    ch_trim_reads        = ch_reads
    ch_trim_json         = Channel.empty()
    ch_trim_html         = Channel.empty()
    ch_trim_log          = Channel.empty()
    ch_trim_reads_fail   = Channel.empty()
    ch_trim_reads_merged = Channel.empty()
    ch_fastqc_trim_html  = Channel.empty()
    ch_fastqc_trim_zip   = Channel.empty()

    if (!val_skip_fastp) {
        FASTP (
            ch_reads,
            ch_adapter_fasta,
            val_save_trimmed_fail,
            val_save_merged
        )
        ch_trim_reads        = FASTP.out.reads
        ch_trim_json         = FASTP.out.json
        ch_trim_html         = FASTP.out.html
        ch_trim_log          = FASTP.out.log
        ch_fastp_trim_fail   = FASTP.out.reads_fail
        ch_trim_reads_merged = FASTP.out.reads_merged
        ch_versions          = ch_versions.mix(FASTP.out.versions.first())

        //
        // Filter empty FastQ files after adapter trimming so FastQC doesn't fail
        //
        ch_trim_reads
            .join(ch_trim_json)
            .map {
                meta, reads, json ->
                    num_reads = CheckReads.getFastpReadsBeforeFiltering(json)
                    num_trimmed_reads = CheckReads.getFastpReadsAfterFiltering(json)
                    pass = num_trimmed_reads > params.min_trim_reads
                    [ meta, reads, num_reads, num_trimmed_reads, pass ] }
            .set { ch_pass_fail_reads }

        ch_pass_fail_reads
            .map { meta, reads, num_reads, num_trimmed_reads, pass -> if (pass) [ meta, reads ] }
            .set { ch_trim_reads_pass_min }

        ch_pass_fail_reads
            .map {
                meta, reads, num_reads, num_trimmed_reads, pass ->
                if (!pass) [ "$meta.id\tNA\t$num_reads\t$num_trimmed_reads\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0\t0" ] }
            .set { ch_trim_reads_fail_min }

        ch_pass_fail_reads
            .map { meta, reads, num_reads, num_trimmed_reads, pass -> [ meta, num_reads, num_trimmed_reads ] }
            .set { ch_reads_num }

        if (!val_skip_fastqc) {
            FASTQC_TRIM (
                ch_trim_reads_pass_min
            )
            ch_fastqc_trim_html = FASTQC_TRIM.out.html
            ch_fastqc_trim_zip  = FASTQC_TRIM.out.zip
            ch_versions         = ch_versions.mix(FASTQC_TRIM.out.versions.first())
        }
    }

    emit:
    trim_reads_pass_min = ch_trim_reads_pass_min    // channel: [ val(meta), path(reads) ]
    trim_reads_fail_min = ch_trim_reads_fail_min    // channel: [ val(trim_reads_fail_min_summary_stats) ]  
    reads_num           = ch_reads_num              // channel: [ val(meta), val(num_reads), val(num_trimmed_reads) ]
    trim_json           = ch_trim_json              // channel: [ val(meta), path(json) ]
    trim_html           = ch_trim_html              // channel: [ val(meta), path(html) ]
    trim_log            = ch_trim_log               // channel: [ val(meta), path(log) ]
    fastp_trim_fail     = ch_fastp_trim_fail        // channel: [ val(meta), path(fastq.gz) ]
    trim_reads_merged   = ch_trim_reads_merged      // channel: [ val(meta), path(fastq.gz) ]

    fastqc_raw_html     = ch_fastqc_raw_html        // channel: [ val(meta), path(html) ]
    fastqc_raw_zip      = ch_fastqc_raw_zip         // channel: [ val(meta), path(zip) ]
    fastqc_trim_html    = ch_fastqc_trim_html       // channel: [ val(meta), path(html) ]
    fastqc_trim_zip     = ch_fastqc_trim_zip        // channel: [ val(meta), path(zip) ]
    versions            = ch_versions.ifEmpty(null) // channel: [ path(versions.yml) ]
}

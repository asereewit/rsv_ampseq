include { IVAR_TRIM               } from '../../modules/nf-core/ivar/trim/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../nf-core/bam_sort_stats_samtools/main'

workflow IVAR_PRIMER_TRIM {

    take:
    ch_bam  // channel: [ val(meta), path(bam) ]
    ch_bai  // channel: [ val(meta), path(bai) ]
    ch_rsva_primer_bed // channel: /path/to/rsva_primer_bed
    ch_rsvb_primer_bed // channel: /path/to/rsvb_primer_bed
    ch_fasta

    main:

    ch_versions = Channel.empty()

    IVAR_TRIM (
        ch_bam,
        ch_bai,
        ch_rsva_primer_bed,
        ch_rsvb_primer_bed,
    )

    BAM_SORT_STATS_SAMTOOLS (
        IVAR_TRIM.out.bam,
        ch_fasta
    )

    emit:
    bam_orig = IVAR_TRIM.out.bam
    log_out  = IVAR_TRIM.out.log

    bam      = BAM_SORT_STATS_SAMTOOLS.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = BAM_SORT_STATS_SAMTOOLS.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), [ csi ] ]
    stats    = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}


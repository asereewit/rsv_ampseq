include { IVAR_TRIM               } from '../../modules/nf-core/ivar/trim/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../nf-core/bam_sort_stats_samtools/main'

workflow IVAR_PRIMER_TRIM {

    take:
    ch_bam  // channel: [ val(meta), val(ref), path(bam) ]
    ch_bai  // channel: [ val(meta), val(ref), path(bai) ]
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

    bam      = BAM_SORT_STATS_SAMTOOLS.out.bam          // channel: [ val(meta), val(ref), [ bam ] ]
    bai      = BAM_SORT_STATS_SAMTOOLS.out.bai          // channel: [ val(meta), val(ref), [ bai ] ]
    csi      = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), val(ref), [ csi ] ]
    stats    = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), val(ref), [ stats ] ]
    flagstat = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), val(ref), [ flagstat ] ]
    idxstats = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), val(ref), [ idxstats ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}


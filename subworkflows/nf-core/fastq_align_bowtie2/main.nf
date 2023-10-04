//
// Alignment with Bowtie2
//

include { BOWTIE2_ALIGN           } from '../../../modules/nf-core/bowtie2/align/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../bam_sort_stats_samtools/main'

workflow FASTQ_ALIGN_BOWTIE2 {
    take:
    ch_reads            // channel: [ val(meta), val(ref), [ reads ] ]
    ch_rsva_index       // channel: /path/to/bowtie2/rsva_index/
    ch_rsvb_index       // channel: /path/to/bowtie2/rsvb_index/
    save_unaligned      // val
    sort_bam            // val

    main:

    ch_versions = Channel.empty()

    //
    // Map reads with Bowtie2
    //
    BOWTIE2_ALIGN (
        ch_reads,
        ch_rsva_index,
        ch_rsvb_index,
        save_unaligned,
        sort_bam
    )
    ch_versions = ch_versions.mix(BOWTIE2_ALIGN.out.versions.first())

    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_STATS_SAMTOOLS ( BOWTIE2_ALIGN.out.bam, [] )
    ch_versions = ch_versions.mix(BAM_SORT_STATS_SAMTOOLS.out.versions)

    emit:
    bam_orig         = BOWTIE2_ALIGN.out.bam          // channel: [ val(meta), val(ref), bam   ]
    log_out          = BOWTIE2_ALIGN.out.log          // channel: [ val(meta), val(ref), log   ]
    fastq            = BOWTIE2_ALIGN.out.fastq        // channel: [ val(meta), val(ref), fastq ]

    bam              = BAM_SORT_STATS_SAMTOOLS.out.bam      // channel: [ val(meta), val(ref), [ bam ] ]
    bai              = BAM_SORT_STATS_SAMTOOLS.out.bai      // channel: [ val(meta), val(ref), [ bai ] ]
    csi              = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), val(ref), [ csi ] ]
    stats            = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), val(ref), [ stats ] ]
    flagstat         = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), val(ref), [ flagstat ] ]
    idxstats         = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), val(ref), [ idxstats ] ]
    
    versions         = ch_versions                      // channel: [ versions.yml ]
}

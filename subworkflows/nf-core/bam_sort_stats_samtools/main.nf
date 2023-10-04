//
// Sort, index BAM file and run samtools stats, flagstat and idxstats
//

include { SAMTOOLS_SORT      } from '../../../modules/nf-core/samtools/sort/main'
include { SAMTOOLS_INDEX     } from '../../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS } from '../bam_stats_samtools/main'

workflow BAM_SORT_STATS_SAMTOOLS {
    take:
    ch_bam   // channel: [ val(meta), val(ref), [ bam ] ]
    ch_fasta // channel: [ fasta ]

    main:

    ch_versions = Channel.empty()

    SAMTOOLS_SORT ( ch_bam )
    ch_versions = ch_versions.mix(SAMTOOLS_SORT.out.versions.first())

    SAMTOOLS_INDEX ( SAMTOOLS_SORT.out.bam )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    SAMTOOLS_SORT.out.bam
        .join(SAMTOOLS_INDEX.out.bai, by: [0,1], remainder: true)
        .join(SAMTOOLS_INDEX.out.csi, by: [0,1], remainder: true)
        .map {
            meta, ref_type, bam, bai, csi ->
                if (bai) {
                    [ meta, ref_type, bam, bai ]
                } else {
                    [ meta, ref_type, bam, csi ]
                }
        }
        .set { ch_bam_bai }

    BAM_STATS_SAMTOOLS ( ch_bam_bai, ch_fasta )
    ch_versions = ch_versions.mix(BAM_STATS_SAMTOOLS.out.versions)

    emit:
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), val(ref), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), val(ref), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), val(ref), [ csi ] ]

    stats    = BAM_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), val(ref), [ stats ] ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), val(ref), [ flagstat ] ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), val(ref), [ idxstats ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

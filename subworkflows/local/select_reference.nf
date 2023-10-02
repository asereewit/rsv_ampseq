//
// Create new meta [ [ meta.id, meta.single_end, meta.rsv_type ], fastq ]
// based on mapping stats from aligning reads to RSV-A and RSV-B references
// using bbmap
//

include { BBMAP_ALIGN } from '../../modules/nf-core/bbmap/align'

workflow SELECT_REFERENCE {
    take:
    ch_reads    // channel: [ val(meta), path(reads) ]
    ref         // path: ref

    main:
    BBMAP_ALIGN (
        ch_reads,
        ref
    ).align_covstats_fastq
    .map { meta, covstats, fastq -> add_ref_info(meta, covstats, fastq) }
    .set { ch_new_meta_reads }

    emit:
    reads =  ch_new_meta_reads              // channel: [ val(new_meta), path(reads) ]
    versions =  BBMAP_ALIGN.out.versions    // channel: [ versions.yml ]

}

// Function to get list of [ [ meta.id, meta.single_end, meta.rsv_type ], fastq ]
def add_ref_info(meta, covstats, fastq) {

    def lines = new File(covstats.toString()).readLines()

    def rsv_type = lines[1].split('\t')[0]

    def new_meta_fastq = []
    if (rsv_type == "RSVA") { 
        meta.rsv_type = "RSVA"
    } else if (rsv_type == "RSVB") {
        meta.rsv_type = "RSVB"
    }
    new_meta_fastq = [ meta, fastq ] 

    return new_meta_fastq
}

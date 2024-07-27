//
// Prepare reference genome files
//

include { BOWTIE2_BUILD     } from '../../modules/local/bowtie2_build'

workflow PREPARE_GENOME {
    main:
        
    ch_bowtie2_index_RSVA = Channel.empty()
    ch_bowtie2_index_RSVB = Channel.empty()
    BOWTIE2_BUILD (
        params.ref_RSVA,
        params.ref_RSVB
    )
    ch_bowtie2_index_RSVA = BOWTIE2_BUILD.out.bowtie2_index_RSVA
    ch_bowtie2_index_RSVB = BOWTIE2_BUILD.out.bowtie2_index_RSVB

    emit:
    bowtie2_index_RSVA  = ch_bowtie2_index_RSVA        // path: bowtie2/rsva_index/
    bowtie2_index_RSVB  = ch_bowtie2_index_RSVB        // path: bowtie2/rsvb_index/
}

//
// Prepare reference genome files
//

include { BOWTIE2_BUILD     } from '../../modules/local/bowtie2_build'
include { PREP_REF          } from '../../modules/local/prep_ref'

workflow PREPARE_GENOME {
    main:
        
    ch_RSVA_ref = Channel.empty()
    ch_RSVB_ref = Channel.empty()
    ch_RSVA_RSVB_ref = Channel.empty()
    PREP_REF (
        file(params.ref_RSVA),
        file(params.ref_RSVB)
    )
    ch_RSVA_ref = PREP_REF.out.RSVA_fasta
    ch_RSVB_ref = PREP_REF.out.RSVB_fasta
    ch_RSVA_RSVB_ref = PREP_REF.out.RSVA_RSVB_fasta

    ch_bowtie2_index_RSVA = Channel.empty()
    ch_bowtie2_index_RSVB = Channel.empty()
    BOWTIE2_BUILD (
        ch_RSVA_ref,
        ch_RSVB_ref
    )
    ch_bowtie2_index_RSVA = BOWTIE2_BUILD.out.bowtie2_index_RSVA
    ch_bowtie2_index_RSVB = BOWTIE2_BUILD.out.bowtie2_index_RSVB

    ch_primer_bed_RSVA = Channel.empty()
    ch_primer_bed_RSVB = Channel.empty()
    ch_ref_gff_RSVA = Channel.empty()
    ch_ref_gff_RSVB = Channel.empty()
    if (params.primer_bed_RSVA) {
        ch_primer_bed_RSVA = file(params.primer_bed_RSVA)
    }
    if (params.primer_bed_RSVB) {
        ch_primer_bed_RSVB = file(params.primer_bed_RSVB)
    }
    if (params.ref_gff_RSVA) {
        ch_ref_gff_RSVA = file(params.ref_gff_RSVA)
    }
    if (params.ref_gff_RSVB) {
        ch_ref_gff_RSVB = file(params.ref_gff_RSVB)
    }

    emit:
    RSVA_ref            = ch_RSVA_ref               // path: RSVA_ref.fasta
    RSVB_ref            = ch_RSVB_ref               // path: RSVA_ref.fasta
    RSVA_RSVB_ref       = ch_RSVA_RSVB_ref          // path: RSVA_RSVB_ref.fasta
    bowtie2_index_RSVA  = ch_bowtie2_index_RSVA     // path: bowtie2/rsva_index/
    bowtie2_index_RSVB  = ch_bowtie2_index_RSVB     // path: bowtie2/rsvb_index/
    primer_bed_RSVA     = ch_primer_bed_RSVA        // path: RSVA.primer.bed
    primer_bed_RSVB     = ch_primer_bed_RSVB        // path: RSVB.primer.bed
    ref_gff_RSVA        = ch_ref_gff_RSVA           // path: RSVA.gff
    ref_gff_RSVB        = ch_ref_gff_RSVB           // path: RSVB.gff
}

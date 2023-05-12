process PICK_REF {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
        'quay.io/biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(align_covstats)
    path ref
    path primer_bed_RSVA
    path ref_gff_RSVA
    path primer_bed_RSVB
    path ref_gff_RSVB

    output:
    tuple val(meta), path("*.RSV_ref.fasta"), emit: rsv_ref_fasta
    tuple val(meta), env(bowtie2_index), emit: rsv_ref_bowtie2_index
    tuple val(meta), path("*.RSV_primer.bed"), emit: rsv_primer_bed
    tuple val(meta), path("*.RSV_ref.gff"), emit: rsv_ref_gff
    tuple val(meta), env(rsv_type), emit: rsv_type
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    
    # get the fasta header of the reference (RSVA or RSVB) that has the higher median coverage
    ref_highest_median_cov=`cat ${align_covstats} | awk 'NR>1' | head -1 | cut -f1`

    if [[ \${ref_highest_median_cov} == RSVA ]]
    then
        rsv_type=`echo RSVA`
        cp ${primer_bed_RSVA} ${prefix}.RSV_primer.bed
        cp ${ref_gff_RSVA} ${prefix}.RSV_ref.gff
        bowtie2_index=`echo ${params.bowtie2_index_RSVA}`
    elif [[ \${ref_highest_median_cov} == RSVB ]]
    then
        rsv_type=`echo RSVB`
        cp ${primer_bed_RSVB} ${prefix}.RSV_primer.bed  
        cp ${ref_gff_RSVB} ${prefix}.RSV_ref.gff
        bowtie2_index=`echo ${params.bowtie2_index_RSVB}`
    fi

    # extract the reference
    samtools \\
        faidx \\
        $ref \\
        \${ref_highest_median_cov} \\
        > ${prefix}.RSV_ref.fasta
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pickref: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

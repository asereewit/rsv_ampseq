process IVAR_VARIANTS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ivar=1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/biocontainers/ivar:1.4--h6b7c446_1' }"

    input:
    tuple val(meta), path(bam)
    path ref_rsva
    path ref_rsvb
    path gff_rsva
    path gff_rsvb
    path fai
    val save_mpileup

    output:
    tuple val(meta), path("*.tsv")    , emit: tsv
    tuple val(meta), path("*.mpileup"), emit: mpileup, optional: true
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""

    def ref
    def features 
    if ("${meta.rsv_type}" == "RSVA") {
        ref = "${ref_rsva}"
        features =  "-g ${gff_rsva}"
    } else if ("${meta.rsv_type}" == "RSVB") {
        ref = "${ref_rsvb}"
        features =  "-g ${gff_rsvb}"
    }

    """
    samtools \\
        mpileup \\
        $args2 \\
        --reference $ref \\
        $bam \\
        $mpileup \\
        | ivar \\
            variants \\
            $args \\
            $features \\
            -r $ref \\
            -p $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*iVar version //; s/ .*\$//')
    END_VERSIONS
    """
}

process IVAR_VARIANTS {
    tag "$meta.id"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::ivar=1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/sereewit/ivar:1.4.2_49079e2' }"

    input:
    tuple val(meta), val(ref), path(bam)
    path ref_rsva
    path ref_rsvb
    path gff_rsva
    path gff_rsvb
    val save_mpileup

    output:
    tuple val(meta), val(ref), path("*.tsv")    , emit: tsv
    tuple val(meta), val(ref), path("*.mpileup"), emit: mpileup, optional: true
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""

    def fasta
    def features 
    if ("${ref.type}" == "RSVA") {
        fasta = "${ref_rsva}"
        features =  "-g ${gff_rsva}"
    } else if ("${ref.type}" == "RSVB") {
        fasta = "${ref_rsvb}"
        features =  "-g ${gff_rsvb}"
    }

    """
    samtools \\
        mpileup \\
        $args2 \\
        --reference $fasta \\
        $bam \\
        $mpileup \\
        | ivar \\
            variants \\
            $args \\
            $features \\
            -r $fasta \\
            -p $prefix

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*iVar version //; s/ .*\$//')
    END_VERSIONS
    """
}

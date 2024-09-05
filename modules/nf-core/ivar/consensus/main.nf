process IVAR_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::ivar=1.4" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ivar:1.4--h6b7c446_1' :
        'quay.io/sereewit/ivar:1.4.2_49079e2' }"

    input:
    tuple val(meta), val(ref), path(bam)
    path ref_rsva
    path ref_rsvb
    val save_mpileup

    output:
    tuple val(meta), val(ref), path("*.fa")      , emit: fasta
    tuple val(meta), val(ref), path("*.qual.txt"), emit: qual
    tuple val(meta), val(ref), path("*.mpileup") , optional:true, emit: mpileup
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""
    
    def fasta
    if ("${ref.type}" == "RSVA") {
        fasta = "${ref_rsva}"
    } else if ("${ref.type}" == "RSVB") {
        fasta = "${ref_rsvb}"
    }

    """
    samtools \\
        mpileup \\
        --reference $fasta \\
        $args2 \\
        $bam \\
        $mpileup \\
        | ivar \\
            consensus \\
            $args \\
            -p $prefix \\
            -i $prefix

    # remove leading and trailing Ns
    sed -i '/^>/! s/^N*//; /^>/! s/N*\$//' ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ivar: \$(echo \$(ivar version 2>&1) | sed 's/^.*iVar version //; s/ .*\$//')
    END_VERSIONS
    """
}

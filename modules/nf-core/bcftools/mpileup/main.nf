process BCFTOOLS_MPILEUP {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::bcftools=1.17" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.17--haef29d1_0':
        'public.ecr.aws/biocontainers/bcftools:1.17--haef29d1_0' }"

    input:
    tuple val(meta), val(ref), path(bam)
    path ref_rsva
    path ref_rsvb
    val save_mpileup

    output:
    tuple val(meta), val(ref), path("*.vcf"),         emit: vcf
    tuple val(meta), val(ref), path("*stats.txt"),    emit: stats
    tuple val(meta), val(ref), path("*.mpileup.gz"),  emit: mpileup, optional: true
    path  "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""
    def bgzip_mpileup = save_mpileup ? "bgzip ${prefix}.mpileup" : ""

    def fasta
    if ("${ref.type}" == "RSVA") {
        fasta = "${ref_rsva}"
    } else if ("${ref.type}" == "RSVB") {
        fasta = "${ref_rsvb}"
    }

    """
    echo "${meta.id}" > sample_name.list

    bcftools \\
        mpileup \\
        --fasta-ref $fasta \\
        $args \\
        $bam \\
        $mpileup \\
        | bcftools call --output-type v $args2 - > ${prefix}.vcf

    $bgzip_mpileup

    bcftools stats ${prefix}.vcf > ${prefix}.bcftools_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}

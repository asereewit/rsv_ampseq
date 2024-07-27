process BOWTIE2_BUILD {
    label 'process_low'

    conda (params.enable_conda ? 'bioconda::bowtie2=2.4.4' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bowtie2:2.4.4--py39hbb4e92a_0' :
        'quay.io/biocontainers/bowtie2:2.4.4--py39hbb4e92a_0' }"

    input:
    path fasta_RSVA
    path fasta_RSVB

    output:
    path 'bowtie2_index_RSVA'   , emit: bowtie2_index_RSVA
    path 'bowtie2_index_RSVB'   , emit: bowtie2_index_RSVB
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir bowtie2_index_RSVA
    bowtie2-build $args --threads $task.cpus ${fasta_RSVA} bowtie2_index_RSVA/${fasta_RSVA.baseName}

    mkdir bowtie2_index_RSVB
    bowtie2-build $args --threads $task.cpus ${fasta_RSVB} bowtie2_index_RSVB/${fasta_RSVB.baseName}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bowtie2: \$(echo \$(bowtie2 --version 2>&1) | sed 's/^.*bowtie2-align-s version //; s/ .*\$//')
    END_VERSIONS
    """
}

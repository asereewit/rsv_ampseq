process BBMAP_ALIGN {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::bbmap=39.01 bioconda::samtools=1.16.1 pigz=2.6" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0' :
        'quay.io/biocontainers/mulled-v2-008daec56b7aaf3f162d7866758142b9f889d690:e8a286b2e789c091bac0a57302cdc78aa0112353-0' }"

    input:
    tuple val(meta), path(fastq)
    path ref

    output:
    tuple val(meta), path("*.bam"), emit: bam
    tuple val(meta), path("*.sorted.tsv"), path(fastq), emit: align_covstats_fastq
    tuple val(meta), path("*.log"), emit: log
    path "versions.yml",            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    input = meta.single_end ? "in=${fastq}" : "in=${fastq[0]} in2=${fastq[1]}"

    // Set the db variable to reflect the three possible types of reference input: 1) directory
    // named 'ref', 2) directory named something else (containg a 'ref' subdir) or 3) a sequence
    // file in fasta format
    if ( ref.isDirectory() ) {
        if ( ref ==~ /(.\/)?ref\/?/ ) {
            db = ''
        } else {
            db = "path=${ref}"
        }
    } else {
        db = "ref=${ref}"
    }

    """
    bbmap.sh \\
        $db \\
        $input \\
        out=${prefix}.bam \\
        $args \\
        covstats=${prefix}.bbmap_align.covstats.tsv \\
        threads=$task.cpus \\
        -Xmx${task.memory.toGiga()}g \\
        &> ${prefix}.bbmap.log

    # sort bbmap_align.covstats.tsv based on Plus_reads (column 7) in descending order
	head -1 ${prefix}.bbmap_align.covstats.tsv > ${prefix}.bbmap_align.covstats.temp.tsv
	awk 'NR>1' < ${prefix}.bbmap_align.covstats.tsv | sort -t \$'\t' -nrk7 >> ${prefix}.bbmap_align.covstats.temp.tsv
	mv ${prefix}.bbmap_align.covstats.temp.tsv ${prefix}.bbmap_align.covstats.sorted.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bbmap: \$(bbversion.sh | grep -v "Duplicate cpuset")
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}

process CLEANUP {
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/YOUR-TOOL-HERE':
        'ubuntu:20.04' }"

    input:
    path summary_tsv_files

    output:
    path "summary.tsv", emit: summary
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    echo "sample_name\trsv_subtype\traw_reads\ttrimmed_reads\tpct_reads_trimmed\tmapped_reads\tpct_reads_mapped\tpct_genome_covered\tmean_genome_coverage\tpct_fusion_covered\tmean_fusion_coverage\tpct_fusion_50x\tpct_fusion_100x\tconsensus_length\tnum_ns\tnum_ambiguous" > summary.tsv
    awk '(NR == 2) || (FNR > 1)' *.summary.tsv >> summary.tsv 
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        cleanup: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

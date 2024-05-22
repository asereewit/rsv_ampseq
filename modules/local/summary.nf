process SUMMARY {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/':
        'greningerlab/revica:ubuntu-20.04' }"

    input:
    tuple val(meta), val(ref), path(ivar_trim_bam), path(ivar_trim_bam_bai), path(ivar_consensus), path(fastp_trim_log)

    output:
    path("*.tsv"),          emit: summary_tsv
    path "versions.yml",    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    def fusion_chr_start_end = ""
    if ("${ref.type}" == "RSVA") {
        fusion_chr_start_end = "RSVA:${params.RSVA_F_coord}"
    } else if ("${ref.type}" == "RSVB") {
        fusion_chr_start_end = "RSVB:${params.RSVB_F_coord}"
    }
    def fusion_length = "${params.RSV_F_length}"

    """
    # raw reads and trimmed reads
    raw_reads=`grep -A1 "before filtering:" ${fastp_trim_log} | grep 'total reads:' | cut -d: -f2 | tr -d " " | awk 'NF{sum+=\$1} END {print sum}'`
    trimmed_reads=`grep -A1 "after filtering:" ${fastp_trim_log} | grep 'total reads:' | cut -d: -f2 | tr -d " " | awk 'NF{sum+=\$1} END {print sum}'`
    pct_reads_trimmed=`echo "\${trimmed_reads}/\${raw_reads}*100" | bc -l`

    # mapped reads
    mapped_reads=`samtools view -F 4 -c ${ivar_trim_bam}`
    pct_reads_mapped=`echo "\${mapped_reads}/\${raw_reads}*100" | bc -l`

    # whole genome coverage
    pct_genome_covered=`samtools coverage ${ivar_trim_bam} | awk 'NR>1' | cut -f6`
    mean_genome_coverage=`samtools coverage ${ivar_trim_bam} | awk 'NR>1' | cut -f7`

    # fusion gene coverage 
    pct_fusion_covered=`samtools coverage -r ${fusion_chr_start_end} ${ivar_trim_bam} | awk 'NR>1' | cut -f6`
    mean_fusion_coverage=`samtools coverage -r ${fusion_chr_start_end} ${ivar_trim_bam} | awk 'NR>1' | cut -f7`
    num_bases_fusion_50x=`samtools depth -r ${fusion_chr_start_end} ${ivar_trim_bam} | awk '{if(\$3>50)print\$3}' | wc -l`
    pct_fusion_50x=`echo "\${num_bases_fusion_50x}/${fusion_length}*100" | bc -l`
    num_bases_fusion_100x=`samtools depth -r ${fusion_chr_start_end} ${ivar_trim_bam} | awk '{if(\$3>100)print\$3}' | wc -l`
    pct_fusion_100x=`echo "\${num_bases_fusion_100x}/${fusion_length}*100" | bc -l`

    # consensus genome
    consensus_length=`awk '/^>/{if (l!="") print l; print; l=0; next}{l+=length(\$0)}END{print l}' ${ivar_consensus} | awk 'FNR==2{print val,\$1}'`
    num_ns_consensus=`grep -v "^>" ${ivar_consensus} | tr -c -d N | wc -c`
    num_as_consensus=`grep -v "^>" ${ivar_consensus} | tr -c -d A | wc -c`
    num_cs_consensus=`grep -v "^>" ${ivar_consensus} | tr -c -d C | wc -c`
    num_gs_consensus=`grep -v "^>" ${ivar_consensus} | tr -c -d G | wc -c`
    num_ts_consensus=`grep -v "^>" ${ivar_consensus} | tr -c -d T | wc -c`
    num_non_ns_ambiguous=`echo "\${consensus_length}-\${num_as_consensus}-\${num_cs_consensus}-\${num_gs_consensus}-\${num_ts_consensus}-\${num_ns_consensus}" | bc -l`

    echo "sample_name\trsv_subtype\traw_reads\ttrimmed_reads\tpct_reads_trimmed\tmapped_reads\tpct_reads_mapped\tpct_genome_covered\tmean_genome_coverage\tpct_fusion_covered\tmean_fusion_coverage\tpct_fusion_50x\tpct_fusion_100x\tconsensus_length\tnum_ns\tnum_ambiguous" > ${prefix}.summary.tsv
    echo "${prefix}\t${ref.type}\t\${raw_reads}\t\${trimmed_reads}\t\${pct_reads_trimmed}\t\${mapped_reads}\t\${pct_reads_mapped}\t\${pct_genome_covered}\t\${mean_genome_coverage}\t\${pct_fusion_covered}\t\${mean_fusion_coverage}\t\${pct_fusion_50x}\t\${pct_fusion_100x}\t\${consensus_length}\t\${num_ns_consensus}\t\${num_non_ns_ambiguous}" >> ${prefix}.summary.tsv
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        summary: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}

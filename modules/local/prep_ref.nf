process PREP_REF {
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'quay.io/nf-core/ubuntu:20.04' }"

    input:
    path ref_RSVA
    path ref_RSVB

    output:
    path 'RSVA.fasta'           , emit: RSVA_fasta
    path 'RSVB.fasta'           , emit: RSVB_fasta
    path 'RSVA_RSVB.fasta'      , emit: RSVA_RSVB_fasta
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    if [ "${ref_RSVA}" != "RSVA.fasta" ]; then
        mv ${ref_RSVA} RSVA.fasta
    fi
    sed -i '1s/^>.*/>RSVA/' RSVA.fasta

    if [ "${ref_RSVB}" != "RSVB.fasta" ]; then
        mv ${ref_RSVB} RSVB.fasta
    fi
    sed -i '1s/^>.*/>RSVB/' RSVB.fasta
    
    cat RSVA.fasta RSVB.fasta > RSVA_RSVB.fasta
 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pigz: \$( pigz --version 2>&1 | sed 's/pigz //g' )
    END_VERSIONS
    """
}

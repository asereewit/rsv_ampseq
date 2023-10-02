process EDIT_IVAR_VARIANTS {
    tag "$meta.id"
    label 'process_single'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0':
        'quay.io/biocontainers/mulled-v2-77320db00eefbbf8c599692102c3d387a37ef02a:08144a66f00dc7684fad061f1466033c0176e7ad-0' }"

    input:
    tuple val(meta), path(variants_tsv)
    path gff_rsva
    path gff_rsvb

    output:
    tuple val(meta), path("*.reformatted.tsv"), emit: variants_edited_tsv
    path "versions.yml",                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    def gff
    if ("${meta.rsv_type}" == "RSVA") {
        gff = "${gff_rsva}"
    } else if ("${meta.rsv_type}" == "RSVB") {
        gff = "${gff_rsvb}"
    }

    """
    edit_ivar_variants.py \\
        ${variants_tsv} \\
        ${gff} \\
        ${prefix}.reformatted

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        editivarvariants: python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}

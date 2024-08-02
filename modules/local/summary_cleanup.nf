process SUMMARY_CLEANUP {
    label 'process_low'
    container 'quay.io/nf-core/ubuntu:20.04'

    input:
    path(fail_summary)
    path(pass_summary)

    output:
    path("run_summary.tsv"), emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:

    """
    cat ${fail_summary} | awk 'NR>1' >> temp.tsv
    cat ${pass_summary} | awk 'NR>1' >> temp.tsv
    head -1 ${pass_summary} >> run_summary.tsv
    sort -t\$'\t' -k1,1 temp.tsv >> run_summary.tsv 
    """
}

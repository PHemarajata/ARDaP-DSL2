process HTML_REPORT {
    label 'report'
    publishDir "./Outputs/Reports", mode: 'copy', overwrite: true
    
    input:
    path reports
    path metadata
    
    output:
    path "*.html", emit: html_reports
    path "*.png", emit: plots, optional: true
    
    script:
    """
    bash ${baseDir}/bin/Report_html.sh \\
        ${baseDir} \\
        ${params.species} \\
        ${metadata}
    """
    
    stub:
    """
    touch ardap_report.html
    touch coverage_plot.png
    """
}
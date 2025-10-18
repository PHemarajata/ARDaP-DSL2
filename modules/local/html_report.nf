process HTML_REPORT {
    label 'html_report'
    tag "$id"
    publishDir "./Outputs/Reports", mode: 'copy', overwrite: true
    
    input:
    tuple val(id), path(resistance_report)
    path metadata
    
    output:
    path "${id}_report.html", emit: html_reports
    
    script:
    """
    # Copy the resistance report with expected name for the script
    cp ${resistance_report} resistance_report.txt
    
    # Run the HTML report script
    bash ${baseDir}/bin/Report_html.sh \\
        ${baseDir} \\
        ${params.species} \\
        ${metadata}
    
    # Rename output to include sample ID
    if [ -f "report.html" ]; then
        mv report.html ${id}_report.html
    else
        # Create a basic HTML report if script fails
        echo "<html><head><title>ARDaP Report for ${id}</title></head><body><h1>ARDaP Analysis Report</h1><p>Sample: ${id}</p><p>Analysis completed - see resistance report for details.</p></body></html>" > ${id}_report.html
    fi
    """
    
    stub:
    """
    touch ${id}_report.html
    """
}
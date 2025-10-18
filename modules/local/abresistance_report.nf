process ABRESISTANCE_REPORT {
    label 'report'
    publishDir "./Outputs/Reports", mode: 'copy', overwrite: true
    
    input:
    path sql_results
    path resfinder_results
    path metadata
    
    output:
    path "*.txt", emit: reports
    path "*.csv", emit: csv_reports, optional: true
    
    script:
    if (params.mixtures) {
        """
        bash ${baseDir}/bin/AbR_reports_mix.sh \\
            ${baseDir} \\
            ${params.species} \\
            ${metadata}
        """
    } else {
        """
        bash ${baseDir}/bin/AbR_reports.sh \\
            ${baseDir} \\
            ${params.species} \\
            ${metadata}
        """
    }
    
    stub:
    """
    touch antibiotic_resistance_report.txt
    touch resistance_summary.csv
    """
}
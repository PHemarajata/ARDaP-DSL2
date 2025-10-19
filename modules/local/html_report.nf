process HTML_REPORT {
    label 'html_report'
    tag "$id"
    publishDir "${params.outdir}/AbR_reports", mode: 'copy', overwrite: true
    
    input:
    tuple val(id), path(resistance_report)
    path metadata
    path drug_data
    path report_script
    
    output:
    path "${id}_report.html", emit: html_reports
    
    script: """
    #!/usr/bin/env bash
    set -euo pipefail

    # Copy files with expected names for the script (only if different)
    if [ "${resistance_report}" != "${id}.AbR_output.final.txt" ]; then
        cp "${resistance_report}" "${id}.AbR_output.final.txt"
    fi

    if [ "${metadata}" != "patientMetaData.csv" ]; then
        cp "${metadata}" patientMetaData.csv
    fi

    if [ "${drug_data}" != "patientDrugSusceptibilityData.csv" ]; then
        cp "${drug_data}" patientDrugSusceptibilityData.csv
    fi

    # Run the HTML report script (provided as an input to avoid referencing baseDir)
    bash "${report_script}" "${params.species}"

    # Rename output to include sample ID
    if [ -f "report.html" ]; then
        mv report.html "${id}_report.html"
    else
        # Create a basic HTML report if script fails
        cat > "${id}_report.html" <<'EOF'
<html>
  <head><title>ARDaP Report for ${id}</title></head>
  <body>
    <h1>ARDaP Analysis Report</h1>
    <p>Sample: ${id}</p>
    <p>Analysis completed - see resistance report for details.</p>
  </body>
</html>
EOF
    fi
    """
}
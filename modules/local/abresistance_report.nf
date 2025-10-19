process ABRESISTANCE_REPORT {
    label 'report'
    tag "$id"
    publishDir "${params.outdir}/AbR_reports", mode: 'copy', overwrite: true
    
    input:
    tuple val(id), path(snp_indel_results), path(resfinder_results), path(del_dup_results)
    path metadata
    
    output:
    tuple val(id), path("${id}.AbR_output.final.txt"), emit: reports
    path "patientDrugSusceptibilityData.csv", emit: drug_data
    
    script:
    """
    # Set up database path based on species
    DB_PATH="${baseDir}/Databases/${params.species}/${params.species}.db"
    
    # Create files with exact names the script expects (only if different)
    if [ "${snp_indel_results}" != "${id}.AbR_output_snp_indel.txt" ]; then
        cp ${snp_indel_results} ${id}.AbR_output_snp_indel.txt
    fi
    
    if [ "${del_dup_results}" != "${id}.AbR_output_del_dup.txt" ]; then
        cp ${del_dup_results} ${id}.AbR_output_del_dup.txt
    fi
    
    # Handle resfinder results (only if different)
    if [ "${resfinder_results}" != "${id}_resfinder.txt" ]; then
        ln -sf ${resfinder_results} ${id}_resfinder.txt
    fi
    
    # Copy metadata to expected location (only if different)
    if [ "${metadata}" != "patientMetaData.csv" ]; then
        cp ${metadata} patientMetaData.csv
    fi
    
    # Run the report generation script
    bash ${baseDir}/bin/AbR_reports.sh \\
        ${id} \\
        \$DB_PATH
    
    # Ensure final output file exists
    if [ ! -f "${id}.AbR_output.final.txt" ]; then
        echo "No antibiotic resistance identified in ${id}" > "${id}.AbR_output.final.txt"
    fi
    """
    
    stub:
    """
    touch ${id}.AbR_output.final.txt
    touch patientDrugSusceptibilityData.csv
    """
}
process ABRESISTANCE_REPORT {
    label 'report'
    tag "$id"
    publishDir "./Outputs/Reports", mode: 'copy', overwrite: true
    
    input:
    tuple val(id), path(snp_indel_results), path(resfinder_results)
    path metadata
    
    output:
    tuple val(id), path("${id}.AbR_output.final.txt"), emit: reports  // Changed to match script output
    
    script:
    """
    # Create files with exact names the script expects
    cp ${snp_indel_results} ${id}.AbR_output_snp_indel.txt
    
    # Create symbolic link for resfinder if different, otherwise it's already correct
    if [ "${resfinder_results}" != "${id}_resfinder.txt" ]; then
        ln -sf ${resfinder_results} ${id}_resfinder.txt
    fi
    
    # Create empty del_dup file
    echo "" > ${id}.AbR_output_del_dup.txt
    
    bash ${baseDir}/bin/AbR_reports.sh \\
        ${id} \\
        ${baseDir}/Databases/${params.database}/${params.database}.db
    """
    
    stub:
    """
    touch ${id}.AbR_output.final.txt
    """
}
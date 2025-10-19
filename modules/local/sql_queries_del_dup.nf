process SQL_QUERIES_DEL_DUP {
    label 'genomic_queries'
    tag "$id"
    publishDir "${params.outdir}/Intermediate", mode: 'copy', pattern: "${id}.AbR_output_del_dup.txt"
    
    input:
    tuple val(id), path(vcf)
    path resistance_db
    
    output:
    tuple val(id), path("${id}.AbR_output_del_dup.txt"), emit: results
    
    script:
    """
    # Create empty structural variant files first
    touch ${id}.deletion_summary.txt
    touch ${id}.duplication_summary.txt
    
    if [ "${params.mixtures}" = "true" ]; then
        bash ${baseDir}/bin/SQL_queries_DelDupMix.sh \\
            ${vcf} \\
            ${resistance_db} \\
            ${id}
    else
        bash ${baseDir}/bin/SQL_queries_DelDup.sh \\
            ${id} \\
            ${resistance_db}
    fi
    
    # Ensure output file exists with proper naming
    if [ ! -f "${id}.AbR_output_del_dup.txt" ]; then
        echo "" > "${id}.AbR_output_del_dup.txt"
    fi
    """
    
    stub:
    """
    touch ${id}.AbR_output_del_dup.txt
    """
}
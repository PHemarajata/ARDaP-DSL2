process SQL_QUERIES_DEL_DUP {
    label 'genomic_queries'
    tag "$id"
    
    input:
    tuple val(id), path(vcf)
    path resistance_db
    
    output:
    tuple val(id), path("${id}_del_dup_results.txt"), emit: results
    
    script:
    if (params.mixtures) {
        """
        bash ${baseDir}/bin/SQL_queries_DelDupMix.sh \\
            ${vcf} \\
            ${resistance_db} \\
            ${id}
        """
    } else {
        """
        bash ${baseDir}/bin/SQL_queries_DelDup.sh \\
            ${vcf} \\
            ${resistance_db} \\
            ${id}
        """
    }
    
    stub:
    """
    touch ${id}_del_dup_results.txt
    """
}
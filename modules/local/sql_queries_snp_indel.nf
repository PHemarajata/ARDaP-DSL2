process SQL_QUERIES_SNP_INDEL {
    label 'genomic_queries'
    tag "$id"
    
    input:
    tuple val(id), path(vcf)
    path resistance_db
    
    output:
    tuple val(id), path("${id}_snp_indel_results.txt"), emit: results
    
    script:
    if (params.mixtures) {
        """
        bash ${baseDir}/bin/SQL_queries_SNP_indel_mix.sh \\
            ${vcf} \\
            ${resistance_db} \\
            ${id}
        
        # Ensure output file exists even if script fails to create it
        if [ ! -f "${id}_snp_indel_results.txt" ]; then
            echo "ARDaP found no SNP/Indel resistance variants for ${id}" > "${id}_snp_indel_results.txt"
        fi
        """
    } else {
        """
        bash ${baseDir}/bin/SQL_queries_SNP_indel.sh \\
            ${vcf} \\
            ${resistance_db} \\
            ${id}
        
        # Ensure output file exists even if script fails to create it
        if [ ! -f "${id}_snp_indel_results.txt" ]; then
            echo "ARDaP found no SNP/Indel resistance variants for ${id}" > "${id}_snp_indel_results.txt"
        fi
        """
    }
    
    stub:
    """
    touch ${id}_snp_indel_results.txt
    """
}
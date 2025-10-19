process SQL_QUERIES_SNP_INDEL {
    label 'genomic_queries'
    tag "$id"
    publishDir "${params.outdir}/Intermediate", mode: 'copy', pattern: "${id}.AbR_output_snp_indel.txt"
    
    input:
    tuple val(id), path(vcf)
    path resistance_db
    
    output:
    tuple val(id), path("${id}.AbR_output_snp_indel.txt"), emit: results
    
    script:
    """
    # First extract the necessary intermediate files from the VCF
    echo 'Extracting SNP and indel effects from VCF...'
    
    # Create annotated effects files that the SQL script expects
    awk '/^#|ANN=/ {print}' ${vcf} > annotated.vcf
    
    # Extract SNP effects (TYPE=SNP in INFO field)
    grep -E '^#|TYPE=SNP' annotated.vcf > snps.vcf || touch snps.vcf
    if [[ -s snps.vcf ]]; then
        awk '{if (match(\$0,"ANN=")) print substr(\$0,RSTART)}' snps.vcf > snp.effects.tmp
        awk -F "|" '{ print \$4,\$10,\$11,\$15 }' snp.effects.tmp | sed 's/c\\.//' | sed 's/p\\.//' | sed 's/n\\.//' > ${id}.annotated.snp.effects
    else
        touch ${id}.annotated.snp.effects
    fi
    
    # Extract indel effects (TYPE=INS or TYPE=DEL)
    grep -E '^#|TYPE=(INS|DEL)' annotated.vcf > indels.vcf || touch indels.vcf
    if [[ -s indels.vcf ]]; then
        awk '{if (match(\$0,"ANN=")) print substr(\$0,RSTART)}' indels.vcf > indel.effects.tmp
        awk -F "|" '{ print \$4,\$10,\$11,\$15 }' indel.effects.tmp | sed 's/c\\.//' | sed 's/p\\.//' | sed 's/n\\.//' > ${id}.annotated.indel.effects
    else
        touch ${id}.annotated.indel.effects
    fi
    
    # Create high-impact variants file for Function_lost_list
    grep '|HIGH|' ${vcf} > high.impact.vcf || touch high.impact.vcf
    if [[ -s high.impact.vcf ]]; then
        awk '{if (match(\$0,"ANN=")) print substr(\$0,RSTART)}' high.impact.vcf > high.impact.effects.tmp
        awk -F "|" '{ print \$4,\$11,\$15 }' high.impact.effects.tmp | sed 's/c\\.//' | sed 's/p\\.//' | sed 's/n\\.//' > ${id}.Function_lost_list.txt
    else
        touch ${id}.Function_lost_list.txt
    fi
    
    # Run the SQL queries script
    bash ${baseDir}/bin/SQL_queries_SNP_indel.sh \\
        ${id} \\
        ${resistance_db}
    
    # Ensure output file exists with proper naming
    if [ ! -f "${id}.AbR_output_snp_indel.txt" ]; then
        echo "ARDaP found no SNP/Indel resistance variants for ${id}" > "${id}.AbR_output_snp_indel.txt"
    fi
    """
    
    stub:
    """
    touch ${id}.AbR_output_snp_indel.txt
    """
}
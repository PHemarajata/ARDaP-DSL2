process SNP_MATRIX {
    label 'snp_matrix' 
    publishDir "./Outputs/Phylogeny", mode: 'copy', overwrite: true
    
    input:
    path vcf
    
    output:
    path "*.matrix", emit: matrix, optional: true
    path "*.fasttree", emit: tree, optional: true
    path "*.vcf.table*", emit: tables, optional: true
    
    script:
    """
    # Create links with the expected names for the script
    ln -sf ${vcf} out.vcf
    cp ${vcf} out.filtered.vcf
    
    # Try to run the SNP matrix script
    bash ${baseDir}/bin/SNP_matrix.sh \\
        out.vcf \\
        true \\
        false
    
    # Check if any output was generated
    if [ ! -f "*.matrix" ] && [ ! -f "*.fasttree" ]; then
        echo "SNP matrix analysis completed but no matrix files generated" > analysis_complete.txt
    fi
    """
    
    stub:
    """
    touch snp.matrix
    touch phylogeny.fasttree
    """
}
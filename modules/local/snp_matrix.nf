process SNP_MATRIX {
    label 'snp_matrix'
    publishDir "./Outputs/Phylogeny_and_annotation", mode: 'copy', overwrite: true
    
    input:
    path vcf
    
    output:
    path "snp_matrix.txt", emit: matrix
    path "snp_positions.txt", emit: positions, optional: true
    
    script:
    """
    bash ${baseDir}/bin/SNP_matrix.sh \\
        ${vcf} \\
        ${params.indel_merge} \\
        ${params.tri_tetra_allelic}
    """
    
    stub:
    """
    touch snp_matrix.txt
    touch snp_positions.txt
    """
}
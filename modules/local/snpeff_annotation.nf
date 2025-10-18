process SNPEFF_ANNOTATION {
    label 'snpeff'
    
    input:
    path vcf
    
    output:
    path "annotated_variants.vcf", emit: vcf
    path "snpEff_summary.html", emit: summary
    
    script:
    """
    snpEff -Xmx${task.memory.toGiga()}g \\
        -v ${params.snpeff} \\
        ${vcf} \\
        > annotated_variants.vcf
    """
    
    stub:
    """
    touch annotated_variants.vcf
    touch snpEff_summary.html
    """
}
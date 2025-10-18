process DELLY {
    label 'ardap_default'
    tag "$id"
    
    input:
    tuple val(id), path(bam), path(bai)
    path reference
    path fai
    
    output:
    tuple val(id), path("${id}_delly.vcf"), emit: vcf
    
    script:
    """
    delly call \\
        -g ${reference} \\
        -o ${id}_delly.bcf \\
        ${bam}
    
    bcftools view ${id}_delly.bcf > ${id}_delly.vcf
    """
    
    stub:
    """
    touch ${id}_delly.vcf
    """
}
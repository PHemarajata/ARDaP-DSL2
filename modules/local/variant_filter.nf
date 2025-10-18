process VARIANT_FILTER {
    label 'gatk'
    
    input:
    path vcf
    path reference
    path fai
    path dict
    
    output:
    path "filtered_variants.vcf.gz", emit: vcf
    path "filtered_variants.vcf.gz.tbi", emit: tbi
    
    script:
    """
    # Extract SNPs
    gatk --java-options "-Xmx${task.memory.toGiga()}g" SelectVariants \\
        -R ${reference} \\
        -V ${vcf} \\
        -select-type SNP \\
        -O raw_snps.vcf.gz
    
    # Filter SNPs
    gatk --java-options "-Xmx${task.memory.toGiga()}g" VariantFiltration \\
        -R ${reference} \\
        -V raw_snps.vcf.gz \\
        -filter "QD < 2.0" --filter-name "QD2" \\
        -filter "QUAL < 30.0" --filter-name "QUAL30" \\
        -filter "SOR > 3.0" --filter-name "SOR3" \\
        -filter "FS > 60.0" --filter-name "FS60" \\
        -filter "MQ < 40.0" --filter-name "MQ40" \\
        -filter "MQRankSum < -12.5" --filter-name "MQRankSum-12.5" \\
        -filter "ReadPosRankSum < -8.0" --filter-name "ReadPosRankSum-8" \\
        -O filtered_snps.vcf.gz
    
    # Extract INDELs
    gatk --java-options "-Xmx${task.memory.toGiga()}g" SelectVariants \\
        -R ${reference} \\
        -V ${vcf} \\
        -select-type INDEL \\
        -O raw_indels.vcf.gz
    
    # Filter INDELs
    gatk --java-options "-Xmx${task.memory.toGiga()}g" VariantFiltration \\
        -R ${reference} \\
        -V raw_indels.vcf.gz \\
        -filter "QD < 2.0" --filter-name "QD2" \\
        -filter "QUAL < 30.0" --filter-name "QUAL30" \\
        -filter "FS > 200.0" --filter-name "FS200" \\
        -filter "ReadPosRankSum < -20.0" --filter-name "ReadPosRankSum-20" \\
        -O filtered_indels.vcf.gz
    
    # Merge filtered variants
    gatk --java-options "-Xmx${task.memory.toGiga()}g" MergeVcfs \\
        -I filtered_snps.vcf.gz \\
        -I filtered_indels.vcf.gz \\
        -O filtered_variants.vcf.gz
    """
    
    stub:
    """
    touch filtered_variants.vcf.gz
    touch filtered_variants.vcf.gz.tbi
    """
}
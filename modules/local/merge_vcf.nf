process MERGE_VCF {
    label 'master_vcf'
    publishDir "./Outputs/Variants", mode: 'copy', overwrite: true
    
    input:
    path vcfs
    
    output:
    path "merged_variants.vcf", emit: vcf
    
    script:
    """
    bash ${baseDir}/bin/Master_vcf.sh
    mv master.vcf merged_variants.vcf
    """
    
    stub:
    """
    touch merged_variants.vcf
    """
}
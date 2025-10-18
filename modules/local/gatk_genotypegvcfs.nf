process GATK_GENOTYPE_GVCFS {
    label 'gatk'
    
    input:
    path gvcfs
    path reference
    path fai
    path dict
    
    output:
    path "joint_genotyped.vcf.gz", emit: vcf
    path "joint_genotyped.vcf.gz.tbi", emit: tbi
    
    script:
    def gvcf_list = gvcfs.collect { "-V ${it}" }.join(' ')
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" GenotypeGVCFs \\
        -R ${reference} \\
        ${gvcf_list} \\
        -O joint_genotyped.vcf.gz \\
        --verbosity ERROR
    """
    
    stub:
    """
    touch joint_genotyped.vcf.gz
    touch joint_genotyped.vcf.gz.tbi
    """
}
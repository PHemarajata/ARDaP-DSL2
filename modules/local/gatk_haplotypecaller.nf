process GATK_HAPLOTYPE_CALLER {
    label 'gatk_haplo'
    tag "$id"
    
    input:
    tuple val(id), path(bam), path(bai)
    path reference
    path fai
    path dict
    
    output:
    tuple val(id), path("${id}.g.vcf.gz"), path("${id}.g.vcf.gz.tbi"), emit: gvcf
    
    script:
    """
    gatk --java-options "-Xmx${task.memory.toGiga()}g" HaplotypeCaller \\
        -R ${reference} \\
        -I ${bam} \\
        -O ${id}.g.vcf.gz \\
        -ERC GVCF \\
        --native-pair-hmm-threads ${task.cpus} \\
        --verbosity ERROR
    """
    
    stub:
    """
    touch ${id}.g.vcf.gz
    touch ${id}.g.vcf.gz.tbi
    """
}
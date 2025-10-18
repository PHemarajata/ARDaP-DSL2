process GATK_GENOTYPE_GVCFS {
    label 'gatk'
    tag "$id"
    
    input:
    tuple val(id), path(gvcf), path(tbi)
    path reference
    path fai
    path dict
    
    output:
    tuple val(id), path("${id}.vcf.gz"), path("${id}.vcf.gz.tbi"), emit: vcf
    
    script:
    """
    # Ensure reference indices exist
    if [ ! -f "${reference}.fai" ]; then
        echo "Creating FASTA index for reference"
        samtools faidx ${reference}
    fi
    
    if [ ! -f "${dict}" ]; then
        echo "Creating sequence dictionary for reference"
        gatk CreateSequenceDictionary -R ${reference} -O ${reference.baseName}.dict
    fi
    
    # Genotype individual GVCF (not joint)
    gatk --java-options "-Xmx${task.memory.toGiga()}g" GenotypeGVCFs \\
        -R ${reference} \\
        -V ${gvcf} \\
        -O ${id}.vcf.gz \\
        --verbosity ERROR
    """
    
    stub:
    """
    touch ${id}.vcf.gz
    touch ${id}.vcf.gz.tbi
    """
}
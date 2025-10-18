process PINDEL {
    label 'pindel'
    tag "$id"
    
    input:
    tuple val(id), path(bam), path(bai)
    path reference
    
    output:
    tuple val(id), path("${id}_pindel.vcf"), emit: vcf
    
    script:
    """
    # Index reference genome if .fai file is missing
    if [ ! -f "${reference}.fai" ]; then
        echo "Creating FASTA index for ${reference}"
        samtools faidx ${reference}
    fi
    
    # Verify index was created
    if [ ! -f "${reference}.fai" ]; then
        echo "ERROR: Failed to create FASTA index"
        exit 1
    fi
    
    # Create pindel config file
    echo "${bam} ${params.insert_size ?: 500} ${id}" > pindel_config.txt
    
    # Run pindel
    pindel -f ${reference} \\
        -i pindel_config.txt \\
        -o ${id}_pindel \\
        -T ${task.cpus}
    
    # Convert to VCF
    pindel2vcf -p ${id}_pindel_D \\
        -r ${reference} \\
        -R ${params.reference_name ?: "ref"} \\
        -d ${params.reference_date ?: "2023-01-01"} \\
        -v ${id}_pindel.vcf
    """
    
    stub:
    """
    touch ${id}_pindel.vcf
    """
}
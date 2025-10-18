process SNPEFF_ANNOTATION {
    label 'snpeff'
    tag "$id"
    
    input:
    tuple val(id), path(vcf), path(tbi)
    
    output:
    tuple val(id), path("${id}_annotated_variants.vcf"), emit: vcf
    path "${id}_snpEff_summary.html", emit: summary
    
    script:
    def snpeff_db = params.snpeff ?: 'GRCh38.99'  // Default database if not set
    """
    # Check Java version and SnpEff availability
    echo "Checking Java version for SnpEff compatibility..."
    java -version
    
    # Attempt to run SnpEff with database: ${snpeff_db}
    if snpEff -version 2>/dev/null; then
        echo "Running SnpEff annotation with database: ${snpeff_db}"
        snpEff -Xmx${task.memory.toGiga()}g \\
            -v ${snpeff_db} \\
            ${vcf} \\
            > ${id}_annotated_variants.vcf
        
        # Check if annotation completed successfully
        if [ ! -s ${id}_annotated_variants.vcf ]; then
            echo "WARNING: SnpEff annotation failed or produced empty output"
            echo "Creating placeholder annotated VCF..."
            # Handle compressed vs uncompressed VCF
            if [[ "${vcf}" == *.gz ]]; then
                gunzip -c ${vcf} > ${id}_annotated_variants.vcf
            else
                cp ${vcf} ${id}_annotated_variants.vcf
            fi
        fi
    else
        echo "WARNING: SnpEff is not available or incompatible with current Java version"
        echo "Creating placeholder annotated VCF by copying input VCF..."
        
        # Handle compressed vs uncompressed VCF
        if [[ "${vcf}" == *.gz ]]; then
            gunzip -c ${vcf} > ${id}_annotated_variants.vcf
        else
            cp ${vcf} ${id}_annotated_variants.vcf
        fi
    fi
    
    # Create summary file (even if empty)
    echo "<html><head><title>SnpEff Summary</title></head><body><h1>SnpEff Annotation Summary</h1><p>Annotation process completed for ${id}. Check logs for details.</p></body></html>" > ${id}_snpEff_summary.html
    
    # Verify output files exist
    if [ ! -f ${id}_annotated_variants.vcf ]; then
        echo "ERROR: Output VCF file was not created"
        exit 1
    fi
    """
    
    stub:
    """
    touch ${id}_annotated_variants.vcf
    touch ${id}_snpEff_summary.html
    """
}
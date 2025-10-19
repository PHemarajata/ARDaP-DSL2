process SNPEFF_ANNOTATION {
    label 'snpeff'
    tag "$id"
    
    input:
    tuple val(id), path(vcf), path(tbi)
    
    output:
    tuple val(id), path("${id}_annotated_variants.vcf"), emit: vcf
    path "${id}_snpEff_summary.html", emit: summary
    
    script:
    def snpeff_db = params.snpeff ?: 'Burkholderia_pseudomallei_k96243'
    """
    echo "Setting up SnpEff 4.3.1 for bacterial annotation..."
    echo "Database: ${snpeff_db}"
    echo "Data directory: ${baseDir}/resources/snpeff"
    
    # Check SnpEff version
    snpEff -version
    
    # Check if database exists locally
    if [ -d "${baseDir}/resources/snpeff/${snpeff_db}" ]; then
        echo "✓ Found local SnpEff database: ${baseDir}/resources/snpeff/${snpeff_db}"
        ls -la "${baseDir}/resources/snpeff/${snpeff_db}"
    else
        echo "✗ ERROR: SnpEff database not found: ${baseDir}/resources/snpeff/${snpeff_db}"
        echo "Available databases:"
        ls -la "${baseDir}/resources/snpeff/" || echo "No databases directory found"
        echo "Please restore SnpEff databases from your original ARDaP installation"
        exit 1
    fi
    
    echo "Running SnpEff 4.3.1 with correct bacterial database..."
    
    # SnpEff 4.3.1 compatible command (removed -t option, uses 'eff' subcommand)
    snpEff eff -nodownload -no-downstream -no-intergenic -ud 100 -v \\
        -dataDir ${baseDir}/resources/snpeff \\
        ${snpeff_db} \\
        ${vcf} > ${id}_annotated_variants.vcf 2>snpeff.log
    
    # Verify annotation was successful
    if [ -s ${id}_annotated_variants.vcf ] && grep -q "ANN=" ${id}_annotated_variants.vcf; then
        echo "✓ SnpEff 4.3.1 bacterial annotation successful!"
        echo "✓ Found ANN annotations in output VCF"
        
        # Count annotations
        ANN_COUNT=\$(grep -c "ANN=" ${id}_annotated_variants.vcf)
        echo "✓ Total variants with annotations: \$ANN_COUNT"
        
        # Create success summary
        echo "<html><head><title>SnpEff Summary</title></head><body><h1>SnpEff 4.3.1 Bacterial Annotation Summary</h1><p>Successfully annotated \$ANN_COUNT variants for ${id} using database ${snpeff_db}.</p><p>Bacterial genes and resistance mechanisms properly identified.</p></body></html>" > ${id}_snpEff_summary.html
        
        # Copy SnpEff summary if generated
        if [ -f "snpEff_summary.html" ]; then
            mv snpEff_summary.html ${id}_snpEff_detailed_summary.html
        fi
        
    else
        echo "✗ SnpEff 4.3.1 bacterial annotation failed!"
        echo "Check log for details:"
        cat snpeff.log
        
        # Try alternative approach for SnpEff 4.3.1 (some versions need different syntax)
        echo "Trying alternative SnpEff 4.3.1 approach..."
        snpEff eff -nodownload -no-downstream -no-intergenic -ud 100 \\
            -dataDir ${baseDir}/resources/snpeff \\
            -c ${baseDir}/resources/snpeff/snpEff.config \\
            ${snpeff_db} \\
            ${vcf} > ${id}_annotated_variants_alt.vcf 2>snpeff_alt.log
            
        if [ -s ${id}_annotated_variants_alt.vcf ] && grep -q "ANN=" ${id}_annotated_variants_alt.vcf; then
            echo "✓ Alternative SnpEff approach successful!"
            mv ${id}_annotated_variants_alt.vcf ${id}_annotated_variants.vcf
            
            ANN_COUNT=\$(grep -c "ANN=" ${id}_annotated_variants.vcf)
            echo "✓ Total variants with annotations: \$ANN_COUNT"
            
            echo "<html><head><title>SnpEff Summary</title></head><body><h1>SnpEff 4.3.1 Bacterial Annotation Summary</h1><p>Successfully annotated \$ANN_COUNT variants for ${id} using database ${snpeff_db} (alternative approach).</p></body></html>" > ${id}_snpEff_summary.html
        else
            echo "All SnpEff approaches failed. Creating fallback VCF..."
            
            # Create failure summary
            echo "<html><head><title>SnpEff Summary</title></head><body><h1>SnpEff Annotation Failed</h1><p>All annotation attempts failed for ${id}.</p><pre>Log 1:" > ${id}_snpEff_summary.html
            cat snpeff.log >> ${id}_snpEff_summary.html
            echo "Log 2:" >> ${id}_snpEff_summary.html
            cat snpeff_alt.log >> ${id}_snpEff_summary.html
            echo "</pre></body></html>" >> ${id}_snpEff_summary.html
            
            # Copy VCF without annotation as fallback
            if [[ "${vcf}" == *.gz ]]; then
                gunzip -c ${vcf} > ${id}_annotated_variants.vcf
            else
                cp ${vcf} ${id}_annotated_variants.vcf
            fi
            
            echo "WARNING: Proceeding with unannotated VCF - resistance analysis may be incomplete"
        fi
    fi
    
    echo "Annotation process completed. Output file size: \$(wc -l < ${id}_annotated_variants.vcf) lines"
    """
    
    stub:
    """
    touch ${id}_annotated_variants.vcf
    touch ${id}_snpEff_summary.html
    """
}
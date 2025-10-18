process READ_SYNTHESIS {
    label 'art'
    tag "$id"
    
    input:
    tuple val(id), path(assembly)
    
    output:
    tuple val(id), path("${assembly.baseName}_1_cov.fq.gz"), path("${assembly.baseName}_2_cov.fq.gz"), emit: reads
    
    script:
    """
    art_illumina -i ${assembly} -p -l 150 -f 30 -m 500 -s 10 -ss HS25 -na -o ${assembly.baseName}_out
    mv ${assembly.baseName}_out1.fq ${assembly.baseName}_1_cov.fq
    mv ${assembly.baseName}_out2.fq ${assembly.baseName}_2_cov.fq
    gzip ${assembly.baseName}_1_cov.fq
    gzip ${assembly.baseName}_2_cov.fq
    """
    
    stub:
    """
    touch ${assembly.baseName}_1_cov.fq.gz
    touch ${assembly.baseName}_2_cov.fq.gz
    """
}
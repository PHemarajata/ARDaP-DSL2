process DOWNSAMPLE {
    label 'ardap_default'
    tag "$id"
    publishDir "./Clean_reads", mode: 'copy', overwrite: false, enabled: params.publish_clean_reads ?: false
    
    input:
    tuple val(id), path(forward), path(reverse)
    
    output:
    tuple val(id), path("${id}_1_cov.fq.gz"), path("${id}_2_cov.fq.gz"), emit: reads
    
    script:
    if (params.size > 0) {
        """
        seqtk sample -s 11 ${forward} ${params.size} | gzip - > ${id}_1_cov.fq.gz
        seqtk sample -s 11 ${reverse} ${params.size} | gzip - > ${id}_2_cov.fq.gz
        """
    } else {
        """
        mv ${forward} ${id}_1_cov.fq.gz
        mv ${reverse} ${id}_2_cov.fq.gz
        """
    }
    
    stub:
    """
    touch ${id}_1_cov.fq.gz
    touch ${id}_2_cov.fq.gz
    """
}
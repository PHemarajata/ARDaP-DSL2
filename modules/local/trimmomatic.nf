process TRIMMOMATIC {
    label 'trimmomatic'
    tag "$id"
    
    input:
    tuple val(id), path(forward), path(reverse)
    
    output:
    tuple val(id), path("${id}_1.fq.temp.gz"), path("${id}_2.fq.temp.gz"), emit: reads
    
    script:
    if (params.notrim) {
        """
        mv ${forward} ${id}_1.fq.temp.gz
        mv ${reverse} ${id}_2.fq.temp.gz
        """
    } else {
        """
        trimmomatic PE -threads ${task.cpus} ${forward} ${reverse} \\
        ${id}_1.fq.temp.gz ${id}_1_u.fq.gz ${id}_2.fq.temp.gz ${id}_2_u.fq.gz \\
        ILLUMINACLIP:${baseDir}/resources/trimmomatic/all_adapters.fa:2:30:10: \\
        LEADING:10 TRAILING:10 SLIDINGWINDOW:4:15 MINLEN:36
        rm ${id}_1_u.fq.gz ${id}_2_u.fq.gz
        """
    }
    
    stub:
    """
    touch ${id}_1.fq.temp.gz
    touch ${id}_2.fq.temp.gz
    """
}
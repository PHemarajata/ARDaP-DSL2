process REFERENCE_ALIGNMENT {
    label 'alignment'
    tag "$id"
    publishDir "${params.outdir}/Resfinder", mode: 'copy', pattern: "*_resfinder.txt", overwrite: true
    publishDir "${params.outdir}/bams", mode: 'copy', pattern: "*.bam*", overwrite: true
    
    input:
    path ref_index
    tuple val(id), path(forward), path(reverse)
    
    output:
    tuple val(id), path("${id}.bam"), path("${id}.bam.bai"), emit: bam
    tuple val(id), path("${id}_resfinder.txt"), emit: resfinder_results
    
    script:
    if (params.fast) {
        """
        # Run masked alignment for fast mode
        bash ${baseDir}/bin/Masked_alignment.sh ${task.cpus} ${forward} ${reverse} ${id} ${baseDir} ${params.snpeff}
        
        bwa mem -R '@RG\\tID:${params.org}\\tSM:${id}\\tPL:ILLUMINA' -a \\
        -t ${task.cpus} ref ${forward} ${reverse} > ${id}.sam
        samtools view -h -b -@ 1 -q 1 -o ${id}.bam_tmp ${id}.sam
        samtools sort -@ 1 -o ${id}.bam ${id}.bam_tmp
        samtools index ${id}.bam
        rm ${id}.sam ${id}.bam_tmp
        
        bash ${baseDir}/bin/Run_resfinder.sh ${baseDir} ${forward} ${reverse} ${id}
        """
    } else {
        """
        bwa mem -R '@RG\\tID:${params.org}\\tSM:${id}\\tPL:ILLUMINA' -a \\
        -t ${task.cpus} ref ${forward} ${reverse} > ${id}.sam
        samtools view -h -b -@ 1 -q 1 -o ${id}.bam_tmp ${id}.sam
        samtools sort -@ 1 -o ${id}.bam ${id}.bam_tmp
        samtools index ${id}.bam
        rm ${id}.sam ${id}.bam_tmp
        
        bash ${baseDir}/bin/Run_resfinder.sh ${baseDir} ${forward} ${reverse} ${id}
        """
    }
    
    stub:
    """
    touch ${id}.bam
    touch ${id}.bam.bai
    touch ${id}_resfinder.txt
    """
}
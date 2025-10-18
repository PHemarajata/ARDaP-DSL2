process MARK_DUPLICATES {
    label 'markduplicates'
    tag "$id"
    publishDir "./Outputs/bams", mode: 'copy', overwrite: true
    
    input:
    tuple val(id), path(bam), path(bai)
    
    output:
    tuple val(id), path("${id}_dup.bam"), path("${id}_dup.bam.bai"), emit: bam
    path "${id}_metrics.txt", emit: metrics
    
    script:
    """
    picard MarkDuplicates \\
        I=${bam} \\
        O=${id}_dup.bam \\
        M=${id}_metrics.txt \\
        CREATE_INDEX=true \\
        VALIDATION_STRINGENCY=SILENT
    # Fix Picard's incorrect index naming convention  
    if [[ -f "${id}_dup.bai" && ! -f "${id}_dup.bam.bai" ]]; then
        mv "${id}_dup.bai" "${id}_dup.bam.bai"
    fi
    """
    
    stub:
    """
    touch ${id}_dup.bam
    touch ${id}_dup.bam.bai
    touch ${id}_metrics.txt
    """
}
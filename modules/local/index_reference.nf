process INDEX_REFERENCE {
    label 'index'
    
    input:
    path reference
    
    output:
    path "ref.*",                     emit: index
    path reference,                   emit: reference
    path "${reference}.fai",          emit: fai
    path "${reference.baseName}.dict", emit: dict
    path "${reference}.bed",          emit: bed
    
    script:
    """
    bwa index -a is -p ref ${reference}
    samtools faidx ${reference}
    picard CreateSequenceDictionary R=${reference} O=${reference.baseName}.dict
    bedtools makewindows -g ${reference}.fai -w ${params.window} > ${reference}.bed
    """
    
    stub:
    """
    touch ref.amb ref.ann ref.bwt ref.pac ref.sa
    touch ${reference}.fai
    touch ${reference.baseName}.dict
    touch ${reference}.bed
    """
}
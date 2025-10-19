process CREATE_EMPTY_DEL_DUP {
    tag "$id"
    
    input:
    tuple val(id), path(snp_file)
    
    output:
    tuple val(id), path("${id}.AbR_output_del_dup.txt")
    
    script:
    """
    echo "" > ${id}.AbR_output_del_dup.txt
    """
    
    stub:
    """
    touch ${id}.AbR_output_del_dup.txt
    """
}
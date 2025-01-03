process BWA_INDEX {
    conda "${moduleDir}/environment.yml"

    input:
    path(reference)

    output:
    path(bwa) , emit: indexed_reference
    
    script:
    """
    mkdir bwa
    bwa-mem2 index ${reference} \\
        -p bwa/\$(basename ${reference}) \\
        

    """
}

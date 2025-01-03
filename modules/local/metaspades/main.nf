process METASPADES {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    label 'process_high'

    publishDir "./results/assembly", pattern: '*.fasta', mode: 'copy'  

    input:
    tuple val(meta), path(trimmed_fastq_1), path(trimmed_fastq_2)
    
    output:
    tuple val(meta), path("${prefix}_assembly/contigs.fasta"), emit: assembly
    path "versions.yml", emit: versions
    
    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    spades.py \\
        --memory $MEM \\
        --only-assembler \\
        --threads  6 \\
        --pe1-1 ${fastq_1} \\
        --pe1-2 ${fastq_2} \\
        --meta \\
        -o ${prefix}_assembly
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spades: \$(spades.py --version 2>&1 | sed 's/^.*SPAdes genome assembler v//; s/ .*\$//')
    END_VERSIONS
    """
}

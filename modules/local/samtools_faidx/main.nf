process SAMTOOLS_FAIDX {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    label 'process_low'

    input:
    tuple val(meta), path(reference)

    output:
    tuple path("${reference}.fai"),   emit: fai
    path "versions.yml",              emit: versions

    script:
    """
    samtools faidx $reference
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(samtools --version | grep samtools | sed 's/samtools //')
    END_VERSIONS
    """

}

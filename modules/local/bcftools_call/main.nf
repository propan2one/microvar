process BCFTOOLS_CALL {
    conda "${moduleDir}/environment.yml"

    publishDir "./results/variants", pattern: '*.vcf.gz', mode: 'copy'

    input:
    tuple val(sample_id), path(bam), path(bai)
    tuple path(reference), path(fai)

    output:
    tuple val(sample_id), path("${sample_id}.vcf.gz"), path("${sample_id}.vcf.gz.tbi"), emit: vcf
    path "versions.yml", emit: versions
    
    script:
    """
    bcftools mpileup \\
        --output-type u \\
        --fasta-ref ${reference} \\
        --max-depth 8000 \\
        --annotate AD,DP \\
        ${bam} | bcftools call \\
            --variants-only \\
            --multiallelic-caller \\
            --output-type z \\
            --group-samples - \\
            --skip-variants indels \\
            --output ${sample_id}.vcf.gz
    bcftools index -t ${sample_id}.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}

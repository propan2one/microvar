process BWA_MEM {
	conda "${moduleDir}/environment.yml"

	publishDir "./results/mapping", pattern: '*.bam', mode: 'copy'
	publishDir "./results/mapping", pattern: '*.bai', mode: 'copy'

    input:
    tuple val(sample_id), path(reference), path(index_files), path(trimmed_fastq_1), path(trimmed_fastq_2)
     
    output:
    tuple val(sample), path("*.bam")	, emit: bam
    tuple val(sample), path("*bai")		, emit: bai
	path "versions.yml"                 , emit: versions

    script:
	"""
		INDEX=`find -L ./ -name "*.amb" | sed 's/.amb//'`

		bwa-mem2 \\
			mem \\
			-t 4 \\
			\$INDEX \\
			${read1} ${read2} \\
			| samtools sort --threads 4 -o ${sample}.bam
		
		samtools \\
			index \\
			-@ 1 \\
			${sample}.bam

	cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwa: \$(bwa 2>&1 | grep -i '^version' | sed 's/Version: //')
        samtools: \$(samtools --version | grep '^samtools' | sed 's/^samtools //')
    END_VERSIONS
	"""
}

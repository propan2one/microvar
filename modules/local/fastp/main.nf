process FASTP {
	tag "$meta.id"
	conda "${moduleDir}/environment.yml"
    label 'process_medium'
	
	input:
	tuple val(meta), path(fastq_1), path(fastq_2)
	
    output:
    tuple val(meta), path("${meta.id}_trimmed_1.fastq.gz"), 
        path("${meta.id}_trimmed_2.fastq.gz"),               emit: trimmed_reads
    path "*.json",                                           emit: json
    path "*.html",                                           emit: html
    path "versions.yml",                                     emit: versions

	script:
    def prefix = task.ext.prefix ?: "${meta.id}"
	"""
	fastp \\
		--in1 ${fastq_1} \\
		--in2 ${fastq_2} \\
		--out1 ${prefix}_trimmed_1.fastq.gz \\
		--out2 ${prefix}_trimmed_2.fastq.gz \\
		--json ${prefix}_fastp.json \\
		--html ${prefix}_fastp.html \\
		2> ${prefix}.fastp.log

	cat <<-END_VERSIONS > versions.yml
	"${task.process}":
		fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
	END_VERSIONS
	"""
}
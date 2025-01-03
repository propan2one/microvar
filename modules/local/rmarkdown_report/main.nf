process RMARKDOWN_REPORT {
    tag "$sample_id"
    publishDir "${params.outdir}/reports", mode: 'copy'

    input:
    tuple val(sample_id), path(stats)

    output:
    path "${sample_id}_report.html"

    script:
    """
    #!/usr/bin/env Rscript
    library(rmarkdown)
    rmarkdown::render("${projectDir}/templates/report_template.Rmd",
                      output_file = "${sample_id}_report.html",
                      params = list(sample_id = "$sample_id",
                                    stats_file = "$stats"))
    """
}
#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// Check mandatory parameters
if (params.samplesheet) { csv_file = file(params.samplesheet) } else { exit 1, 'Input samplesheet not specified!' }

/*
// To force user at providing a reference with the command line (241210JD)
if (params.reference == null) error "Please specify a reference genome fasta file with --reference"
def reference =  file(params.reference)
*/

log.info """\
    =======================================================================
    M I C R O V A R
    ======================================================================
    samplesheet: ${params.samplesheet}
    ======================================================================
    """
    .stripIndent()

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { MICROVAR } from './workflows/microvar'

workflow {
    // Read the samplesheet
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header:true, sep:',')
        .map { row -> 
            def meta = [:]
            meta.id = row.sample_id
            meta.reference = row.reference ? file(row.reference) : null
            [ meta, file(row.fastq_1), file(row.fastq_2) ]
        }
        .set { samples_ch }
    
    //
    // WORKFLOW: Run main workflow
    //
    MICROVAR(samples_ch)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
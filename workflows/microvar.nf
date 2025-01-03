#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Local to the pipeline
//
include { FASTP               } from '../modules/local/fastp/main'
include { METASPADES          } from '../modules/local/metaspades/main'
include { BWA_INDEX           } from '../modules/local/bwa_index/main'
include { SAMTOOLS_FAIDX      } from '../modules/local/samtools_faidx/main'
include { BWA_MEM             } from '../modules/local/bwa_mem/main'
include { SAMTOOLS_STATS      } from '../modules/local/samtools_stats/main'
include { BCFTOOLS_CALL       } from '../modules/local/bcftools_call/main'
include { MULTIQC             } from '../modules/local/multiqc/main'

//
// MODULE: Installed directly from nf-core/modules
//

//
// SUBWORKFLOWS: Consisting of a mix of local and nf-core/modules
//

workflow MICROVAR {
    // Read the samplesheet
    take:
    samples_ch // channel:  [ meta, file(row.fastq_1), file(row.fastq_2) ]

    main:
    // QC preprocessing of reads
    FASTP(samples_ch)
    // DEBUG: FASTP.out.trimmed_reads.view()

     // Perform de novo assembly if reference is not provided
    // METASPADES(FASTP.out.trimmed_reads.filter { it[0].reference == 'null' })
    METASPADES(FASTP.out.trimmed_reads.filter { sample_id, fastq_1, fastq_2, reference -> 
        reference.name == 'null' 
    })
    //METASPADES.out.assembly.view()

    // Combine reference genomes (provided or assembled)
    reference_ch = FASTP.out.trimmed_reads
        .map { meta, fastq_1, fastq_2 -> [meta.id, meta.reference] }
        .mix(METASPADES.out.assembly.map { meta, assembly -> [meta.id, assembly] })
        .groupTuple()
        .map { id, refs -> [id, refs.find { it != null }] }
    // DEBUG: reference_ch.view()
    // Index all references (provided and assembled) with BWA and Samtools
    BWA_INDEX(reference_ch)
    SAMTOOLS_FAIDX(reference_ch)

    // Align reads to reference
    BWA_MEM(FASTP.out.trimmed_reads.join(BWA_INDEX.out.indexed_reference))

    // Generate mapping statistics
    SAMTOOLS_STATS(BWA_MEM.out.bam, reference_ch)

    // Prepare input for BCFTOOLS_CALL
    bcftools_input = BWA_MEM.out.bam
        .combine(SAMTOOLS_FAIDX.out.fai, by: 1)
        .map { sample_id, bam, bai, reference, faidx ->
            tuple(sample_id, bam, bai, reference, faidx)
        }
    bcftools_input.view()
    
    //BWA_MEM.out.bam.map { tuple -> tuple[1] }.collect().view()
    // Call variants
    BCFTOOLS_CALL(
        bcftools_input.map { sample_id, bam, bai, reference, faidx ->
            tuple(sample_id, bam, bai)
        },
        bcftools_input.map { sample_id, bam, bai, reference, faidx ->
            tuple(reference, faidx)
        }
    )
    
    // Generate MultiQC report
    MULTIQC(
        Channel.empty().mix(
            FASTP.out.json,
            SAMTOOLS_STATS.out.stats,
            // ... other process outputs ...
        ).collect(),
        []  // Empty list for optional config file
    )

    emit:
    multiqc_report = MULTIQC.out.report
}
    //emit:

    /*
    // Generate individual sample reports
    RMARKDOWN_REPORT(SAMTOOLS_STATS.out.stats)

    // Generate MultiQC report
    MULTIQC(SAMTOOLS_STATS.out.stats.collect(), FASTP.out.json.collect())
    */
// }

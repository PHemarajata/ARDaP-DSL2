#!/usr/bin/env nextflow

/*
 *
 *  Pipeline            ARDaP
 *  Version             2.4.0 DSL2
 *  Description         Antimicrobial resistance detection and prediction from WGS
 *  Authors             Derek Sarovich, Erin Price, Danielle Madden, Eike Steinig
 *  Updated to DSL2     Seqera AI Assistant
 *
 */

nextflow.enable.dsl = 2

log.info """
===============================================================================
                           NF-ARDaP DSL2
                             v2.4.0
================================================================================

Optional Parameters:

    --fastq      Input PE read file wildcard (default: *_{1,2}.fastq.gz)

                 Currently this is set to $params.fastq

    --species    Species specific database for resistance determination
                 (default: Burkholderia_pseudomallei)

                 Currently you are using $params.species

    --assemblies Optionally include a directory of assembled genomes in the
                 analysis. Set this parameter to 'true' if you wish to included
                 assembled genomes and place all assembled genomes in a
                 subdirectory called 'assemblies'. (default: false)

                 Currently assemblies is set to $params.assemblies

    --notrim     Although not generally recommended to switch off, set to true
                 if you want to skip the trimmomatic step (default: false).
                 Currently notrim is set to $params.notrim

    --mixtures   Optionally perform within species mixtures analysis.
                 Set this parameter to 'true' if you are dealing with
                 multiple strains. (default: false)

                 Currently mixtures is set to $params.mixtures

    --size       ARDaP can optionally down-sample your read data to
                 run through the pipeline quicker. Please set to 0 to skip this step
                 (default: 1000000)

                 Currently you are using $params.size

                 Currently executor is set to $params.executor

    --fast       **Experimental**. Future implementation to only look at regions that
                 may cause AMR rather than the whole genome. I expect this may impact on the
                 performance of predicting structural variants.

                 Currently fast is set to $params.fast

    --gwas       **Experimental**. If you have a database of GWAS co-ordinates
                 ARDaP can interrogate SNPs and indels across the entire genome
                 to identify novel mutations likely contributing to an antibiotic
                 resistance phenotype. For more information about this feature,
                 please contact the developers.

                 Currently gwas is set to $params.gwas


==================================================================
==================================================================
"""

/*
==============================================================================
    MODULES AND PROCESSES
==============================================================================
*/

// Include all process modules
include { INDEX_REFERENCE                      } from './modules/local/index_reference.nf'
include { READ_SYNTHESIS                       } from './modules/local/read_synthesis.nf'
include { TRIMMOMATIC                          } from './modules/local/trimmomatic.nf'
include { DOWNSAMPLE                           } from './modules/local/downsample.nf'
include { REFERENCE_ALIGNMENT                  } from './modules/local/reference_alignment.nf'
include { MARK_DUPLICATES                      } from './modules/local/mark_duplicates.nf'
include { GATK_HAPLOTYPE_CALLER               } from './modules/local/gatk_haplotypecaller.nf'
include { GATK_GENOTYPE_GVCFS                 } from './modules/local/gatk_genotypegvcfs.nf'
include { VARIANT_FILTER                       } from './modules/local/variant_filter.nf'
include { PINDEL                               } from './modules/local/pindel.nf'
include { SNPEFF_ANNOTATION                    } from './modules/local/snpeff_annotation.nf'
include { DELLY                                } from './modules/local/delly.nf'
include { SQL_QUERIES_SNP_INDEL               } from './modules/local/sql_queries_snp_indel.nf'
include { SQL_QUERIES_DEL_DUP                  } from './modules/local/sql_queries_del_dup.nf'
include { ABRESISTANCE_REPORT                  } from './modules/local/abresistance_report.nf'
include { HTML_REPORT                          } from './modules/local/html_report.nf'
include { MERGE_VCF                            } from './modules/local/merge_vcf.nf'
include { SNP_MATRIX                           } from './modules/local/snp_matrix.nf'
include { PHYLOGENY                            } from './modules/local/phylogeny.nf'

/*
==============================================================================
    VALIDATION AND INITIALIZATION
==============================================================================
*/

// Validate required parameters and files
if (!params.species) {
    log.error "ERROR: Please provide a species parameter (--species)"
    exit 1
}

// Find reference and species-specific databases
species = params.species
database_config_file = "${baseDir}/Databases/Database.config"



// Get reference and database paths
def get_database_info(species, config_file) {
    try {
        def lines = file(config_file).readLines()
        def matching_line = lines.find { it.startsWith("${species}\t") }
        
        if (!matching_line) {
            log.error "ERROR: Species '${species}' not found in database config"
            exit 1
        }
        
        def parts = matching_line.split('\t')
        if (parts.size() < 3) {
            log.error "ERROR: Invalid database config format for species '${species}'"
            exit 1
        }
        
        return [database: parts[1].trim(), reference: parts[2].trim()]
    } catch (Exception e) {
        log.error "ERROR: Could not read database config file: ${e.message}"
        exit 1
    }
}

def db_info = get_database_info(species, database_config_file)
def database = db_info.database
def ref = db_info.reference

// Set derived parameters
params.reference = "${baseDir}/Databases/${database}/${ref}"
params.resistance_db = "${baseDir}/Databases/${database}/${database}.db"
params.snpeff = database
// Set default values for optional analyses
params.matrix = params.matrix ?: false
params.phylogeny = params.phylogeny ?: false
// Validate required files
def resistance_database_file = file(params.resistance_db)
if (!resistance_database_file.exists()) {
    log.error "ERROR: The resistance database file does not exist: ${params.resistance_db}"
    exit 1
}

def reference_file = file(params.reference)
if (!reference_file.exists()) {
    log.error """
    ERROR: ARDaP can't find the reference file.
    It is currently looking for this file --> ${params.reference}
    Please check that this reference exists here --> ${baseDir}/Databases/${database}/${ref}
    If this file doesn't exist either ARDaP is not configured to run with this reference/species
    or there was an error during the installation process and ARDaP needs to be re-installed
    """
    exit 1
}

def patient_meta_file = file(params.patientMetaData)
if (!patient_meta_file.exists()) {
    log.error "ERROR: The specified patient metadata file does not exist: ${params.patientMetaData}"
    exit 1
}

/*
==============================================================================
    MAIN WORKFLOW
==============================================================================
*/

workflow {
    
    // Create input channels
    fastq_ch = Channel
        .fromFilePairs(params.fastq, flat: true)
        .ifEmpty { 
            log.error """
            ERROR: Input read files could not be found.
            Have you included the read files in the current directory and do they have the correct naming?
            With the parameters specified, ARDaP is looking for reads named ${params.fastq}.
            To fix this error either rename your reads to match this formatting or specify the desired format
            when initializing ARDaP e.g. --fastq "*_{1,2}_sequence.fastq.gz"
            """
            exit 1
        }
    
    // Optional assembly channel
    assembly_ch = Channel.empty()
    if (params.assemblies) {
        assembly_ch = Channel
            .fromPath(params.assembly_loc, checkIfExists: true)
            .ifEmpty { log.warn "No assembled genomes will be processed" }
            .map { file ->
                def id = file.name.toString().tokenize('.').get(0)
                return tuple(id, file)
            }
    }
    
    //
    // WORKFLOW: Run ARDaP analysis
    //
    
    // Step 1: Index reference genome
    INDEX_REFERENCE(reference_file)
    
    // Step 2: Generate synthetic reads from assemblies (if provided)
    synthetic_reads_ch = Channel.empty()
    if (params.assemblies) {
        READ_SYNTHESIS(assembly_ch)
        synthetic_reads_ch = READ_SYNTHESIS.out.reads
    }
    
    // Step 3: Read preprocessing
    TRIMMOMATIC(fastq_ch)
    DOWNSAMPLE(TRIMMOMATIC.out.reads)
    
    // Combine real and synthetic reads
    all_reads_ch = DOWNSAMPLE.out.reads.mix(synthetic_reads_ch)
    
    // Step 4: Reference alignment
    REFERENCE_ALIGNMENT(
        INDEX_REFERENCE.out.index,
        all_reads_ch
    )
    
    // Step 5: Mark duplicates
    MARK_DUPLICATES(REFERENCE_ALIGNMENT.out.bam)
    
    // Step 6: Variant calling with GATK HaplotypeCaller
    GATK_HAPLOTYPE_CALLER(
        MARK_DUPLICATES.out.bam,
        INDEX_REFERENCE.out.reference,
        INDEX_REFERENCE.out.fai,
        INDEX_REFERENCE.out.dict
    )
    
    // Step 7: Genotype GVCFs  
    GATK_GENOTYPE_GVCFS(
        GATK_HAPLOTYPE_CALLER.out.gvcf,
        INDEX_REFERENCE.out.reference,
        INDEX_REFERENCE.out.fai,
        INDEX_REFERENCE.out.dict
    )
    
    // Step 8: Filter variants
    VARIANT_FILTER(
        GATK_GENOTYPE_GVCFS.out.vcf,
        INDEX_REFERENCE.out.reference,
        INDEX_REFERENCE.out.fai,
        INDEX_REFERENCE.out.dict
    )
    
    // Step 9: Structural variant calling
    if (params.delly) {
        DELLY(
            MARK_DUPLICATES.out.bam,
            INDEX_REFERENCE.out.reference,
            INDEX_REFERENCE.out.fai
        )
    }
    
    // Step 10: Indel calling with Pindel
    PINDEL(
        MARK_DUPLICATES.out.bam,
        INDEX_REFERENCE.out.reference
    )
    
    // Step 11: Annotation with SnpEff
    SNPEFF_ANNOTATION(VARIANT_FILTER.out.vcf)
    
    // Step 12: SQL queries for SNP/Indel analysis
    SQL_QUERIES_SNP_INDEL(
        SNPEFF_ANNOTATION.out.vcf,
        file(params.resistance_db)
    )
    
    // Step 13: SQL queries for structural variants
    if (params.delly) {
        SQL_QUERIES_DEL_DUP(
            DELLY.out.vcf,
            file(params.resistance_db)
        )
    }
    
    // Step 14: Generate antibiotic resistance reports
    // Join channels by sample ID to ensure matching
    snp_and_resfinder = SQL_QUERIES_SNP_INDEL.out.results
        .join(REFERENCE_ALIGNMENT.out.resfinder_results)

    ABRESISTANCE_REPORT(
        snp_and_resfinder,                     // Now each tuple is [id, snp_file, resfinder_file]
        file(params.patientMetaData)
    )
    // Step 15: Generate HTML report
    HTML_REPORT(
        ABRESISTANCE_REPORT.out.reports,
        file(params.patientMetaData)
    )
    
    // Optional: Matrix and phylogeny analysis
    // Optional: Matrix and phylogeny analysis
    // DISABLED - causing issues with empty VCF
    /*
    if (params.matrix) {
        MERGE_VCF(
            VARIANT_FILTER.out.vcf.map { id, vcf, tbi -> vcf }.collect(),
            INDEX_REFERENCE.out.reference,
            INDEX_REFERENCE.out.fai,
            INDEX_REFERENCE.out.dict
        )
        SNP_MATRIX(MERGE_VCF.out.vcf)
        
        if (params.phylogeny) {
            PHYLOGENY(SNP_MATRIX.out.matrix)
        }
    }
    */
}

/*
==============================================================================
    COMPLETION
==============================================================================
*/

workflow.onComplete {
    log.info (workflow.success ? 
        """
        Pipeline completed successfully!
        
        Results summary:
        - HTML reports are available in: ./Outputs/Reports/
        - BAM alignment files are in: ./Outputs/bams/
        - VCF variant files are in: ./Outputs/Variants/VCFs/
        - Phylogenetic analysis (if enabled) is in: ./Outputs/Phylogeny_and_annotation/
        - Resistance gene analysis is in: ./Outputs/Resfinder/
        
        """ : 
        "Pipeline completed with errors. Please check the log files for details."
    )
}
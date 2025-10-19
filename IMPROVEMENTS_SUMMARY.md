# ARDaP DSL2 Improvements Summary

## Overview
This document summarizes the improvements made to the ARDaP-DSL2 workflow to address the issues identified with missing antimicrobial resistance information and ensure proper output organization and resumability.

## Key Issues Addressed

### 1. Missing Databases Directory
**Problem:** The DSL2 version was missing the `Databases` directory containing species-specific databases and references.
**Solution:** Copied the entire `Databases` directory from the original DSL1 version.

### 2. Inconsistent Output Directory Structure
**Problem:** Files were scattered across different locations, making results hard to find.
**Solution:** 
- Changed default `outdir` parameter from `./results` to `./Outputs` to match original
- Added consistent `publishDir` directives to all modules using `${params.outdir}`
- Organized outputs into logical subdirectories:
  - `${params.outdir}/AbR_reports/` - Final resistance reports (text & HTML)
  - `${params.outdir}/bams/` - Alignment files
  - `${params.outdir}/Variants/VCFs/` - Variant call files
  - `${params.outdir}/Resfinder/` - ResFinder analysis results
  - `${params.outdir}/Intermediate/` - Intermediate analysis files

### 3. Missing Intermediate Files for SQL Queries
**Problem:** The SQL query scripts expect specific intermediate files that weren't being created properly.
**Solution:** Enhanced `SQL_QUERIES_SNP_INDEL` module to:
- Extract SNP and indel effects from VCF files
- Create properly formatted intermediate files (`${id}.annotated.snp.effects`, etc.)
- Generate high-impact variant files for function loss analysis
- Ensure all expected input files exist before running SQL scripts

### 4. Broken Channel Dependencies
**Problem:** The ABR report generation was failing due to missing del_dup results channel.
**Solution:**
- Created `CREATE_EMPTY_DEL_DUP` module to generate empty del_dup files for individual sample analysis
- Properly joined SNP/indel, ResFinder, and del_dup results channels
- Updated `ABRESISTANCE_REPORT` module to accept all three input types

### 5. Phylogeny Steps Removal
**Problem:** User requested removal of phylogeny analysis since only individual samples are analyzed.
**Solution:**
- Commented out phylogeny-related includes (`MERGE_VCF`, `SNP_MATRIX`, `PHYLOGENY`)
- Removed phylogeny workflow logic from main workflow
- Disabled matrix and phylogeny parameters in config
- Removed phylogeny references from completion message

### 6. Incomplete Report Generation
**Problem:** HTML and text reports weren't being generated with complete resistance information.
**Solution:**
- Enhanced `ABRESISTANCE_REPORT` module to properly handle all input files
- Updated `HTML_REPORT` module to receive all necessary inputs including drug susceptibility data
- Ensured proper file naming conventions match what the shell scripts expect
- Added proper database path resolution using species parameter

### 7. Resumability Issues
**Problem:** Workflow wasn't properly resumable due to output handling issues.
**Solution:**
- Added proper `publishDir` configuration to all modules
- Set `resume = true` in config
- Configured proper work directory handling
- Added cleanup settings for better resource management

## Module Updates

### Updated Modules:
1. **sql_queries_snp_indel.nf**: Enhanced VCF processing and intermediate file creation
2. **sql_queries_del_dup.nf**: Improved output naming and empty file handling
3. **abresistance_report.nf**: Added support for all three input channels
4. **html_report.nf**: Enhanced input handling and file management
5. **reference_alignment.nf**: Added BAM file publishing
6. **variant_filter.nf**: Added VCF file publishing

### New Module:
- **create_empty_del_dup.nf**: Generates empty del_dup files for individual sample workflows

## Configuration Changes

### nextflow.config:
- Changed `outdir` from `./results` to `./Outputs`
- Disabled matrix and phylogeny parameters
- Enhanced resource allocation profiles
- Improved resume functionality

## Workflow Logic Improvements

### main.nf:
- Added proper database path resolution
- Enhanced channel joining logic
- Removed phylogeny workflow sections
- Improved completion messages with detailed output locations
- Added proper error handling for missing files

## Expected Output Structure

After running the improved workflow, users will find:

```
Outputs/
├── AbR_reports/                    # Final reports
│   ├── [SAMPLE]_report.html       # Interactive HTML report
│   ├── [SAMPLE].AbR_output.final.txt  # Text resistance summary
│   └── patientDrugSusceptibilityData.csv  # Drug susceptibility data
├── bams/                           # Alignment files
│   ├── [SAMPLE].bam
│   └── [SAMPLE].bam.bai
├── Variants/VCFs/                  # Variant files
│   └── [SAMPLE]_filtered_variants.vcf.gz
├── Resfinder/                      # Gene-based resistance analysis
│   └── [SAMPLE]_resfinder.txt
└── Intermediate/                   # Analysis intermediates
    ├── [SAMPLE].AbR_output_snp_indel.txt
    └── [SAMPLE].AbR_output_del_dup.txt
```

## Benefits of These Improvements

1. **Complete Resistance Reporting**: All antimicrobial resistance information is now properly captured and reported
2. **Individual Sample Focus**: Workflow optimized for individual sample analysis without phylogeny overhead
3. **Consistent Output Structure**: All results organized in predictable locations using `outdir` parameter
4. **Full Resumability**: Proper publishDir configuration enables reliable workflow resumption
5. **Better Error Handling**: Enhanced validation and fallback mechanisms
6. **Cleaner Workflow Logic**: Removed unnecessary phylogeny components, focusing on core resistance detection

## Testing Recommendations

1. Test with known samples that have resistance markers
2. Verify all output files are created in expected locations
3. Confirm HTML reports display resistance information properly
4. Test resumability by interrupting and restarting workflow
5. Validate results match expectations from original DSL1 version

## Usage Notes

The workflow is now optimized for individual sample resistance analysis:
- Use `--outdir` parameter to specify custom output location
- Ensure input FASTQ files follow naming convention: `*_{1,2}.fastq.gz`
- Place metadata in `Reports/data/patientMetaData.csv`
- Results will be organized by analysis type in the output directory
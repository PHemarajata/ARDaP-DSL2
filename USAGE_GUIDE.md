# ARDaP DSL2 - Improved Usage Guide

## Quick Start

### 1. Prepare Your Data
Place your paired-end FASTQ files in the current directory with naming pattern: `*_{1,2}.fastq.gz`

Example:
```
sample1_1.fastq.gz
sample1_2.fastq.gz
sample2_1.fastq.gz  
sample2_2.fastq.gz
```

### 2. Set Up Metadata
Edit `Reports/data/patientMetaData.csv` to include your sample information. The file should contain sample IDs that match your FASTQ file prefixes.

### 3. Run the Workflow

#### Basic usage:
```bash
nextflow run main.nf --species Burkholderia_pseudomallei
```

#### With custom parameters:
```bash
nextflow run main.nf \
    --species Burkholderia_pseudomallei \
    --fastq "*_{1,2}.fq.gz" \
    --outdir ./my_results
```

#### Resume a previous run:
```bash
nextflow run main.nf -resume --species Burkholderia_pseudomallei
```

## Available Species

The workflow supports the following species databases:
- `Burkholderia_pseudomallei` (default)
- `Pseudomonas_aeruginosa`  
- `Haemophilus_influenzae`
- `Stenotrophomonas_maltophilia`

## Key Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--species` | `Burkholderia_pseudomallei` | Species-specific database to use |
| `--fastq` | `"*_{1,2}.fastq.gz"` | Input FASTQ file pattern |
| `--outdir` | `"./Outputs"` | Output directory for results |
| `--size` | `1000000` | Read subsampling size (0 = no subsampling) |
| `--notrim` | `true` | Skip trimming step |
| `--fast` | `true` | Use fast alignment mode |

## Output Structure

After successful completion, you'll find:

```
Outputs/
├── AbR_reports/                          # 📊 MAIN RESULTS
│   ├── [SAMPLE]_report.html             # Interactive resistance report
│   ├── [SAMPLE].AbR_output.final.txt    # Text resistance summary
│   └── patientDrugSusceptibilityData.csv # Drug susceptibility data
├── bams/                                 # 🧬 Alignment files
│   ├── [SAMPLE].bam
│   └── [SAMPLE].bam.bai
├── Variants/VCFs/                        # 🧪 Variant calls
│   └── [SAMPLE]_filtered_variants.vcf.gz
├── Resfinder/                            # 🔍 Gene analysis
│   └── [SAMPLE]_resfinder.txt
└── Intermediate/                         # 🔧 Processing files
    ├── [SAMPLE].AbR_output_snp_indel.txt
    └── [SAMPLE].AbR_output_del_dup.txt
```

## Understanding Your Results

### HTML Reports (`[SAMPLE]_report.html`)
- **Interactive dashboard** with resistance predictions
- **Drug susceptibility tables** by antibiotic class  
- **Mechanism details** for each resistance gene/mutation found
- **Quality control metrics** and analysis summary

### Text Reports (`[SAMPLE].AbR_output.final.txt`)
- **Tab-delimited summary** of all resistance mechanisms
- **Format:** `Method|Gene|Mutation|Antibiotic|Confidence`
- **Suitable for** automated processing and spreadsheet import

### ResFinder Results (`[SAMPLE]_resfinder.txt`)
- **Gene-based resistance detection** results
- **Coverage and identity** statistics for resistance genes
- **Raw output** from ResFinder analysis

## Troubleshooting

### Common Issues

1. **"Species not found in database config"**
   - Check available species with: `cat Databases/Database.config`
   - Use exact species name from first column

2. **"Input read files could not be found"**
   - Verify FASTQ files match the pattern (default: `*_{1,2}.fastq.gz`)
   - Use custom pattern: `--fastq "your_pattern_here"`

3. **"Reference file does not exist"**
   - Database may be corrupted or missing
   - Check: `ls Databases/[SPECIES]/`

4. **Empty or incomplete reports**
   - May indicate no resistance found (normal for sensitive strains)
   - Check intermediate files in `Outputs/Intermediate/`

### Resume Failed Runs
If a run fails or is interrupted:
```bash
nextflow run main.nf -resume --species [YOUR_SPECIES]
```

The workflow will skip completed steps and continue from where it left off.

### Performance Optimization

#### For faster runs (testing):
```bash
nextflow run main.nf --species Burkholderia_pseudomallei --size 100000
```

#### For maximum sensitivity:
```bash
nextflow run main.nf --species Burkholderia_pseudomallei --size 0 --fast false
```

## Workflow Profiles

### Standard (default)
- Local execution on single machine
- Balanced resource usage

### Workstation  
- Optimized for 22-core/64GB workstations
```bash
nextflow run main.nf -profile workstation --species [SPECIES]
```

### High-performance
- For systems with >100 cores/500GB RAM
```bash
nextflow run main.nf -profile dgx --species [SPECIES]
```

### Testing
- Quick runs with minimal data
```bash
nextflow run main.nf -profile test --species [SPECIES]
```

## Individual Sample Focus

This improved workflow is optimized for **individual sample analysis**:
- ✅ Individual resistance profiles per sample
- ✅ Complete antimicrobial resistance reporting  
- ✅ Gene-based and mutation-based resistance detection
- ❌ Phylogenetic analysis removed (use original DSL1 for population studies)
- ❌ SNP matrix generation disabled
- ❌ Tree building disabled

## Getting Help

1. **Validation:** Run `./validate_improvements.sh` to check workflow setup
2. **Documentation:** See `IMPROVEMENTS_SUMMARY.md` for technical details  
3. **Issues:** Check Nextflow logs in `Outputs/pipeline_info/`
4. **Original documentation:** Refer to `README.md` for additional background

## Example Complete Run

```bash
# 1. Prepare data
ls *_{1,2}.fastq.gz  # Verify your files are present

# 2. Edit metadata  
nano Reports/data/patientMetaData.csv

# 3. Run analysis
nextflow run main.nf --species Burkholderia_pseudomallei

# 4. Check results
ls -la Outputs/AbR_reports/
firefox Outputs/AbR_reports/[SAMPLE]_report.html  # View HTML report
```

This will analyze all samples and generate comprehensive antimicrobial resistance reports with both text and HTML formats.
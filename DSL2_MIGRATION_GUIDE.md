# ARDaP DSL2 Migration Guide

This guide explains the migration from DSL1 to DSL2 and the new features in ARDaP v2.4.0.

## Major Changes

### 1. DSL2 Syntax Update
- **Modular design**: Pipeline is now split into individual process modules in `modules/local/`
- **Improved workflow structure**: Main workflow is more readable and maintainable
- **Better channel handling**: Automatic channel forking eliminates the need for explicit `.into()` operations
- **Enhanced resumability**: Much better support for pipeline resumption at any step

### 2. Updated Dependencies
- **Nextflow**: Updated to v24.04.4 (minimum v23.04.0)
- **Java**: Updated to OpenJDK 17 for better performance and compatibility
- **GATK**: Updated to v4.5.0.0 with improved performance
- **Python**: Updated to 3.11 with modern scientific libraries
- **Tools**: All bioinformatics tools updated to latest stable versions

### 3. New Hardware Profiles

#### Workstation Profile (`-profile workstation`)
Optimized for local workstation with 22 cores and 64GB RAM:
- Reserves 2 cores and 8GB for system overhead
- Optimized resource allocation per process
- Queue size limited to prevent overwhelming the system

```bash
nextflow run main.nf -profile workstation --fastq "*_{1,2}.fastq.gz"
```

#### DGX Profile (`-profile dgx`)
Optimized for NVIDIA DGX Station A100 with 128 cores and 512GB RAM:
- Reserves 8 cores and 32GB for system overhead
- Higher parallelization for compute-intensive processes
- Larger queue size for efficient resource utilization

```bash
nextflow run main.nf -profile dgx --fastq "*_{1,2}.fastq.gz"
```

### 4. Improved Environment Management

Three environment options are provided:

1. **Full Environment** (`environment.yml`): Complete with R, plotting capabilities, and all optional tools
2. **Minimal Environment** (`environment_minimal.yml`): Essential tools only for basic functionality
3. **Legacy Support**: Original `env.yaml` maintained for backward compatibility

## Migration Steps

### Step 1: Update Environment

Choose one of the following approaches:

#### Option A: Full Environment (Recommended)
```bash
# Create new environment with full functionality
conda env create -f environment.yml
conda activate ardap
```

#### Option B: Minimal Environment (Faster installation)
```bash
# Create minimal environment for basic functionality
conda env create -f environment_minimal.yml
conda activate ardap-minimal
```

### Step 2: Update Configuration

Replace your current configuration:

```bash
# Backup current config
cp nextflow.config nextflow.config.backup

# Use new DSL2 configuration
cp nextflow.config.dsl2 nextflow.config
```

### Step 3: Update Main Script

Replace the main pipeline file:

```bash
# Backup current main script
cp main.nf main.nf.dsl1.backup

# Use new DSL2 main script
cp main.nf.dsl2 main.nf
```

### Step 4: Test Migration

Run a small test to ensure everything works:

```bash
# Test with minimal data (if available)
nextflow run main.nf -profile test --fastq "test_data/*_{1,2}.fastq.gz"

# Or test with your hardware profile
nextflow run main.nf -profile workstation --fastq "*_{1,2}.fastq.gz" --size 10000
```

## Key Improvements for Resumability

### 1. Better Work Directory Management
- Consistent file naming across processes
- Proper staging of intermediate files
- Reduced file I/O through optimization

### 2. Enhanced Error Handling
- Smarter retry strategies based on exit codes
- Better memory scaling on retry attempts
- Improved error reporting

### 3. Process Isolation
- Each process is now a separate module
- Better dependency tracking
- Easier to debug individual steps

## Running the Pipeline

### Basic Usage
```bash
# Standard run
nextflow run main.nf --fastq "*_{1,2}.fastq.gz" --species "Burkholderia_pseudomallei"

# With workstation profile
nextflow run main.nf -profile workstation --fastq "*_{1,2}.fastq.gz"

# With DGX profile  
nextflow run main.nf -profile dgx --fastq "*_{1,2}.fastq.gz"

# Resume from interruption
nextflow run main.nf -resume --fastq "*_{1,2}.fastq.gz"
```

### Advanced Options
```bash
# Skip trimming (not recommended)
nextflow run main.nf --notrim false

# Enable phylogeny analysis
nextflow run main.nf --phylogeny true --matrix true

# Enable mixtures analysis
nextflow run main.nf --mixtures true

# Custom sampling size
nextflow run main.nf --size 500000

# Fast mode (experimental)
nextflow run main.nf --fast true
```

## Resource Requirements

### Minimum Requirements
- 4 cores, 8GB RAM
- 50GB storage space
- Linux/macOS

### Recommended for Workstation Profile
- 22+ cores, 64GB+ RAM
- 200GB+ storage space
- SSD storage for work directory

### Recommended for DGX Profile
- 128+ cores, 512GB+ RAM
- 1TB+ high-speed storage
- NVMe storage for optimal I/O

## Troubleshooting

### Common Issues

#### 1. Java Version Conflicts
If you see Java-related errors:
```bash
conda install openjdk=17
export JAVA_HOME=$CONDA_PREFIX
```

#### 2. Memory Issues
Reduce memory requirements in configuration or use test profile:
```bash
nextflow run main.nf -profile test
```

#### 3. Resume Issues
Clean work directory if resume fails:
```bash
rm -rf work/
nextflow run main.nf --fastq "*_{1,2}.fastq.gz"
```

#### 4. Environment Creation Fails
Try minimal environment first:
```bash
conda env create -f environment_minimal.yml
```

### Getting Help

1. Check the execution report: `results/pipeline_info/execution_report.html`
2. Review trace file: `results/pipeline_info/execution_trace.txt`
3. Check individual process logs in `work/` directories
4. Use `-with-trace` and `-with-report` for detailed execution information

## Performance Tips

1. **Use profiles**: Always specify a hardware-appropriate profile
2. **SSD storage**: Use SSD/NVMe storage for the work directory
3. **Memory allocation**: Monitor memory usage and adjust if needed
4. **Parallelization**: The pipeline automatically parallelizes where possible
5. **Resume capability**: Always use `-resume` if restarting

## Compatibility

- **Backward compatible**: All original parameters and options are supported
- **Data compatibility**: Existing databases and reference files work without modification
- **Output compatibility**: Output formats and directory structure remain the same
# Conda Environment Troubleshooting Guide

## Common Issues and Solutions

### Issue: PackagesNotFoundError (like `biopython=1.81`)

This happens when exact package versions aren't available in current channels or for your platform.

#### Solution 1: Use More Flexible Environment (Recommended)
```bash
# Try the robust environment with flexible versions
conda env create -f environment_robust.yml
conda activate ardap
```

#### Solution 2: Update Conda and Channels
```bash
# Update conda to latest version
conda update conda

# Add/update channels in correct priority order
conda config --add channels conda-forge
conda config --add channels bioconda
conda config --add channels defaults

# Try creating environment again
conda env create -f environment_minimal.yml
```

#### Solution 3: Use Mamba (Faster and Better at Resolving Dependencies)
```bash
# Install mamba if not already installed
conda install mamba -n base -c conda-forge

# Use mamba instead of conda
mamba env create -f environment.yml
```

#### Solution 4: Manual Package Installation
If specific packages are causing issues, create a minimal environment and add packages individually:

```bash
# Create basic environment
conda create -n ardap python=3.9 pip

# Activate environment
conda activate ardap

# Install packages one by one (skip problematic ones initially)
conda install -c bioconda nextflow bwa samtools gatk4
conda install -c conda-forge numpy pandas matplotlib

# For problematic packages, try without version constraints
conda install -c bioconda biopython
```

### Issue: Channel Conflicts or Slow Resolution

#### Solution: Clean Channel Configuration
```bash
# Reset channel configuration
conda config --remove-key channels

# Add channels in optimal order
conda config --add channels defaults
conda config --add channels bioconda  
conda config --add channels conda-forge

# Clear package cache
conda clean --all
```

### Issue: Platform-Specific Problems

#### macOS with Apple Silicon (M1/M2)
```bash
# Use x86_64 emulation for better compatibility
CONDA_SUBDIR=osx-64 conda env create -f environment_minimal.yml
```

#### Linux ARM64
```bash
# Some bioinformatics packages may not be available for ARM64
# Try using conda-forge first
conda install -c conda-forge nextflow python numpy
conda install -c bioconda bwa samtools gatk4
```

### Issue: Environment Creation is Very Slow

#### Solution: Use Mamba + Libmamba Solver
```bash
# Install mamba for faster solving
conda install mamba -n base -c conda-forge

# Or use the new libmamba solver in conda
conda install -n base conda-libmamba-solver
conda config --set solver libmamba

# Then create environment
mamba env create -f environment.yml
```

## Environment Options by Reliability

### Most Reliable: `environment_robust.yml`
- Flexible version constraints
- Widely available packages
- Should work on most platforms

### Fast Installation: `environment_minimal.yml`
- Essential tools only
- Flexible versions
- Quick to install and resolve

### Full Featured: `environment.yml` 
- All analysis tools included
- May have occasional version conflicts
- Use mamba for best results

## Alternative Installation Methods

### Option 1: Docker (Most Reliable)
```bash
# Use a pre-built container with all tools
docker pull biocontainers/nextflow
# Or build your own from the Dockerfile
```

### Option 2: System Package Manager
```bash
# On Ubuntu/Debian
sudo apt install nextflow bwa samtools bcftools

# On macOS with Homebrew
brew install nextflow bwa samtools bcftools
```

### Option 3: Conda-Free Installation
```bash
# Install Nextflow directly
curl -s https://get.nextflow.io | bash

# Install other tools as needed
# Many bioinformatics tools provide direct installation options
```

## Testing Your Environment

After successful installation, test with:

```bash
# Activate environment
conda activate ardap  # or ardap-minimal

# Test key tools
nextflow -version
samtools --version
gatk --version
python -c "import biopython; print(biopython.__version__)"

# Run validation script
./validate_dsl2.sh
```

## Getting Help

1. **Check conda version**: `conda --version` (update if < 4.10)
2. **Check channel configuration**: `conda config --show channels`
3. **Try alternative environment files** provided
4. **Use mamba** instead of conda for better dependency resolution
5. **Report specific error messages** for targeted assistance

## Environment File Hierarchy

1. Try `environment_robust.yml` first (most compatible)
2. If issues, try `environment_minimal.yml` (fastest)
3. For full features, use `environment.yml` with mamba
4. As last resort, use manual installation approach
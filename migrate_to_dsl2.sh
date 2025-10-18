#!/bin/bash

# ARDaP DSL2 Migration Script
# This script helps migrate from DSL1 to DSL2 version

set -euo pipefail

echo "==================================================================="
echo "              ARDaP DSL2 Migration Script"
echo "==================================================================="

# Check if we're in the ARDaP directory
if [[ ! -f "main.nf" ]] || [[ ! -d "Databases" ]]; then
    echo "ERROR: This script must be run from the ARDaP root directory"
    echo "Please ensure you're in the directory containing main.nf and Databases/"
    exit 1
fi

# Create backup directory
BACKUP_DIR="backup_dsl1_$(date +%Y%m%d_%H%M%S)"
echo "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"

# Backup original files
echo "Backing up original files..."
cp main.nf "${BACKUP_DIR}/main.nf.dsl1"
cp nextflow.config "${BACKUP_DIR}/nextflow.config.dsl1"
if [[ -f "env.yaml" ]]; then
    cp env.yaml "${BACKUP_DIR}/env.yaml.original"
fi
if [[ -f "env_full.yaml" ]]; then
    cp env_full.yaml "${BACKUP_DIR}/env_full.yaml.original"  
fi

echo "Backup completed in ${BACKUP_DIR}/"

# Apply DSL2 updates
echo ""
echo "Applying DSL2 updates..."

# Update main pipeline file
if [[ -f "main.nf.dsl2" ]]; then
    cp main.nf.dsl2 main.nf
    echo "✓ Updated main.nf to DSL2 version"
else
    echo "ERROR: main.nf.dsl2 not found. Please ensure all DSL2 files are present."
    exit 1
fi

# Update configuration
if [[ -f "nextflow.config.dsl2" ]]; then
    cp nextflow.config.dsl2 nextflow.config
    echo "✓ Updated nextflow.config with new profiles and settings"
else
    echo "ERROR: nextflow.config.dsl2 not found. Please ensure all DSL2 files are present."
    exit 1
fi

# Check if modules directory exists
if [[ ! -d "modules/local" ]]; then
    echo "ERROR: modules/local directory not found. Please ensure all DSL2 module files are present."
    exit 1
fi

echo "✓ DSL2 modules are in place"

# Environment setup
echo ""
echo "==================================================================="
echo "Environment Setup Options:"
echo "==================================================================="
echo ""
echo "Choose your environment setup:"
echo "  1. Full environment (environment.yml) - Recommended"
echo "     Includes all tools, R packages, and plotting capabilities"
echo ""
echo "  2. Minimal environment (environment_minimal.yml) - Faster"
echo "     Essential tools only, quicker installation"
echo ""
echo "  3. Manual setup - I'll configure the environment myself"
echo ""

read -p "Enter your choice (1-3): " env_choice

case $env_choice in
    1)
        if [[ -f "environment.yml" ]]; then
            echo ""
            echo "Setting up full environment..."
            echo "This may take 10-30 minutes depending on your internet connection."
            echo ""
            read -p "Proceed with conda environment creation? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                conda env create -f environment.yml
                echo "✓ Full environment created successfully"
                echo "  Activate with: conda activate ardap"
            else
                echo "Environment creation skipped"
            fi
        else
            echo "ERROR: environment.yml not found"
            exit 1
        fi
        ;;
    2)
        if [[ -f "environment_minimal.yml" ]]; then
            echo ""
            echo "Setting up minimal environment..."
            echo "This should take 5-15 minutes."
            echo ""
            read -p "Proceed with conda environment creation? (y/N): " confirm
            if [[ $confirm =~ ^[Yy]$ ]]; then
                conda env create -f environment_minimal.yml
                echo "✓ Minimal environment created successfully"
                echo "  Activate with: conda activate ardap-minimal"
            else
                echo "Environment creation skipped"
            fi
        else
            echo "ERROR: environment_minimal.yml not found"
            exit 1
        fi
        ;;
    3)
        echo "Manual setup selected. You'll need to ensure all dependencies are available."
        ;;
    *)
        echo "Invalid choice. Environment setup skipped."
        ;;
esac

# Hardware profile recommendation
echo ""
echo "==================================================================="
echo "Hardware Profile Recommendations:"
echo "==================================================================="
echo ""

# Detect system resources
if command -v nproc >/dev/null 2>&1; then
    CORES=$(nproc)
else
    CORES="unknown"
fi

if command -v free >/dev/null 2>&1; then
    MEMORY_GB=$(free -g | awk '/^Mem:/{print $2}')
else
    MEMORY_GB="unknown"  
fi

echo "Detected system resources:"
echo "  CPU cores: ${CORES}"
echo "  Memory: ${MEMORY_GB}GB"
echo ""

if [[ "$CORES" != "unknown" ]] && [[ "$MEMORY_GB" != "unknown" ]]; then
    if (( CORES >= 100 && MEMORY_GB >= 400 )); then
        echo "🚀 Recommended profile: -profile dgx"
        echo "   Your system appears to be high-end (100+ cores, 400+ GB RAM)"
    elif (( CORES >= 20 && MEMORY_GB >= 50 )); then
        echo "💻 Recommended profile: -profile workstation"  
        echo "   Your system appears to be a powerful workstation (20+ cores, 50+ GB RAM)"
    elif (( CORES >= 8 && MEMORY_GB >= 16 )); then
        echo "🖥️  Recommended profile: -profile standard"
        echo "   Your system should work with the standard profile"
    else
        echo "🧪 Recommended profile: -profile test"
        echo "   Your system has limited resources, consider using test profile for small datasets"
    fi
else
    echo "Unable to detect system resources automatically."
    echo "Please choose the appropriate profile based on your hardware:"
    echo "  -profile dgx        : 100+ cores, 400+ GB RAM"
    echo "  -profile workstation: 20+ cores, 50+ GB RAM"  
    echo "  -profile standard   : 8+ cores, 16+ GB RAM"
    echo "  -profile test       : Limited resources"
fi

# Test run suggestion
echo ""
echo "==================================================================="
echo "Test Your Migration:"
echo "==================================================================="
echo ""
echo "To test your DSL2 migration, try a small test run:"
echo ""

if [[ "$env_choice" == "1" ]]; then
    echo "conda activate ardap"
elif [[ "$env_choice" == "2" ]]; then
    echo "conda activate ardap-minimal"
fi

echo 'nextflow run main.nf -profile test --fastq "test_*_{1,2}.fastq.gz" --size 1000'
echo ""
echo "Or with your recommended profile:"
if [[ "$CORES" != "unknown" ]] && [[ "$MEMORY_GB" != "unknown" ]]; then
    if (( CORES >= 100 && MEMORY_GB >= 400 )); then
        echo 'nextflow run main.nf -profile dgx --fastq "*_{1,2}.fastq.gz"'
    elif (( CORES >= 20 && MEMORY_GB >= 50 )); then
        echo 'nextflow run main.nf -profile workstation --fastq "*_{1,2}.fastq.gz"'
    else
        echo 'nextflow run main.nf -profile standard --fastq "*_{1,2}.fastq.gz"'
    fi
else
    echo 'nextflow run main.nf -profile workstation --fastq "*_{1,2}.fastq.gz"'
fi

echo ""
echo "==================================================================="
echo "Migration Summary:"
echo "==================================================================="
echo "✓ Original files backed up to: ${BACKUP_DIR}/"
echo "✓ DSL2 pipeline files installed"  
echo "✓ Configuration updated with new profiles"
echo "✓ Module-based architecture implemented"

if [[ "$env_choice" == "1" ]] || [[ "$env_choice" == "2" ]]; then
    echo "✓ Conda environment configured"
fi

echo ""
echo "Key improvements in DSL2 version:"
echo "  • Better resumability between all steps"
echo "  • Optimized resource allocation for different hardware"
echo "  • Improved dependency management"
echo "  • Modular, maintainable code structure"
echo "  • Enhanced error handling and reporting"
echo ""
echo "For detailed documentation, see: DSL2_MIGRATION_GUIDE.md"
echo ""
echo "🎉 Migration to DSL2 completed successfully!"
echo "==================================================================="
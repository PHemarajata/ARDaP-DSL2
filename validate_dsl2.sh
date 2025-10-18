#!/bin/bash

# DSL2 Validation Script
# Quick validation of the DSL2 migration

set -euo pipefail

echo "==================================================================="
echo "                ARDaP DSL2 Validation Script"
echo "==================================================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    if [[ "$status" == "PASS" ]]; then
        echo -e "${GREEN}✓ $message${NC}"
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "${RED}✗ $message${NC}"
    elif [[ "$status" == "WARN" ]]; then
        echo -e "${YELLOW}⚠ $message${NC}"
    fi
}

# Validation counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

validate_file() {
    local file=$1
    local description=$2
    if [[ -f "$file" ]]; then
        print_status "PASS" "$description found"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "$description missing"
        ((FAIL_COUNT++))
    fi
}

validate_directory() {
    local dir=$1
    local description=$2
    if [[ -d "$dir" ]]; then
        print_status "PASS" "$description found"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "$description missing"
        ((FAIL_COUNT++))
    fi
}

echo "1. Validating DSL2 Pipeline Files..."
echo "-------------------------------------------------------------------"

validate_file "main.nf.dsl2" "DSL2 main pipeline"
validate_file "nextflow.config.dsl2" "DSL2 configuration"
validate_file "environment.yml" "Full environment file"
validate_file "environment_minimal.yml" "Minimal environment file"
validate_file "migrate_to_dsl2.sh" "Migration script"
validate_file "DSL2_MIGRATION_GUIDE.md" "Migration guide"

echo ""
echo "2. Validating Module Structure..."
echo "-------------------------------------------------------------------"

validate_directory "modules" "Modules directory"
validate_directory "modules/local" "Local modules directory"

# Check individual modules
MODULES=(
    "index_reference.nf"
    "read_synthesis.nf"
    "trimmomatic.nf"
    "downsample.nf"
    "reference_alignment.nf"
    "mark_duplicates.nf"
    "gatk_haplotypecaller.nf"
    "gatk_genotypegvcfs.nf"
    "variant_filter.nf"
    "pindel.nf"
    "delly.nf"
    "snpeff_annotation.nf"
    "sql_queries_snp_indel.nf"
    "sql_queries_del_dup.nf"
    "abresistance_report.nf"
    "html_report.nf"
    "merge_vcf.nf"
    "snp_matrix.nf"
    "phylogeny.nf"
)

for module in "${MODULES[@]}"; do
    validate_file "modules/local/$module" "Module: $module"
done

echo ""
echo "3. Validating DSL2 Syntax..."
echo "-------------------------------------------------------------------"

if [[ -f "main.nf.dsl2" ]]; then
    if grep -q "nextflow.enable.dsl = 2" main.nf.dsl2; then
        print_status "PASS" "DSL2 enabled in main pipeline"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "DSL2 not properly enabled"
        ((FAIL_COUNT++))
    fi
    
    if grep -q "include {" main.nf.dsl2; then
        print_status "PASS" "Module includes found"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "No module includes found"
        ((FAIL_COUNT++))
    fi
    
    if grep -q "workflow {" main.nf.dsl2; then
        print_status "PASS" "Main workflow block found"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "No main workflow block found"
        ((FAIL_COUNT++))
    fi
else
    print_status "FAIL" "Cannot validate DSL2 syntax - main.nf.dsl2 missing"
    ((FAIL_COUNT++))
fi

echo ""
echo "4. Validating Configuration Profiles..."
echo "-------------------------------------------------------------------"

if [[ -f "nextflow.config.dsl2" ]]; then
    PROFILES=("standard" "workstation" "dgx" "test" "conda" "singularity" "docker")
    
    for profile in "${PROFILES[@]}"; do
        if grep -q "$profile {" nextflow.config.dsl2; then
            print_status "PASS" "Profile '$profile' defined"
            ((PASS_COUNT++))
        else
            print_status "WARN" "Profile '$profile' not found (may be optional)"
            ((WARN_COUNT++))
        fi
    done
    
    if grep -q "check_max" nextflow.config.dsl2; then
        print_status "PASS" "Resource limit checking function found"
        ((PASS_COUNT++))
    else
        print_status "FAIL" "Resource limit checking function missing"
        ((FAIL_COUNT++))
    fi
else
    print_status "FAIL" "Cannot validate profiles - nextflow.config.dsl2 missing"
    ((FAIL_COUNT++))
fi

echo ""
echo "5. Validating Environment Files..."
echo "-------------------------------------------------------------------"

check_env_file() {
    local file=$1
    local name=$2
    
    if [[ -f "$file" ]]; then
        if grep -q "nextflow" "$file"; then
            print_status "PASS" "$name contains Nextflow"
            ((PASS_COUNT++))
        else
            print_status "WARN" "$name missing Nextflow (may use system version)"
            ((WARN_COUNT++))
        fi
        
        if grep -q "gatk4" "$file"; then
            print_status "PASS" "$name contains GATK4"
            ((PASS_COUNT++))
        else
            print_status "FAIL" "$name missing GATK4"
            ((FAIL_COUNT++))
        fi
        
        if grep -q "openjdk" "$file"; then
            print_status "PASS" "$name contains Java"
            ((PASS_COUNT++))
        else
            print_status "FAIL" "$name missing Java"
            ((FAIL_COUNT++))
        fi
        
        # Check for pinned versions vs flexible versions
        if grep -q "=" "$file"; then
            print_status "PASS" "$name has version constraints"
            ((PASS_COUNT++))
        else
            print_status "WARN" "$name has no version constraints"
            ((WARN_COUNT++))
        fi
    fi
}

check_env_file "environment.yml" "Full environment"
check_env_file "environment_minimal.yml" "Minimal environment"

echo ""
echo "6. Checking for Nextflow Installation..."
echo "-------------------------------------------------------------------"

if command -v nextflow >/dev/null 2>&1; then
    NEXTFLOW_VERSION=$(nextflow -version | head -n1 | awk '{print $3}')
    print_status "PASS" "Nextflow installed (version: $NEXTFLOW_VERSION)"
    ((PASS_COUNT++))
    
    # Check if version is adequate (23.04.0+)
    if [[ $(echo "$NEXTFLOW_VERSION 23.04.0" | tr " " "\n" | sort -V | head -n1) == "23.04.0" ]]; then
        print_status "PASS" "Nextflow version is compatible with DSL2 features"
        ((PASS_COUNT++))
    else
        print_status "WARN" "Nextflow version may be too old for some DSL2 features"
        ((WARN_COUNT++))
    fi
else
    print_status "WARN" "Nextflow not found in PATH (will be installed via conda)"
    ((WARN_COUNT++))
fi

echo ""
echo "7. Validating Required Directories..."
echo "-------------------------------------------------------------------"

REQUIRED_DIRS=("Databases" "bin" "configs" "resources")

for dir in "${REQUIRED_DIRS[@]}"; do
    validate_directory "$dir" "Required directory: $dir"
done

echo ""
echo "8. Checking Original Files..."
echo "-------------------------------------------------------------------"

validate_file "main.nf" "Original main.nf (will be backed up)"
validate_file "nextflow.config" "Original nextflow.config (will be backed up)"

echo ""
echo "==================================================================="
echo "                    Validation Summary"
echo "==================================================================="

TOTAL_CHECKS=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))

echo "Validation Results:"
echo "  ✓ Passed: $PASS_COUNT"
echo "  ⚠ Warnings: $WARN_COUNT"  
echo "  ✗ Failed: $FAIL_COUNT"
echo "  Total checks: $TOTAL_CHECKS"

echo ""

if [[ $FAIL_COUNT -eq 0 ]]; then
    print_status "PASS" "All critical validations passed!"
    echo ""
    echo "✅ Ready for DSL2 migration!"
    echo ""
    echo "Next steps:"
    echo "  1. Run the migration script: ./migrate_to_dsl2.sh"
    echo "  2. Set up your conda environment"
    echo "  3. Test with: nextflow run main.nf -profile test"
    
    exit 0
elif [[ $FAIL_COUNT -le 2 ]] && [[ $WARN_COUNT -le 5 ]]; then
    print_status "WARN" "Migration possible with some issues"
    echo ""
    echo "⚠️  Migration can proceed, but address failures first"
    echo ""
    echo "Common fixes:"
    echo "  - Ensure all DSL2 files are present"
    echo "  - Check file permissions"
    echo "  - Verify you're in the correct directory"
    
    exit 1
else
    print_status "FAIL" "Too many critical issues found"
    echo ""
    echo "❌ Fix critical issues before proceeding with migration"
    echo ""
    echo "Please ensure all DSL2 files are properly created and accessible."
    
    exit 2
fi
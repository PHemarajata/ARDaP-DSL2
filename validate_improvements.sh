#!/bin/bash

echo "==================================================================================="
echo "                           ARDaP DSL2 Validation Script"
echo "==================================================================================="
echo ""

# Check 1: Databases directory exists
echo "✓ Checking for Databases directory..."
if [ -d "Databases" ]; then
    echo "  ✓ Databases directory found"
    echo "  ✓ Available species databases:"
    ls Databases/ | grep -v "\.config" | grep -v "Blank" | grep -v "CARD" | sed 's/^/    - /'
else
    echo "  ℹ️  INFO: Databases directory not found (expected if using existing local copy)"
    echo "  📝 Make sure to copy your existing Databases directory here before running"
fi

echo ""

# Check 1b: SnpEff resources exist
echo "✓ Checking for SnpEff annotation databases..."
if [ -d "resources/snpeff" ] && [ "$(ls -A resources/snpeff 2>/dev/null)" ]; then
    echo "  ✓ SnpEff databases found"
    echo "  ✓ Available SnpEff databases:"
    ls resources/snpeff/ | sed 's/^/    - /'
else
    echo "  ℹ️  INFO: SnpEff databases not found (expected if using existing local copy)"
    echo "  📝 Make sure to copy your existing resources/snpeff/* here before running"
fi

echo ""

# Check 2: Configuration has correct output directory
echo "✓ Checking output directory configuration..."
if grep -q 'outdir.*=.*"./Outputs"' nextflow.config; then
    echo "  ✓ Output directory set to ./Outputs"
else
    echo "  ✗ WARNING: Output directory not set to ./Outputs"
fi

echo ""

# Check 3: Phylogeny components disabled
echo "✓ Checking phylogeny removal..."
disabled_includes=$(grep -c "^// include.*phylogeny\|^// include.*matrix\|^// include.*merge_vcf" main.nf)
if [ "$disabled_includes" -eq 3 ]; then
    echo "  ✓ Phylogeny-related includes properly commented out"
else
    echo "  ✗ WARNING: Some phylogeny includes may still be active"
fi

if grep -q 'phylogeny.*=.*false' nextflow.config; then
    echo "  ✓ Phylogeny parameter disabled in config"
else
    echo "  ✗ WARNING: Phylogeny parameter not disabled"
fi

echo ""

# Check 4: Module improvements
echo "✓ Checking module improvements..."

# Check SQL_QUERIES_SNP_INDEL has publishDir
if grep -q "publishDir.*Intermediate" modules/local/sql_queries_snp_indel.nf; then
    echo "  ✓ SQL_QUERIES_SNP_INDEL has publishDir configured"
else
    echo "  ✗ WARNING: SQL_QUERIES_SNP_INDEL missing publishDir"
fi

# Check ABRESISTANCE_REPORT has correct inputs
if grep -q "path(del_dup_results)" modules/local/abresistance_report.nf; then
    echo "  ✓ ABRESISTANCE_REPORT accepts del_dup results"
else
    echo "  ✗ WARNING: ABRESISTANCE_REPORT may not handle del_dup results"
fi

# Check CREATE_EMPTY_DEL_DUP module exists
if [ -f "modules/local/create_empty_del_dup.nf" ]; then
    echo "  ✓ CREATE_EMPTY_DEL_DUP module created"
else
    echo "  ✗ ERROR: CREATE_EMPTY_DEL_DUP module missing"
fi

echo ""

# Check 5: publishDir patterns
echo "✓ Checking publishDir configurations..."
publishdir_count=$(find modules/local -name "*.nf" -exec grep -l "publishDir.*params.outdir" {} \; | wc -l)
echo "  ✓ Found $publishdir_count modules with params.outdir publishDir configuration"

echo ""

# Check 6: Resume configuration
echo "✓ Checking resume settings..."
if grep -q "resume = true" nextflow.config; then
    echo "  ✓ Resume enabled in configuration"
else
    echo "  ✗ WARNING: Resume not enabled"
fi

if grep -q "workDir = './work'" nextflow.config; then
    echo "  ✓ Work directory configured"
else
    echo "  ✗ WARNING: Work directory not properly configured"
fi

echo ""

# Check 7: Essential files and structure
echo "✓ Checking essential files..."
essential_files=(
    "main.nf"
    "nextflow.config"
    "Reports/data/patientMetaData.csv"
    "environment.yml"
    "bin/AbR_reports.sh"
    "bin/SQL_queries_SNP_indel.sh"
    "bin/Report_html.sh"
)

for file in "${essential_files[@]}"; do
    if [ -e "$file" ]; then
        echo "  ✓ $file exists"
    else
        echo "  ✗ WARNING: $file missing"
    fi
done

echo ""
echo "==================================================================================="
echo "Validation complete! Review any WARNING or ERROR messages above."
echo "==================================================================================="

# Return exit code based on critical errors
if [ ! -f "modules/local/create_empty_del_dup.nf" ]; then
    echo "CRITICAL ERRORS FOUND - workflow may not function properly"
    exit 1
elif [ ! -d "Databases" ]; then
    echo "⚠️  WARNING: Remember to copy your Databases directory before running the workflow"
    echo "Basic validation passed - workflow should be functional once databases are added"
    exit 0
else
    echo "Basic validation passed - workflow should be functional"
    exit 0
fi
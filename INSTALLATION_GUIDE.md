# ARDaP DSL2 - Installation Guide

## 📦 **Setup Instructions**

Since this download **does not include the Databases directory** (to reduce download size), you'll need to copy your existing local Databases directory.

## 🔧 **Step-by-Step Installation**

### 1. **Extract the Workflow**
```bash
# If using compressed archive:
tar -xzf ARDaP-DSL2-improved-lightweight.tar.gz
cd ARDaP-DSL2

# Or simply navigate to the directory if downloaded as folder
cd ARDaP-DSL2
```

### 2. **Copy Your Databases Directory and SnpEff Resources** 
```bash
# Copy databases from your existing ARDaP installation
# Replace /path/to/your/existing/ARDaP with your actual path
cp -r /path/to/your/existing/ARDaP/Databases ./

# Copy SnpEff databases for annotation
cp -r /path/to/your/existing/ARDaP/resources/snpeff/* ./resources/snpeff/

# Example:
# cp -r ../ARDaP-original/Databases ./
# cp -r ../ARDaP-original/resources/snpeff/* ./resources/snpeff/
```

### 3. **Validate the Setup**
```bash
./validate_improvements.sh
```

Expected output:
```
✓ Databases directory found
✓ Available species databases:
    - Burkholderia_pseudomallei_k96243
    - Haemophilus_influenzae_rd_kw20
    - Pseudomonas_aeruginosa_pao1
    - Stenotrophomonas_maltophilia_k279a
```

### 4. **Test Configuration**
```bash
nextflow config
```

### 5. **Ready to Run!**
```bash
nextflow run main.nf --species Burkholderia_pseudomallei
```

## 📁 **Required Databases Directory Structure**

Your directory structure should look like this after copying:
```
Databases/
├── Database.config                           # Species configuration
├── Burkholderia_pseudomallei_k96243/        # Species database
│   ├── k96243.fasta                        # Reference genome
│   ├── Burkholderia_pseudomallei_k96243.db # Resistance database
│   └── ...
├── Pseudomonas_aeruginosa_pao1/
├── Haemophilus_influenzae_rd_kw20/
├── Stenotrophomonas_maltophilia_k279a/
└── ...

resources/snpeff/
├── Burkholderia_pseudomallei_k96243/        # SnpEff annotation databases
├── Pseudomonas_aeruginosa_pao1/
├── Haemophilus_influenzae_rd_kw20/
├── Stenotrophomonas_maltophilia_k279a/
└── ...
```

## ⚠️ **Troubleshooting**

### "Species not found in database config"
- Check that `Databases/Database.config` exists
- Verify the species name matches exactly (case-sensitive)
- Available species: `cat Databases/Database.config`

### "Reference file does not exist"  
- Ensure the reference FASTA file exists in the species subdirectory
- Check file permissions are readable

### "Resistance database file does not exist"
- Verify the `.db` file exists in the species directory
- Check the Database.config file has correct paths

## 🎯 **What You Get**

### Lightweight Download Contents:
- ✅ **Core workflow files** (~148KB)
- ✅ **Enhanced modules** (all 19+ processes)  
- ✅ **Configuration files** (nextflow.config, environment.yml)
- ✅ **Shell scripts and tools** (bin/ directory)
- ✅ **Documentation suite** (all improvement guides)
- ✅ **Validation tools** (setup checking)
- ❌ **Databases** (you provide from your local copy)

### After Adding Databases:
- ✅ **Complete antimicrobial resistance detection**
- ✅ **Individual sample focus** (no phylogeny overhead)
- ✅ **Organized outputs** with outdir parameter
- ✅ **Full resumability** with proper publishDir
- ✅ **Enhanced HTML & text reporting**

## 📊 **Download Size Comparison**

| Version | Size | Contents |
|---------|------|----------|
| Full (original) | 345MB | Workflow + Databases |
| Lightweight | 167MB | Workflow only |
| **Savings** | **178MB** | **52% smaller!** |

## 🚀 **Quick Verification**

After setup, run this quick check:
```bash
# Check workflow syntax
nextflow run main.nf --help

# Validate all components  
./validate_improvements.sh

# Test with your data
nextflow run main.nf --species Burkholderia_pseudomallei
```

## 💡 **Pro Tips**

1. **Keep databases central**: Consider symlinking if you have multiple ARDaP versions
   ```bash
   ln -s /path/to/central/Databases ./Databases
   ```

2. **Version control**: Your databases can stay separate from the workflow code

3. **Updates**: Future workflow updates won't require re-downloading large databases

**The improved workflow is ready to provide complete antimicrobial resistance analysis with the same quality as the original, but with better organization and resumability!** 🎯
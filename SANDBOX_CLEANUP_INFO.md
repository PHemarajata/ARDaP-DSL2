# Sandbox Cleanup Information

## What Was Removed

To make this sandbox package efficiently downloadable, the following large files were removed:

### 🗑️ **Removed (736MB saved)**
- **Database files (471MB)**: 
  - `Databases/Pseudomonas_aeruginosa_pao1/` (255MB)
  - `Databases/Resfinder_general/` (95MB)
  - `Databases/Stenotrophomonas_maltophilia_k279a/` (44MB)
  - `Databases/Blank_database_template/` (39MB)
  - `Databases/CARD/` (32MB)
  - `Databases/Burkholderia_pseudomallei_k96243/` (7.2MB)
  - `Databases/Haemophilus_influenzae_rd_kw20/` (1.9MB)

- **Large resource files (6.6MB)**:
  - `resources/snpeff/` directory

### ✅ **Preserved (7MB total)**
- **All DSL2 migration files**:
  - `main.nf.dsl2` - Complete DSL2 pipeline
  - `nextflow.config.dsl2` - Enhanced configuration
  - `environment.yml` & `environment_minimal.yml` - Working dependencies
  - `modules/local/` - All 19 process modules

- **Essential scripts and tools**:
  - `bin/` - All analysis scripts
  - `migrate_to_dsl2.sh` - Migration script
  - `validate_dsl2.sh` - Validation script

- **Documentation**:
  - `README.md` - Updated with proper attribution
  - `DSL2_MIGRATION_GUIDE.md` - Migration instructions
  - `DSL2_UPDATE_SUMMARY.md` - Technical summary
  - All other documentation files

- **Configuration files**:
  - `configs/` - Pipeline configurations
  - `resources/trimmomatic/` - Essential adapters
  - `Reports/` - Report templates and data
  - `Databases/Database.config` - Database configuration

- **Original files for reference**:
  - `main.nf` - Original DSL1 pipeline
  - `nextflow.config` - Original configuration
  - `env.yaml` & `env_full.yaml` - Original environments

## Size Reduction

- **Before cleanup**: 743MB
- **After cleanup**: 7MB
- **Space saved**: 736MB (99.1% reduction)

## How to Restore Full Database Functionality

When you use this clean package, you'll need to download the databases separately:

### Option 1: Clone Original Repository for Databases
```bash
# Clone original repository in a separate directory
git clone https://github.com/dsarov/ARDaP.git original-ardap

# Copy databases to your DSL2 installation
cp -r original-ardap/Databases/* /path/to/ARDaP-DSL2/Databases/
cp -r original-ardap/resources/snpeff /path/to/ARDaP-DSL2/resources/
```

### Option 2: Use Migration Script
The `migrate_to_dsl2.sh` script can automatically handle this when applied to an existing ARDaP installation.

## What This Package Contains

This clean package is perfect for:

✅ **DSL2 development and testing**  
✅ **Migration script distribution**  
✅ **Documentation and examples**  
✅ **Environment setup and validation**  
✅ **Code review and contribution**

## Next Steps

1. **Download this efficient package** (7MB vs 743MB)
2. **Follow the README.md** for installation instructions
3. **Use migration script** if you have existing ARDaP with databases
4. **Or clone original databases** separately as needed

The DSL2 migration is complete and functional - you just need to add the species-specific databases for actual analysis!
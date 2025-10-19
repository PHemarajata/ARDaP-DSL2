# Hotfix: ABRESISTANCE_REPORT Module Error

## 🐛 **Issue Identified**
The `ABRESISTANCE_REPORT` process was failing with:
```
cp: 'IP-0132-1_S2_L001.AbR_output_snp_indel.txt' and 'IP-0132-1_S2_L001.AbR_output_snp_indel.txt' are the same file
```

## 🔧 **Root Cause**
The module was trying to copy input files to themselves when the file names already matched the expected format. This happened because:

1. `SQL_QUERIES_SNP_INDEL` correctly produces: `${id}.AbR_output_snp_indel.txt`
2. `CREATE_EMPTY_DEL_DUP` correctly produces: `${id}.AbR_output_del_dup.txt` 
3. `ABRESISTANCE_REPORT` tried to copy these to the same names → **ERROR**

## ✅ **Solution Applied**
Updated `modules/local/abresistance_report.nf` to use conditional copying:

```bash
# Only copy if files have different names
if [ "${snp_indel_results}" != "${id}.AbR_output_snp_indel.txt" ]; then
    cp ${snp_indel_results} ${id}.AbR_output_snp_indel.txt
fi

if [ "${del_dup_results}" != "${id}.AbR_output_del_dup.txt" ]; then
    cp ${del_dup_results} ${id}.AbR_output_del_dup.txt
fi

if [ "${resfinder_results}" != "${id}_resfinder.txt" ]; then
    ln -sf ${resfinder_results} ${id}_resfinder.txt
fi

if [ "${metadata}" != "patientMetaData.csv" ]; then
    cp ${metadata} patientMetaData.csv
fi
```

## 🚀 **Resume Your Workflow**
You can now resume your workflow:
```bash
nextflow run main.nf -resume --species Burkholderia_pseudomallei
```

The workflow will skip completed steps and continue from the `ABRESISTANCE_REPORT` process with the fixed logic.

## ✅ **Expected Behavior**
- Files with correct names are used directly (no unnecessary copying)
- Files with different names are copied/linked as needed
- The `AbR_reports.sh` script receives properly named input files
- Resistance reports generate successfully

This fix ensures robust handling of file names regardless of how the upstream modules name their outputs.
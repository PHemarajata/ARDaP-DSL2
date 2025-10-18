#!/bin/bash

vcf=$1
RESISTANCE_DB=$2 
id=$3

# Extract sequence name from VCF filename (remove .vcf extension)
seq=$(basename "$vcf" .vcf) 

cat << _EOF_ >  Variant_ignore_Q.txt  
SELECT
Variants_SNP_indel.Gene_name,
Variants_SNP_indel.Variant_annotation
FROM
	Variants_SNP_indel
WHERE
	Variants_SNP_indel.Antibiotic_affected LIKE '%none%';
_EOF_

sqlite3 "$RESISTANCE_DB" < Variant_ignore_Q.txt >> Variant_ignore.txt;

sed -i 's/|/ /g' Variant_ignore.txt 

# Check if required input files exist, create empty ones if missing
if [ ! -f "${seq}.Function_lost_list.txt" ]; then
    echo "Warning: ${seq}.Function_lost_list.txt not found, creating empty file"
    touch "${seq}.Function_lost_list.txt"
fi

if [ ! -f "${seq}.deletion_summary.txt" ]; then
    echo "Warning: ${seq}.deletion_summary.txt not found, creating empty file with header"
    echo -e "Chromosome\tStart\tEnd" > "${seq}.deletion_summary.txt"
fi

if [ ! -f "${seq}.duplication_summary.txt" ]; then
    echo "Warning: ${seq}.duplication_summary.txt not found, creating empty file with header"
    echo -e "Chromosome\tStart\tEnd" > "${seq}.duplication_summary.txt"
fi

# Only process Function_lost_list if it has content
if [ -s "${seq}.Function_lost_list.txt" ]; then
    while read f; do 
        grep -vw "$f" ${seq}.Function_lost_list.txt > ${seq}.Function_lost_list.txt.tmp
        mv ${seq}.Function_lost_list.txt.tmp ${seq}.Function_lost_list.txt
    done < Variant_ignore.txt
fi

declare -A SQL_loss_report=()
STATEMENT_GENE_LOSS_COV () {
COUNTER=1
while read line; do 
chromosome=$(echo "$line" | awk '{print $1}')
q_start=$(echo "$line" | awk '{print $2}')
q_end=$(echo "$line" | awk '{print $3 }')
SQL_loss_report[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
	Coverage.Threshold,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Chromosome = '$chromosome'
    AND Coverage.Start_coords < '$q_end'
    AND Coverage.End_coords > '$q_start'
    AND Coverage.Upregulation_or_loss LIKE 'Loss';
EOF
)

COUNTER=$((COUNTER+1))
done < <(tail -n +2 ${seq}.deletion_summary.txt)
LOSS_COUNT="$COUNTER"
}


declare -A SQL_upregulation_report=()
STATEMENT_UPREGULATION () {
COUNTER=1
while read line; do
  chromosome=$(echo "$line" | awk '{print $1}')
  q_start=$(echo "$line" | awk '{print $2}')
  q_end=$(echo "$line" | awk '{print $3 }')
SQL_upregulation_report[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
	Coverage.Threshold,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Chromosome = '$chromosome'
    AND Coverage.Start_coords > '$q_start'
    AND Coverage.End_coords < '$q_end'
    AND Coverage.Upregulation_or_loss LIKE 'Upregulation';
EOF
)

COUNTER=$((COUNTER+1))
done < <(tail -n +2 ${seq}.duplication_summary.txt)
UPREG_COUNT="$COUNTER"
}

declare -A SQL_loss_func=()
STATEMENT_GENE_LOSS_FUNC () {
COUNTER=1
while read line; do 
gene=$(echo "$line" | awk '{print $1}')
#variant=$(echo $line | awk '{print $2 }')
SQL_loss_func[$COUNTER]=$(
cat << EOF
SELECT
    Coverage.Gene,
    Coverage.Locus_tag,
    Coverage.Upregulation_or_loss,
    Coverage.Antibiotic_affected,
	Coverage.Threshold,
	Coverage.Comments
FROM
    Coverage
WHERE
    Coverage.Gene = '$gene'
	AND Coverage.Upregulation_or_loss LIKE 'loss';
EOF
)

COUNTER=$((COUNTER+1))
done < ${seq}.Function_lost_list.txt
LOSS_FUNC_COUNT="$COUNTER"
}

echo "Creating function lost statements"
STATEMENT_GENE_LOSS_FUNC 
echo -e "Creating loss statements\n"
STATEMENT_GENE_LOSS_COV
echo -e "Creating upregulation statements\n"
STATEMENT_UPREGULATION

echo "Running duplication detection queries"
for (( i=1; i<"$UPREG_COUNT"; i++ )); do sqlite3 "$RESISTANCE_DB" "${SQL_upregulation_report[$i]}" >> ${seq}.AbR_output_del_dup.txt; done
echo "done"
echo "Running loss of coverage queries"
for (( i=1; i<"$LOSS_COUNT"; i++ )); do sqlite3 "$RESISTANCE_DB" "${SQL_loss_report[$i]}" >> ${seq}.AbR_output_del_dup.txt; done
echo "done"
echo "Running detection of functional loss queries"
for (( i=1; i<"$LOSS_FUNC_COUNT"; i++ )); do sqlite3 "$RESISTANCE_DB" "${SQL_loss_func[$i]}" >> ${seq}.AbR_output_del_dup.txt; done
echo "done"

# Create the expected output file
if [ -f "${seq}.AbR_output_del_dup.txt" ]; then
    cp "${seq}.AbR_output_del_dup.txt" "${id}_del_dup_results.txt"
else
    # Create empty output file if no results
    echo "ARDaP found no deletions or duplications that cause antibiotic resistance" > "${id}_del_dup_results.txt"
fi

# Verify the expected output file was created
if [ ! -f "${id}_del_dup_results.txt" ]; then
    echo "ERROR: Expected output file ${id}_del_dup_results.txt was not created"
    exit 1
fi

exit 0

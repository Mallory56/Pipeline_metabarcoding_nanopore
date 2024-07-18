#!/bin/bash
# Source the file with the function to apply ( the pipeline 
source pipeline_nanopore.sh

# source the congig file 
source configuration.sh
echo "   "
echo "============================================================"
echo "======================== PIPELINE ========================= "
echo "==========================================================="
echo "   "
#source des conda 
source $(conda info --base)/etc/profile.d/conda.sh


echo "data dir : $data_dir"

if [ -d "$data_dir" ]; then # check if the assigned directory does exist 
    for barcode_dir in "$data_dir"/*; do # brows all element in the data_directory
        if [ -d "$barcode_dir" ]; then # check if the element is a directory
            dir_name=$(basename "$barcode_dir") # take the name of the directory ( the barcode ) and put it in a variable
            barcode_results="$results/$dir_name/" # create a path variable using the previous variable 
            mkdir -p "$barcode_results" # create the directory with the variable 

           
            process_data "$dir_name" "$barcode_dir" "$barcode_results" # use the function process_data from the source pipeline_report to apply the pipeline
        else
            echo "error: $barcode_dir isn't a directory"
        fi
    done
else
    echo "error: $data_dir doesn't exist."
fi

conda activate pipPy37

emu combine-outputs $class_dir tax_id --split-tables --counts
 ### Creation du rapport MultiQC ###

taxonomy=$(ls "$class_dir"/emu-combined-taxonomy* 2>/dev/null | head -n 1)
echo "taxonomy : $taxonomy"

# Trouver le fichier qui commence par "emu-combined-abundance"
abundance=$(ls "$class_dir"/emu-combined-abundance* 2>/dev/null | head -n 1)
echo "abundance : $abundance"

echo "mapfile : $mapfile"
# Vérification des variables avant de lancer le script R
if [[ -z "$taxonomy" || -z "$abundance" || ! -f "$mapfile" ]]; then
    echo "Error: One or more required files are missing."
    exit 1
fi

Rscript create_phyloseq.R "$taxonomy" "$abundance" "$mapfile" "$results"
conda activate pipPy38

# Generate MultiQC report
path_report="$results/report/"
multiqc_report "$path_report"





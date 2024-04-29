#!/bin/bash
# Source the file with the function to apply ( the pipeline 
source pipeline_avec_report.sh

# source the congig file 
source parametres_test.sh

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

 ### Creation du rapport MultiQC ###
eval "$(conda shell.bash hook)"
conda activate py38
cd "$results"/report/
multiqc .

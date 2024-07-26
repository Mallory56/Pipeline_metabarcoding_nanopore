#!/bin/bash

# Source the file with the function to apply ( the pipeline)
source pipeline_nanopore.sh

# Affichage de la liste finale
echo "Votre liste : ${user_list[@]}"

# Source the configuration file
source configuration_benchmark.sh
echo "   "
echo "============================================================"
echo "======================== PIPELINE ========================="
echo "==========================================================="
echo "   "
# Source des conda
source $(conda info --base)/etc/profile.d/conda.sh

# Variable data_dir et results (assurez-vous de les définir avant)
echo "data dir : $data_dir"

if [ -d "$data_dir" ]; then
    for qscore in "${qualite[@]}"; do
        echo "Processing for Qscore: $qscore"
        if [ -d "$data_dir" ]; then
            dir_name="benchmark_q${qscore}"
            qscore_results="$results/$qscore"
            echo "qscore_dir:, $qscore_results"
            mkdir -p "$qscore_results"
            qualite=$qscore
            process_data "$qscore" "$data_dir" "$qscore_results"
        else
            echo "error: $data_dir isn't a directory"
        fi
    done
else
    echo "error: $data_dir doesn't exist."
fi

conda activate py37

emu combine-outputs "$class_dir" species --split-tables

# Création du rapport MultiQC
conda activate py38
path_report="$results/report/"
multiqc_report "$path_report"

conda deactivate
 

# Trouver le fichier result_path
result_path=$(find "$class_dir" -name "emu-combined-abundance-species.tsv")

# Assurez-vous que result_path contient un seul fichier
if [ -z "$result_path" ]; then
    echo "Le fichier emu-combined-abundance-species.tsv n'a pas été trouvé."
    exit 1
fi

# Appeler le script Python avec les chemins corrects
cd /home/mlecorre/pipeline/scripts/
python benchmark_analyse.py "$result_path" "$mc"





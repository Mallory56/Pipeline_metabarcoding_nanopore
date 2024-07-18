#!/bin/bash

source configuration.sh

#add in the variable the path for the mock_community result you want to study
resultat="/home/mlecorre/Bureau/Tunisie_Illumina/outputs/dada2/merged/MOCK/emu-combined-genus.tsv"

analyse_resultats="/home/mlecorre/Bureau/Tunisie_Illumina/outputs/dada2/merged/MOCK_genre"

mkdir -p "$analyse_resultats"

liste_parametres=("qualite " "33" "min_length " "$min_length" "max_length  " "$max_length" "headcrop : " "$headcrop" "tailcrop: " "$tailcrop" "N  " "$N" "K  " "$K")

python analyse_result.py "$result_dir" "$mc" "$resultat" "$analyse_resultats" "${liste_parametres[@]}" 

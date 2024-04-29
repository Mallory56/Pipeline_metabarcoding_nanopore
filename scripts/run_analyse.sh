#!/bin/bash

source parametres_test.sh



#add in the variable the path for the mock_community result you want to study
resultat="/home/mlecorre/metabarcoding_pacbio/results/classification/Mocklog_unismrt2sanschimere_rel-abundance.tsv"

analyse_resultats="$results/Analyse_mock_community"

mkdir -p "$analyse_resultats"

liste_parametres=("qualite " "$qualite" "min_length " "$min_length" "max_length  " "$max_length" "headcrop : " "$headcrop" "tailcrop: " "$tailcrop" "N  " "$N" "K  " "$K")

python analyse_result.py "$result_dir" "$mc" "$resultat" "$analyse_resultats" "${liste_parametres[@]}" 

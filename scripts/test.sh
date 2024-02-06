#!/bin/bash

source "parametres.sh"



#mettre les résultats de classification que vous voulez étudier
resultat="/home/mlecorre/metabarcoding_nanopore/results/barcode23_test1/classification_barcode23/barcode23_vsearch_rel-abundance-threshold-0.0001.tsv"

analyse_resultats="$result_dir/Analyse_resultat"

mkdir -p "$analyse_resultats"

liste_parametres=("qualite " "$qualite" "min_length " "$min_length" "max_length  " "$max_length" "headcrop : " "$headcrop" "tailcrop: " "$tailcrop" "N  " "$N" "K  " "$K")

python analyse_result.py "$result_dir" "$mc" "$resultat" "$analyse_resultats" "${liste_parametres[@]}" 

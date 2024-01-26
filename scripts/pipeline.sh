#!/bin/bash
start_time=$(date +%H:%M:%S)
##################################
#import des parametres depuis le fichier parametre
source parametres.sh
###################################
#gestion des sorties

if [ ! -d "$result_dir" ]; then mkdir -p "$result_dir"; fi

cp parametres.sh "$result_dir"

#nanoplot
nanoplot_avant="$result_dir/nanoplot_avant_traitement/"

nanoplot_apres="$result_dir/nanoplot_apres_traitement/"

#creation des repertoire
if [ ! -d "$nanoplot_avant" ]; then mkdir -p "$nanoplot_avant"; fi
if [ ! -d "$nanoplot_apres" ]; then mkdir -p "$nanoplot_apres"; fi

# Nanopore produit plusieurs fichiers de séquences, ligne de commande pour les réunir en un seul fichier
result_combine="$result_dir/${barcode}_combine.fastq.gz"

#porechop
fastq_trimmed="$result_dir/${barcode}_trimmed.fastq"

#Nanofilt
filtered_fastq="$result_dir/${barcode}_filtered.fastq"

#Vsearch
sans_chimere="$result_dir/${barcode}_vsearch.fastq"

#Emu
class_dir="$result_dir/classification_${barcode}"

#vsearch 
sanschimere="$result_dir/${barcode}sanschimere.fasta"



##########################################
############# Pre traitement #############
##########################################

##### Regroupement des fichiers #####
cat "$barcode_dir"/*.fastq.gz > "$result_combine"


##### Nanoplot avant le traitement #####
NanoPlot -t 2 --fastq "$result_combine" --outdir "$nanoplot_avant" --prefix "${barcode}_nanoplot_before"


##### Porechop, suppression des adaptateurs ####
porechop -i "$result_combine" -o "$fastq_trimmed"

if [ $? -ne 0 ]; then echo "Erreur execution porechop, code : $?"; else echo "porechop correctement effectué"; fi



##### NanoFilt, filtrage qualite #####

NanoFilt -q "$qualite" --length "$min_length" --maxlength "$max_length" --headcrop 10 --tailcrop 5 < "$fastq_trimmed" > "$filtered_fastq"

# Message d'erreur
if [ $? -ne 0 ]; then echo "Erreur NanoFilt, code : $?"; else echo " NanoFilt correctement effectué";fi



#####VSEARCH, suppression des chimeres #####

vsearch --uchime_denovo "$filtered_fastq" --nonchimeras "$sans_chimere"

if [ $? -ne 0 ]; then echo "Erreur VSEARCH, code : $?"; else echo " vsearch correctement effectué";fi


##### Nanoplot après le traitement #####
NanoPlot -t 2 --fastq "$filtered_fastq" --outdir "$nanoplot_apres" --prefix "${barcode}_nanoplot_after"



##########################################
############# Classification #############
##########################################

emu abundance "$sans_chimere" --db "$bdd" --output-dir "$class_dir"

end_time=$(date +%H:%M:%S)

echo "$end_time"

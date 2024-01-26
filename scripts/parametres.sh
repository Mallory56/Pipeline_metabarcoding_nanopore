#!/bin/bash

#chemin d'acces au repertoire
barcode_dir="/home/mlecorre/metabarcoding_nanopore/data/fastq_frina/barcode23"

#chemin d'acces au summary
summary_dir="/home/mlecorre/metabarcoding_nanopore/data sequencing_summary_FAW93216_3bdc7dd0_6a0e5917.txt"

#chemin d'acces des resultats
result_dir="/home/mlecorre/metabarcoding_nanopore/results/barcode23NanoFilt"

#nom de l'echantillon pour nommer les fichiers
barcode=barcode23


##### parametres nanofilt #####

qualite=15 #seuil de qualitee 
min_length=1480 # longueur minimum des reads a conserver
max_length=1626 # longueur maximum des reads a conserver


#### Classificationa avec Emu ####

#chemin d'accès de la base de données emu
bdd="/home/mlecorre/metabarcoding_nanopore/emu/database"


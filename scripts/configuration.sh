#!/bin/bash

#chemin d'acces au repertoire



data_dir="/home/mlecorre/projets/pipeline/data/test_tiny"



mapfile="/home/mlecorre/projets/pipeline/data/test_tiny/mapfile.csv"
#chemin d'acces des resultats
results="/home/mlecorre/projets/pipeline/results"

#chemin d'acces du excel qui contient les valeurs de la mock community
mc="/home/mlecorre/metabarcoding_nanopore/data/mock_community.csv"

class_dir="$results/classification"

primer_g="^TTACCGCGGCKGCTGGCAC"
primer_a="^GGAGTTTGATCMTGGCTCAG"

#nombre  de thread accordé au pipeline 
threads=15
##### parametres nanofilt #####

qualite=10 #seuil de qualitee 
min_length=1480 # longueur minimum des reads a conserver
max_length=1626 # longueur maximum des reads a conserver
headcrop=1
tailcrop=1

#### Classificationa avec Emu ####

#chemin d'accès la base de donnée vsearch
Vsearch_db="/home/mlecorre/projets/pipeline/base_donnée/vsearch"

#chemin d'accès de la base de données emu
Emu_db="/home/mlecorre/projets/pipeline/base_donnée/emu/database"

# Nombre maximum d'alignement utilisé pour chaque read dans minimap2
N=60

#taille du batch d'entrainement utilisé par minimap2
K=600000000

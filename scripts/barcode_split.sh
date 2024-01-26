#!/bin/bash



summary_directory="/home/mlecorre/metabarcoding_nanopore/data/sequencing_summary_FAW93216_3bdc7dd0_6a0e5917.txt"
results_directory="/home/mlecorre/metabarcoding_nanopore/results/summary_barcode_split/"

Barcode_split -f "$summary_directory" -o "$results_directory"


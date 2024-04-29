#!/bin/bash

process_data() {
    barcode="$1"
    barcode_dir="$2"
    result_dir="$3"

    start_time=$(date +%H:%M:%S)

    ##################################
    # Import des paramètres depuis le fichier parametre
    source parametres_test.sh
    ###################################
    # Gestion des sorties
    echo "Les résultats sont enregistrés dans : $result_dir"
    if [ ! -d "$result_dir" ]; then mkdir -p "$result_dir"; fi



    # Création des répertoires
    if [ ! -d "$report_dir" ]; then mkdir -p "$report_dir"; fi

    # Création d'un fichier pour enregistrer les sorties
    sorties="$result_dir/sorties.txt"

    # Rediriger la sortie standard et la sortie d'erreur standard vers le fichier
    if [ ! -e "$sorties" ]; then touch "$sorties"; fi

    # Nanopore produit plusieurs fichiers de séquences, ligne de commande pour les réunir en un seul fichier
    result_combine="$result_dir/${barcode}_combine.fastq"

    # Porechop
    fastq_trimmed="$result_dir/${barcode}_trimmed.fastq"

    # chopper
    filtered_fastq="$result_dir/${barcode}_filtered.fastq"

    # Vsearch
    sans_chimere="$result_dir/${barcode}_vsearch.fasta"

    # Emu
    class_dir="$result_dir/classification_${barcode}"

    # Vsearch
    filtered_fasta="$result_dir/${barcode}.fasta"
    sanschimere="$result_dir/${barcode}sanschimere.fasta"
    
    # NanoStat
    report_dir="$results/report/${barcode}"
    
    
    start_time=$(date +%H:%M:%S)
    echo "$start_time"

    ##########################################
    ############# Pre traitement #############
    ##########################################

    eval "$(conda shell.bash hook)"
    conda activate py37

    ##### Regroupement des fichiers #####

    #check if the file extension and add it to the variable
    gunzip "$barcode_dir"/*.fastq.gz > "${result_combine}"

    cat "$barcode_dir"/*.fastq > "${result_combine}"
    

    ##### Porechop, suppression des adaptateurs ####
    porechop -i "$result_combine" -o "$fastq_trimmed" --threads "$threads"

    if [ $? -ne 0 ]; then
        echo "Erreur execution porechop, code : $?"
    else
        echo "Porechop correctement effectué"
    fi

    ##### Chopper, filtrage qualité #####

    chopper -q "$qualite" --minlength "$min_length" --maxlength "$max_length" --headcrop "$headcrop" --tailcrop "$tailcrop" < "$fastq_trimmed" > "$filtered_fastq" --threads "$threads"

    # Message d'erreur
    if [ $? -ne 0 ]; then
        echo "Erreur chopper, code : $?"
    else
        echo "chopper correctement effectué"
    fi

    ##### VSEARCH, suppression des chimères #####

    seqtk seq -a "$filtered_fastq" > "$filtered_fasta"

    vsearch --uchime_ref "$filtered_fasta" --db "$Vsearch_db" --nonchimeras "$sans_chimere"

    if [ $? -ne 0 ]; then
        echo "Erreur VSEARCH, code : $?"
    else
        echo "VSEARCH correctement effectué"
    fi

 
    ##########################################
    ############# MultiQC report #############
    ##########################################
    eval "$(conda shell.bash hook)"
    conda activate py38

    ### Creation des rapports Nanostats ###
    # NanoStat --summary "$summary_dir" --outdir "$report_dir" -n "${barcode}_nanostat_summary"

    # Nanoplot avant le traitement
    NanoStat -t "$threads" --fastq "$result_combine" --outdir "$report_dir" -n "${barcode}_nanostat"

    # Nanoplot sur les fastq après la suppression des adaptateurs
    NanoStat -t "$threads" --fastq "$fastq_trimmed" --outdir "$report_dir" -n "${barcode}_trimmed_nanostat"

    # Nanoplot après le traitement
    NanoStat -t "$threads" --fastq "$filtered_fastq" --outdir "$report_dir" -n "${barcode}filterd_nanostat"
    
    # NanoStat after chimeras detection
    NanoStat -t "$threads" --fasta "$sans_chimere" --outdir "$report_dir" -n "${barcode}_nonchimeras_nanostat"

    ### Creation des rapports FastQC ###
    fastqc "$result_combine" --outdir "$report_dir" -t "$threads" "${barcode}_fastqc"

    fastqc "$fastq_trimmed" --outdir "$report_dir" -t "$threads" "${barcode}_trimmed_fastqc"
    
    fastqc "$fastq_filtered" --outdir "$report_dir" -t "$threads" "${barcode}_filtered_fastqc"

    


    ##########################################
    ############# Classification #############
    ##########################################


    eval "$(conda shell.bash hook)"
    conda activate py37
    
    emu abundance "$sans_chimere" --db "$Emu_db" --N "$N" --K "$K" --output-dir "$class_dir" --threads "$threads"

    end_time=$(date +%H:%M:%S)

    echo "$end_time"
    }
    
##########################################
############# Classification #############
##########################################   
    
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
    


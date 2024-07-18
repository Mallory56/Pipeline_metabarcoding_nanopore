#!/bin/bash

process_data() {
    barcode="$1"
    barcode_dir="$2"
    result_dir="$3"
    start_time=$(date +%H:%M:%S)

    # Import des paramètres depuis le fichier parametre
    source configuration.sh
    echo "   "
    echo "====================== - $barcode - ====================== "
    echo "   "
    echo "exécution du pipeline sur $barcode_dir"
    echo "nom de l'échantillon : $barcode"
    # Gestion des sorties
    echo "Les résultats sont enregistrés dans : $result_dir"
    if [ ! -d "$result_dir" ]; then mkdir -p "$result_dir"; fi

    # Création d'un fichier pour enregistrer les sorties
    sorties="$result_dir/sorties.txt"

    # Nanopore produit plusieurs fichiers de séquences, ligne de commande pour les réunir en un seul fichier
    result_combine="$result_dir/${barcode}_combine.fastq"

    fastq_primers="$result_dir/${barcode}_primers.fastq"
    
    # Porechop
    fastq_trimmed="$result_dir/${barcode}_trimmed.fastq"

    # Chopper
    filtered_fastq="$result_dir/${barcode}_filtered.fastq"

    # Vsearch
    sans_chimere="$result_dir/${barcode}_vsearch.fasta"
    
    classifications="$results/classification"
    class_dir="$classifications"

    # Vsearch
    filtered_fasta="$result_dir/${barcode}.fasta"

    # NanoStat
    report_dir="$results/report/${barcode}"
    
    start_time=$(date +%H:%M:%S)
    echo "$start_time"

    ##########################################
    ############# Pre traitement #############
    ##########################################

    # Active l'environnement Conda pour Python 3.7
    source $(conda info --base)/etc/profile.d/conda.sh
    conda activate pipPy38

    ##### Regroupement des fichiers #####

    gunzip "$barcode_dir"/*.fastq.gz > "${result_combine}" 2>>"$sorties"

    cat "$barcode_dir"/*.fastq > "${result_combine}" 2>>"$sorties"
    
    
    cutadapt -g "$primer_a" -g "$primer_g" -o "$fastq_primers" "$result_combine" 2>> "$sorties"
    
    if [ $? -ne 0 ]; then
        echo "Erreur execution cutadapt, code : $?"
       exit 1
    else
        echo "cutadapt correctement effectué"
    fi

    ##### Porechop, suppression des adaptateurs ####
    porechop -i "$fastq_primers" -o "$fastq_trimmed" --threads "$threads" >>"$sorties" 2>&1

    if [ $? -ne 0 ]; then
        echo "Erreur execution porechop, code : $?" 
    else
        echo "Porechop correctement effectué" 
    fi

    ##### Chopper, filtrage qualité #####

    chopper -q "$qualite" --minlength "$min_length" --maxlength "$max_length" --headcrop "$headcrop" --tailcrop "$tailcrop" < "$fastq_trimmed" > "$filtered_fastq" --threads "$threads"

    if [ $? -ne 0 ]; then
        echo "Erreur chopper, code : $?" 
    else
        echo "chopper correctement effectué" 
    fi

    ##### VSEARCH, suppression des chimères #####

    seqtk seq -a "$filtered_fastq" > "$filtered_fasta" 2>>"$sorties"

    vsearch --uchime_ref "$filtered_fasta" --db "$Vsearch_db" --nonchimeras "$sans_chimere" >>"$sorties" 2>&1

    if [ $? -ne 0 ]; then
        echo "Erreur VSEARCH, code : $?" 
    else
        echo "VSEARCH correctement effectué" 
    fi

    ##########################################
    ############# MultiQC report #############
    ##########################################

    ### Création des rapports NanoStat ###
    NanoStat -t "$threads" --fastq "$result_combine" --outdir "$report_dir" -n "${barcode}_nanostat" >>"$sorties" 2>&1
    NanoStat -t "$threads" --fastq "$fastq_trimmed" --outdir "$report_dir" -n "${barcode}_trimmed_nanostat" >>"$sorties" 2>&1
    NanoStat -t "$threads" --fastq "$filtered_fastq" --outdir "$report_dir" -n "${barcode}_filtered_nanostat" >>"$sorties" 2>&1
    NanoStat -t "$threads" --fasta "$sans_chimere" --outdir "$report_dir" -n "${barcode}_nonchimeras_nanostat" >>"$sorties" 2>&1

    ### Création des rapports FastQC ###
    fastqc "$result_combine" --outdir "$report_dir" -t "$threads" >>"$sorties" 2>&1
    fastqc "$fastq_trimmed" --outdir "$report_dir" -t "$threads" >>"$sorties" 2>&1
    fastqc "$filtered_fastq" --outdir "$report_dir" -t "$threads" >>"$sorties" 2>&1

    # Désactive l'environnement Conda Python 3.8
    conda deactivate

    ##########################################
    ############# Classification #############
    ##########################################

    # Active l'environnement Conda pour Python 3.7
    conda activate pipPy37
    
    emu abundance "$sans_chimere" --db "$Emu_db" --N "$N" --K "$K" --output-dir "$class_dir" --output-basename "$barcode" --keep-counts --keep-read-assignments --output-unclassified --threads "$threads" >>"$sorties" 2>&1
    
    if [ $? -ne 0 ]; then
        echo "Erreur emu, code : $?" 
    else
        echo "emu correctement effectué" 
    fi

    # Désactive l'environnement Conda Python 3.7
    conda deactivate

    end_time=$(date +%H:%M:%S)
    echo "$end_time"
}

multiqc_report() {
    report_path=$1
    cd $report_path
    multiqc . >>"$sorties" 2>&1
}


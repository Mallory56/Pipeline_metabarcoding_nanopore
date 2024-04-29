#!/bin/bash

process_data() {
    sample_name="$1"
    sample="$2"
    result_dir="$3"
    primer_g="$4"
    primer_a="$5"

    start_time=$(date +%H:%M:%S)

    ##################################
    # Import des paramètres depuis le fichier parametre
    source parametres_test.sh
    ###################################
    echo "sample_name : $sample_name"
    echo "sample : $sample"
    # Gestion des sorties
    echo "Les résultats sont enregistrés dans : $result_dir"
    if [ ! -d "$result_dir" ]; then mkdir -p "$result_dir"; fi
    
    # Création d'un fichier pour enregistrer les sorties
    sorties="$result_dir/sorties.txt"

    # Rediriger la sortie standard et la sortie d'erreur standard vers le fichier
    if [ ! -e "$sorties" ]; then touch "$sorties"; fi

    # cutadapt
    fastq_trimmed="$result_dir/${sample_name}_trimmed.fastq"

    # vsearch
    filtered_fastq="$result_dir/${sample_name}_filtered.fastq"

    # Vsearch
    filtered_fasta="$result_dir/${sample_name}.fasta"
    
    sanschimere="$result_dir/${sample_name}sanschimere.fasta"
    
    # fastqc
    report_dir="$results/report/${sample_name}"
    
    # Création des répertoires
    if [ ! -d "$report_dir" ]; then mkdir -p "$report_dir"; fi
    
    start_time=$(date +%H:%M:%S)
    echo "$start_time"

    ##########################################
    ############# Pre traitement #############
    ##########################################
    
    eval "$(conda shell.bash hook)"
    conda activate py37

    ##### cutadapt, suppression des adaptateurs ####
    cutadapt -a "$primer_a" -g "$primer_g" -o "$fastq_trimmed" "$sample"


    if [ $? -ne 0 ]; then
        echo "Erreur execution cutadapt, code : $?"
    else
        echo "cutadapt correctement effectué"
    fi

    ##### vsearch, filtrage qualité #####
    
    echo "filtered fastq "$filtered_fastq""
    vsearch --fastq_filter "$fastq_trimmed" --fastq_maxee "$qualite" --fastq_maxlen "$max_length" --fastq_minlen "$min_length" --fastq_qmax 93  --fastqout "$filtered_fastq"

    # Message d'erreur
    if [ $? -ne 0 ]; then
        echo "Erreur chopper, code : $?"
    else
        echo "vsearch correctement effectué"
    fi

    ##### VSEARCH, suppression des chimères #####

    seqtk seq -a "$filtered_fastq" > "$filtered_fasta"
    echo "filtered_fasta : $filtered_fasta"
    
    echo "sanschimere: $sanschimere"
    
    vsearch --uchime_ref "$filtered_fasta" --db "$Vsearch_db" --nonchimeras "$sanschimere"

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

    ### Creation des rapports FastQC ###
    fastqc "$sample" --outdir "$report_dir" -t "$threads" "${barcode}_fastqc"

    fastqc "$fastq_trimmed" --outdir "$report_dir" -t "$threads" "${barcode}_trimmed_fastqc"
    
    fastqc "$filtered_fastq" --outdir "$report_dir" -t "$threads" "${barcode}_filtered_fastqc"

    ### NanoStat ###
    # Nanoplot avant le traitement
    NanoStat -t "$threads" --fastq "$sample" --outdir "$report_dir" -n "${barcode}_nanostat"

    # Nanoplot sur les fastq après la suppression des adaptateurs
    NanoStat -t "$threads" --fastq "$fastq_trimmed" --outdir "$report_dir" -n "${barcode}_trimmed_nanostat"

    # Nanoplot après le traitement
    NanoStat -t "$threads" --fastq "$fastq_filtered" --outdir "$report_dir" -n "${barcode}filterd_nanostat"
    
    # NanoStat after chimeras detection
    NanoStat -t "$threads" --fasta "$sanschimere --outdir "$report_dir" -n "${barcode}_nonchimeras_nanostat


    ##########################################
    ############# Classification #############
    ##########################################


    eval "$(conda shell.bash hook)"
    conda activate py37
    
    emu abundance "$sanschimere" --type map-pb --db "$Emu_db" --N "$N" --K "$K" --output-dir "$class_dir" --keep-files --keep-counts --keep-read-assignments --threads "$threads"

    end_time=$(date +%H:%M:%S)

    echo "$end_time"
}

source pipeline_avec_report.sh

# Inclure le fichier de configuration
source parametres_test.sh

# Vérifier si le répertoire de données existe
if [ -d "$data_dir" ]; then
    # Parcourir tous les éléments dans le répertoire de données
    for file in "$data_dir"/*.fastq.gz; do
        # Vérifier si l'élément est un fichier FASTQ
        if [[ -f "$file" ]]; then
            # Prendre le nom du fichier (le code-barres) et le mettre dans une variable
            file_name=$(basename "$file" .hifi_reads.fastq.gz)
            # Créer un chemin d'accès pour les résultats de l'échantillon
            sample_results="$results/${file_name}"
            # Créer le répertoire pour les résultats de l'échantillon
            mkdir -p "$sample_results"
            # Appliquer le pipeline sur les données de l'échantillon
            process_data "${file_name}" "$file" "$sample_results" "$primer_g" "$primer_a"
        else
            echo "Erreur: $file n'est pas un fichier FASTQ valide"
        fi
    done
else
    echo "Erreur: $data_dir n'existe pas."
fi

# Création du rapport MultiQC
eval "$(conda shell.bash hook)"
conda activate py38
cd "$results/report/"
multiqc .

eval "$(conda shell.bash hook)"
conda activate py37

emu combine-outputs $class_dir "tax_id"

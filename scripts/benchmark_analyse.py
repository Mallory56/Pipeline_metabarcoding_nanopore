import pandas as pd
import numpy as np
import sys

result_path = sys.argv[1]
mc_path = sys.argv[2] 

#result_path = "/home/mlecorre/pipeline/results/benchmark_tiny/classification/emu-combined-abundance-species.tsv"
#mc_path = "/home/mlecorre/metabarcoding_nanopore/data/mock_community.csv" 

results = pd.read_csv(result_path, sep='\t')
mc = pd.read_csv(mc_path, sep='\t')


# Normalisation des noms d'espèces
results['species'] = results['species'].str.lower()
mc['species'] = mc['species'].str.lower()

# Fusion des DataFrames
combined_df = pd.merge(mc, results, on='species', how='outer')

# Conversion correcte des valeurs de 'composition'
combined_df['composition'] = combined_df['composition'].replace({',': '.'}, regex=True).astype(float)

# Remplacement des valeurs manquantes par 0
combined_df = combined_df.fillna(0)

# Conversion des noms d'espèces en chaînes de caractères sans espaces
combined_df['species'] = combined_df['species'].astype(str).str.strip()
print(combined_df)
# Définir les espèces comme index
combined_df.set_index('species', inplace=True)

# Liste des colonnes de scores
col_qscore = combined_df.columns[1:]  # Exclude 'composition'
def fdr(FP, TP):
    return FP / (FP + TP) if (FP + TP) != 0 else np.nan

# Fonction pour calculer l'indice de Bray-Curtis
def bray_curtis(diff_abs, total_sum):
    numerator = np.sum(diff_abs)
    denominator = np.sum(total_sum)
    return (numerator / denominator) if denominator != 0 else np.nan

# Fonction pour calculer la MAE
def mean_absolute_error(diff_abs):
    return np.mean(diff_abs) if len(diff_abs) > 0 else np.nan

# Calcul du FDR, de l'indice de Bray-Curtis et de la MAE pour chaque colonne de score
results_summary = {'column': [], 'fdr': [], 'bray_curtis': [], 'mae': []}

for col in col_qscore:
    # Initialisation des compteurs pour chaque colonne
    tp = 0
    fp = 0
    differences_abs = []
    total_sums = []
    
    # Calcul des TP et FP, des différences absolues et des sommes totales pour chaque colonne
    for sp in combined_df.index:
        
        composition = combined_df.loc[sp, 'composition']
        score = combined_df.loc[sp, col]
        
        if composition > 0 and score > 0:
            tp += 1
        elif composition == 0 and score > 0:
            fp += 1
        
        # Calcul des différences absolues et des sommes totales
        diff_abs = np.abs(composition - score)
        total_sum = composition + score
        
        differences_abs.append(diff_abs)
        total_sums.append(total_sum)
    # Calculer le FDR pour la colonne
    fdr_value = fdr(fp, tp)
    
    # Calculer l'indice de Bray-Curtis avec les différences absolues et les sommes totales
    avg_bray_curtis = bray_curtis(np.array(differences_abs), np.array(total_sums))
    
    # Calculer la moyenne des erreurs absolues pour la colonne
    avg_mae = mean_absolute_error(differences_abs)
    
    # Stocker les résultats
    results_summary['column'].append(col)
    results_summary['fdr'].append(fdr_value)
    results_summary['bray_curtis'].append(avg_bray_curtis)
    results_summary['mae'].append(avg_mae)

# Convertir les résultats en DataFrame pour une présentation facile
results_df = pd.DataFrame(results_summary)

# Afficher les résultats
print(results_df)
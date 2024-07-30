import pandas as pd
import numpy as np
import sys

# Paths to the files
result_path = sys.argv[1]
mc_path = sys.argv[2]
results_dir = sys.argv[3]


# download the data in a dataframe
results = pd.read_csv(result_path, sep='\t')
mc = pd.read_csv(mc_path, sep='\t')

# supp capital letter
results['species'] = results['species'].str.lower()
mc['species'] = mc['species'].str.lower()

# Merge the DataFrames
combined_df = pd.merge(mc, results, on='species', how='outer')

# Convert the values in compositions in float
combined_df['composition'] = combined_df['composition'].replace({',': '.'}, regex=True).astype(float)

# Replace missing values with 0
combined_df = combined_df.fillna(0)

# Convert names in str
combined_df['species'] = combined_df['species'].astype(str).str.strip()

print("Combined DataFrame:")
print(combined_df)

# Set species as index
combined_df.set_index('species', inplace=True)

# Put the score column in a list
col_qscore = combined_df.columns[1:]

# Multiply abundance values given by emu by 100
for col in col_qscore:
    combined_df[col] = combined_df[col] * 100

# initialisation of a dictionnary containing the metrics ( to facilitate the creation of the dataframe later )
results_summary = {'column': [], 'bray_curtis': [], 'mae': [], 'fdr': []}

print(combined_df)

# Calculate Bray-Curtis, MAE, and FDR
for col in col_qscore:
  
    att_esp = combined_df[combined_df['composition'] > 0]
    total_esp = combined_df[combined_df[col] > 0]

    numerator = 0
    denominator = 0
    mae = 0
    false_positive = 0
    total_positive = total_esp.shape[0]

    for sp in att_esp.index:
        x_i = combined_df.loc[sp, 'composition']
        y_i = combined_df.loc[sp, col]
        
        numerator += min(x_i, y_i) * 2
        denominator += x_i + y_i
        mae += abs(x_i - y_i)

    # False Discovery Rate (FDR)
    false_positive = total_positive - att_esp.shape[0]
    if total_positive > 0:
        fdr = false_positive / total_positive
    else:
        fdr = np.nan

    # Mean Absolute Error (MAE)
    mae /= att_esp.shape[0]

    if denominator > 0:
        bray_curtis = numerator / denominator
    else:
        bray_curtis = np.nan 

    results_summary['column'].append(col)
    results_summary['bray_curtis'].append(bray_curtis)
    results_summary['mae'].append(mae)
    results_summary['fdr'].append(fdr)
    
    print(f"Column: {col}, Bray-Curtis: {bray_curtis}, MAE: {mae}, FDR: {fdr}")



results_df = pd.DataFrame(results_summary)

# Save to Excel files
combined_df.to_excel(results_dir + '_combined_df.xlsx', sheet_name='Combined Data')
results_df.to_excel(results_dir + '_results_summary.xlsx', sheet_name='Results Summary')

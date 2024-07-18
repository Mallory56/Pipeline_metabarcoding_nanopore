import pandas as pd
import sys
from IPython.core.display import HTML
import plotly.express as px
import numpy as np

# Import des variables depuis le script bash parametres.sh
result_dir = sys.argv[1]
mc_path = sys.argv[2]  # mc pour mock_community
resultat = sys.argv[3]  # On récupère le répertoire avec les classifications
resultat_dir = sys.argv[4]
liste_parametres = sys.argv[5:]

################################
#### CREATION DES DATAFRAME ####
################################

#### TRAITEMENT DU TABLEAU DE LA MOCK COMMUNITY ####

# Séparateur tabulation
mc = pd.read_csv(mc_path, sep='\t')

# Remplacer les , par des .
mc['composition'] = mc['composition'].replace({',': '.'}, regex=True) # remplace les virgule en point 
mc['composition'] = pd.to_numeric(mc['composition'], downcast="float") # met la colonne composition sous forme de float
mc['species'] = mc['species'].str.lower()

##### CREATION RESULTATS OBTENUS APRES LE PIPELINE #####
result_df = pd.read_csv(resultat, sep="\t")
result_df['species'] = result_df['species'].fillna("unassigned")

result_df['abundance'] = result_df['abundance'].replace({',': '.'}, regex=True) # remplace les virgule en point 
result_df['abundance'] = pd.to_numeric(result_df['abundance'], downcast="float")

comp_result = pd.DataFrame({'species': result_df['species'].str.lower(),'composition': result_df['abundance']*100})

####### CREATION DE LA DATAFRAME COMPARAISONS #######

# Utilisation de la fonction .merge pour réunir les deux dataframe en fonction de la colonne species
merged_df = pd.merge(mc, comp_result, on='species', how='outer', suffixes=('_attendue','_observee'))
# Utilisation de la fonction .fillna pour remplacer les NaN par des 0
merged_df = merged_df.fillna(0)
# Ajout de la colonne difference en faisant la différence de composition attendue et composition observée
merged_df['difference'] = merged_df['composition_observee'] - merged_df['composition_attendue']
# Ajout de la colonne difference_abs en prenant la valeur absolue de la différence
merged_df['difference_abs'] = merged_df['difference'].abs()

# Calcul du taux d'erreur moyen en valeur absolue
diff_moyenne_comp = sum(merged_df['difference_abs']) / len(merged_df)

###### CREATION DE LA DATAFRAME ESPECES COMMUNES ######

# Même fonctionnement que pour la dataframe comparaisons
communes_df = merged_df.loc[(merged_df[['composition_attendue', 'composition_observee']] != 0).all(axis=1)]
communes_df.loc[:, 'difference'] = communes_df['composition_observee'] - communes_df['composition_attendue']
communes_df.loc[:, 'difference_abs'] = communes_df['difference'].abs()
communes_df.loc[:, 'taux_erreur'] = ((communes_df['composition_observee'] - communes_df['composition_attendue']) / communes_df['composition_attendue']) * 100
communes_df.loc[:, 'taux_erreur_abs'] = communes_df['taux_erreur'].abs()
diff_moyenne = sum(communes_df['difference_abs']) / len(communes_df)
taux_erreur_moyen_especes_communes = sum(communes_df['taux_erreur_abs']) / len(communes_df)

###### CALCUL DE L'ACCURACY INDEX ######

# Calcul de la somme des différences absolues
somme_diff_abs = merged_df['difference_abs'].sum()
# Calcul du double de la somme des abondances théoriques
double_somme_theoriques = 2 * mc['composition'].sum()
# Calcul de l'Accuracy Index global
accuracy_index = 1 - (somme_diff_abs / double_somme_theoriques)

# Calcul de l'Accuracy Index pour chaque espèce commune
communes_df['accuracy_index'] = 1 - (communes_df['difference_abs'] / (2 * communes_df['composition_attendue']))

###### CALCUL DES FAUX POSITIFS ET FAUX NEGATIFS ######

# Ajout des colonnes faux positifs et faux négatifs
merged_df['faux_positifs'] = ((merged_df['composition_observee'] > 0) & (merged_df['composition_attendue'] == 0)).astype(int)
merged_df['faux_negatifs'] = ((merged_df['composition_observee'] == 0) & (merged_df['composition_attendue'] > 0)).astype(int)

# Ajout des colonnes faux positifs et faux négatifs dans les espèces communes
communes_df['faux_positifs'] = ((communes_df['composition_observee'] > 0) & (communes_df['composition_attendue'] == 0)).astype(int)
communes_df['faux_negatifs'] = ((communes_df['composition_observee'] == 0) & (communes_df['composition_attendue'] > 0)).astype(int)

###### CREATION DE LA DATAFRAME DIFFERENCES ######

# Création d'une dataframe qui montre que les espèces ne sont pas communes aux deux dataframe
differentes_df = merged_df.loc[(merged_df[['composition_attendue', 'composition_observee']] == 0).any(axis=1) & (merged_df.index != 11)]

#############################
##### CREATION DU GRAPH #####
#############################
y = merged_df["species"].astype(str)
# Obtention des valeurs par rapport à chaque valeur de y
x = merged_df["difference"]

# Création du graphique
fig = px.bar(x=x, y=y, orientation='h', labels={'x': 'Différence', 'y': 'Espèces'}, title='Graphique barre horizontal')

fig.show()

# Conversion du graphique en HTML
html_fig = fig.to_html(full_html=True)

#####################################
###### CREATIONS FICHIERS HTML ######
#####################################

#### AJOUT DES HTML DANS LE FICHIER ####

html_mc = mc.to_html(index=False)
html_comp_result = comp_result.to_html(index=False)
html_merged_df = merged_df.to_html(index=False)
html_communes_df = communes_df.to_html(index=False)
html_differentes_df = differentes_df.to_html(index=False)
html_diff_moyenne = f"<p style='color:red; font-size:85%'>{diff_moyenne}</p>"
html_diff_moyenne_comp = f"<p style='color:red; font-size:85%'>{diff_moyenne_comp}</p>"
html_taux_erreur_moyen_especes_communes = f"<p style='color:red; font-size:85%'>{taux_erreur_moyen_especes_communes}</p>"
html_accuracy_index = f"<p style='color:blue; font-size:85%'>Accuracy Index Global: {accuracy_index:.2f}</p>"
html_liste_parametres = ""
for i in range(0, len(liste_parametres), 2):
    html_liste_parametres += f"<p style='font-size:80%'>{liste_parametres[i]}: {liste_parametres[i+1]}</p>"

# Concaténation des codes HTML
html_combined = f"""
<html>
  <head>
    <title>Résultats combinés</title>
  </head>
  <body>

    <h2>Paramètres utilisés</h2>
    <small>{html_liste_parametres}</small>

    <h2>Mock Community</h2>
    {html_mc}

    <h2>Composition après pipeline</h2>
    {html_comp_result}

    <h2>Comparaison</h2>
    {html_merged_df}
    <h2>Différences moyenne entre les espèces:</h2>
    <p>{html_diff_moyenne_comp}</p>

    <h2>Espèces communes</h2>
    {communes_df.to_html(index=False)}
    <h2>Différence moyenne pour les espèces communes:</h2>
    <p>{html_diff_moyenne}</p>
    <h2>Taux erreur moyen pour les espèces communes:</h2>
    <p>{taux_erreur_moyen_especes_communes}</p>
    <h2>Accuracy Index pour les espèces communes:</h2>
    {communes_df.to_html(index=False)}

    <h2>Différences observées</h2>
    {html_differentes_df}

    <h2>Graphique Différence entre la composition attendue et la composition observée</h2>
    {html_fig}

    <h2>Accuracy Index Global</h2>
    {html_accuracy_index}
  </body>
</html>
"""

# Enregistrement du code HTML dans un fichier
with open(f"{resultat_dir}/resultats.html", 'w') as file:
    file.write(html_combined)

#####################################
###### ENREGISTREMENT EXCEL #########
#####################################

# Créer un writer pour le fichier Excel
excel_path = f"{resultat_dir}/resultats.xlsx"
with pd.ExcelWriter(excel_path, engine='xlsxwriter') as writer:
    # Écrire chaque dataframe dans une feuille différente
    mc.to_excel(writer, sheet_name='Mock Community', index=False)
    comp_result.to_excel(writer, sheet_name='Composition Pipeline', index=False)
    merged_df.to_excel(writer, sheet_name='Comparaison', index=False)
    communes_df.to_excel(writer, sheet_name='Espèces Communes', index=False)
    differentes_df.to_excel(writer, sheet_name='Différences Observées', index=False)

print(f"Les résultats ont été enregistrés dans {resultat_dir}/resultats.html et {resultat_dir}/resultats.xlsx")


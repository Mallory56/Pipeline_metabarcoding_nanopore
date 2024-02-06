import pandas as pd
import sys
from IPython.core.display import HTML
import plotly.express as px

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

#séparateur tabulation
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

#utilisation de la fonction .merge pour reunir les deux dataframe en fonction de la colonne species
merged_df = pd.merge(mc,comp_result, on='species', how='outer', suffixes=('_attendue','_observee'))
# utilisation de la fonction .fillna pour remplacer les NaN par des 0
merged_df = merged_df.fillna(0)
# Ajout de la colonne difference en faisant la difference de composition attendue et composition observee
merged_df['difference'] = merged_df['composition_attendue'] - merged_df['composition_observee']


#calcul du taux d erreur moyen
taux_erreur_moyen_comp = sum(merged_df['difference'])/len(merged_df)


###### CREATION DE LA DATAFRAME ESPECES COMMUNES ######

# meme fonctionnement que pour la dataframe comparaisons
communes_df = merged_df.loc[(merged_df[['composition_attendue', 'composition_observee']] != 0).all(axis=1)]
communes_df.loc[:, 'difference'] = communes_df['composition_attendue'] - communes_df['composition_observee']

taux_erreur_moyen = sum(communes_df['difference'])/len(communes_df)

###### CREATION DE LA DATAFRAME DIFFERENCES ######

# creation d'une dataframe qui montre que les ne sont pas communes aux deux dataframe
differentes_df = merged_df.loc[(merged_df[['composition_attendue', 'composition_observee']] == 0).any(axis=1) & (merged_df.index != 11)]



#############################
##### CREATION DU GRAPH #####
#############################

plot_file=f"{resultat_dir}plot.html"
# Basé sur le dataframe
y = merged_df["species"].astype(str)
# Obtention des valeurs par rapport à chaque valeur de y
x = merged_df["difference"]

#creation du graphique
fig = px.bar(x=x, y=y, orientation='h', labels={'x': 'Différence', 'y': 'Espèces'}, title='Graphique barre horizontal')



#####################################
###### CREATIONS FICHIERS HTLM ######
#####################################

#### AJOUT DES PARAMETRES DANS LE FICHIERS ####

html_mc = mc.to_html(index=False)
html_comp_result = comp_result.to_html(index=False)
html_merged_df = merged_df.to_html(index=False)
html_communes_df = communes_df.to_html(index=False)
html_differentes_df = differentes_df.to_html(index=False)
html_tem = f"<p style='color:red; font-size:85%'>{taux_erreur_moyen}</p>"
html_tem_comp = f"<p style='color:red; font-size:85%'>{taux_erreur_moyen_comp}</p>"

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

    <h2> Paramètres utilisés <h2>
    <small>{html_liste_parametres}<small>

    <h2>Mock Community</h2>
    {html_mc}

    <h2>Composition après pipeline</h2>
    {html_comp_result}

    <h2>Comparaison</h2>
    {html_merged_df}
    
    <h2>Taux erreurs moyen:</h2>
    <p>{html_tem_comp}</p>

    <h2>Espèces communes</h2>
    {html_communes_df}
    <h2>Taux erreurs moyen pour les espèces communes:</h2>
    <p>{html_tem}</p>
    <h2>Différences observées</h2>
    {html_differentes_df}
    
    <h2>Graphique Différence entre la composition attendue et la composition observée </h2>
    <!-- Ajout du graphique dans le HTML -->
    <iframe src="{plot_file}" width="800" height="600"></iframe>
  </body>
</html>
"""


# Enregistrement du code HTML dans un fichier
with open(f"{resultat_dir}/resultats.html", 'w') as file:
    file.write(html_combined)
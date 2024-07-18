library(phyloseq)

args <- commandArgs(trailingOnly = TRUE)

# Récupérer les chemins daccès en arguments
emu_combine_tax <- args[1]
emu_combine_ab <- args[2]
mapfile <- args[3]
results_dir <- args[4]



# Lecture des tables
emu_combine_tax_table <- read.table(emu_combine_tax, sep = "\t", dec = ".", header = TRUE)
emu_combine_ab_table <- read.table(emu_combine_ab, sep = "\t", dec = ".", header = TRUE)
mapfile_table <- read.csv(mapfile, sep = "\t", dec = ".", header = TRUE)

# Passage des tax_id en row_names
row.names(emu_combine_tax_table) <- emu_combine_tax_table[, 1]
row.names(emu_combine_ab_table) <- emu_combine_ab_table[, 1]
row.names(mapfile_table) <- mapfile_table[, 1]

# Suppression des tax_id dans le tableau (éviter les doublons)
emu_combine_tax_table <- emu_combine_tax_table[, -1]
emu_combine_ab_table <- emu_combine_ab_table[, -1]

# suppression des NA
emu_combine_ab_table[is.na(emu_combine_ab_table)] <- 0

#arrondir les valeurs
emu_combine_ab_table <- round(emu_combine_ab_table)

# Création de l'objet physeq
taxa <- tax_table(as.matrix(emu_combine_tax_table))
ASV <- otu_table(as.matrix(emu_combine_ab_table), taxa_are_rows = TRUE)
samples <- sample_data(mapfile_table)

physeq <- phyloseq(taxa, ASV, samples)

# Affichage de l'objet physeq pour vérification
print(physeq)

# Chemin de sauvegarde de l'objet physeq
phylobject <- file.path(results_dir, "physeq.Rdata")

# Sauvegarder l'objet physeq dans un fichier .Rdata
save(physeq, file = phylobject)

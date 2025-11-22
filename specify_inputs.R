# ==============================
# INPUT file paths for
# Polyphenol Estimation Pipeline
# Built by: Stephanie Wilson
# Date: November 2025
# ==============================

# USER INPUT REQUIRED===========
# ASA24 Data, standard NCI export Items file format OR
# NHANES Dietary Data, Cleaned as Recommended in 'Obtain_NHANES_Diet_Data.Rmd'
diet_input_file = "user_inputs/VVKAJ_Items.csv"

# PROVIDED FILES================
# Unless moved, you do not have to change these

# Files for Polyphenol Estimation Pipeline
# FDA-FDD Database Version 3.1
FDD_file = "provided_files/FDA_FDD_All_Records_v_3.1.xlsx"

# FooDB polyphenols content, 3072 compounds
FooDB_mg_100g = "provided_files/FooDB_polyphenol_content_with_dbPUPsubstrates_Aug25.csv" 

# FooDB polyphenol compounds class taxonomy
class_tax = "provided_files/FooDB_polyphenol_list_3072.csv"

# FDD to FooDB Mapping file
mapping = "provided_files/FDA_FooDB_Mapping_Nov_2025.csv"

# Files for Calculation of Dietary Inflammatory Index 2014
# FooDB Eugenol Content
FooDB_eugenol = "provided_files/FooDB_Eugenol_Content_Final.csv"

# FooDB polyphenol taxonomic classes relevant to DII
FooDB_DII_subclasses = "provided_files/FooDB_DII_polyphenol_list.csv"

# Location where any R package not found would be downloaded to
Local_R_packages = "functions"

# ============================================================
# Run Polyphenol Estimator
# Built by: Stephanie Wilson
# Date: November 2025
# ============================================================

# SET WORKING DIRECTORY
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# SOURCE FUNCTIONS
# ------------------------------------------------------------
source('functions/estimate_polyphenols.R')
source('functions/calculate_DII.R')

# RUN POLYPHENOL ESTIMATOR
# ------------------------------------------------------------
# diet_input_file = 'user_inputs/UPDATE_THIS_PATH.csv'
# type, specify "ASA24" or "NHANES"
# report, specify "none", "html", or "md" for your reports
estimate_polyphenols(diet_input_file = 'user_inputs/VVKAJ_Items.csv',
                     type = "ASA24", report = "none") 

# CALCULATE DIETARY INFLAMMATORY INDEX
# ------------------------------------------------------------
# report, specify "none", "html", or "md" for your reports
calculate_DII(report = "none")

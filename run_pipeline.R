# ============================================================
# Run Polyphenol Estimator
# Built by: Stephanie Wilson
# Date: February 2026
# ============================================================

# SET WORKING DIRECTORY
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# RUN POLYPHENOL ESTIMATOR
# ------------------------------------------------------------
# diet_input_file = 'user_inputs/UPDATE_THIS_PATH.csv'
# type, specify "ASA24" or "NHANES"
# report, specify "none", "html", or "md" for your reports
source('functions/estimate_polyphenols.R') # loads function
estimate_polyphenols(diet_input_file = 'user_inputs/VVKAJ_Items.csv',
                     type = "ASA24",  report = "none") 

# CALCULATE DIETARY INFLAMMATORY INDEX
# ------------------------------------------------------------
# report, specify "none", "html", or "md" for your reports
source('functions/calculate_DII.R') # loads function
calculate_DII(report = "none")

# Calculate the 42-component DII
# Stephanie Wilson

# DII pipeline runner for beginners
calculate_DII = function(output_type = c("html", "md")) {
  output_type = match.arg(output_type)
  
  # Install and load required packages
  source("functions/startup_functions.R")     # defines install_if_missing()
  install_if_missing(c("tidyverse", "readxl", "rmarkdown"))
  
  # Load package
  library(rmarkdown)
  
  # The Polyphenol Estimation Pipeline Needs to run first.
  # Output from this pipeline kicks off the DII calculation scripts
  starting_file = "outputs/Input_Disaggregated_mapped.csv.bz2"
  
  # Check if it was by confirming Disaggregated Dietary Data File exists
  if (!file.exists(starting_file)) {
    stop("\n Please run the polyphenol estimation pipeline before running the DII calculation.")
  } else {
    message("Checkpoint - Polyphenol estimation pipeline was run.\n")
  }
  
  # List of DII scripts in order
  dii_steps = file.path("scripts", c(
  # Step 1: Calculate Intake of Eugenol
  "DII_STEP1_Eugenol.Rmd",
  # Step 2: Calculate Intake of 6 polyphenol subclasses
  "DII_STEP2_Polyphenol_Subclass.Rmd", 
  # Step 3: Calculate Intake of Foods and Food Components
  "DII_STEP3_Food.Rmd",
  # Step 4: Calculate the Dietary Inflammatory Index
  # DII by Shivappa et al 2013
  "DII_STEP4_DII_Calculation.Rmd"))
  
  # Map output_type to function
  render_fun = switch(output_type,
                       html = run_create_html_report,
                       md   = run_create_md_report)
  
  
  
  # Check if reports directory exists, and if not, Create one
  if (!dir.exists("reports")) dir.create("reports", recursive = TRUE)
  
  # Message saying which report is getting made
  message("Pipeline will now start and generate ", output_type, " reports.\n")
  
  # Record start time
  start_time = Sys.time()
  
  # Run all scripts sequentially
  for (script in dii_steps) {
    tryCatch(
      {
        render_fun(script)
        message("Completed: ", script, "\n")
      },
      error = function(e) {
        stop("Error in ", script, ": ", e$message)  # stop if any step fails
      }
    )
  }
  
  # End time and duration
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  minutes = floor(total_seconds / 60)
  seconds = round(total_seconds %% 60)
  
  
  message("42-Component DII Calculation completed successfully.")
  message("Total runtime: ", minutes, " min ", seconds, " sec")
}

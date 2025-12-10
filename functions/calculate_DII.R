# Calculate the 42-component DII
# Stephanie Wilson

# DII pipeline runner for beginners
calculate_DII = function(report = c("none", "html", "md")) {
  
  report = match.arg(report)
  
  # Install and load required packages
  source("functions/startup_functions.R")     # defines install_if_missing()
  ensure_packages(pkgs = c("dplyr", "vroom", "tidyr", "stringr", "ggplot2", "readxl", "rmarkdown"))
  
  # Load package
  suppressMessages(library(rmarkdown))
  suppressMessages(library(dplyr))
  suppressMessages(library(vroom))
  
  # The Polyphenol Estimation Pipeline Needs to run first.
  # Output from this pipeline kicks off the DII calculation scripts
  starting_file = "outputs/Recall_Disaggregated_mapped.csv.bz2"
  
  # Check if it was by confirming Disaggregated Dietary Data File exists
  if (!file.exists(starting_file)) {
    stop("\n Please run the polyphenol estimation pipeline before running the DII calculation.")
  } else {
    message("Confirmed polyphenol estimation pipeline was run.\n")
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
  "DII_STEP4_DII_Calculation.Rmd"))
  
  # Map report to function
  render_fun = switch(report,
                      html = run_create_html_report,
                      md   = run_create_md_report,
                      none = NULL)
  
  # Check if reports directory exists, and if not, Create one
  if (!dir.exists("reports")) dir.create("reports", recursive = TRUE)
  
  # Message saying which report is getting made
  message("DII calculation will now begin and also generate ", report, " reports.\n")
  
  # Start timing
  start_time = Sys.time()
  
  ###########################################################################
  # Case 1: Produce reports (html/md) with Rmd files
  ###########################################################################
  if (report != "none") {
    
    for (script in dii_steps) {
      tryCatch(
        {
          render_fun(script)
          message("Completed: ", script, "\n")
        },
        error = function(e) {
          stop("Error in ", script, ": ", e$message)
        }
      )
    }
    
    ###########################################################################
    # Case 2: Run .R scripts when report == "none"
    ###########################################################################
  } else {
    
    # Convert Rmd to R quietly
    scripts = character(length(dii_steps))
    for (i in seq_along(dii_steps)) {
      
      # Construct .R path
      scripts[i] = file.path(
        dirname(dii_steps[i]),
        paste0(tools::file_path_sans_ext(basename(dii_steps[i])), ".R")
      )
      
      # Convert without printing anything
      knitr::purl(
        input  = dii_steps[i],
        output = scripts[i],
        quiet  = TRUE)
    }
    
    # Execute each R script without showing messages or warnings
    for (rfile in scripts) {
      message("Running: ", rfile)
      tryCatch({
        suppressMessages(suppressWarnings(source(rfile, local = FALSE)))
        message("Done. Moving to next script.\n")
      },
      error = function(e) stop("Error running ", rfile, ": ", e$message))
    }
    
    # Remove temporary R scripts
    removed = file.remove(scripts)
    if (!all(removed)) warning("Some temporary R scripts could not be deleted.")
  }
  
  # End timing
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  minutes = floor(total_seconds / 60)
  seconds = round(total_seconds %% 60)
  
  # Completion messages
  message("42-Component DII Calculation completed successfully.\n")
  message("Total runtime: ", minutes, " min ", seconds, " sec")
}

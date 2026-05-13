# Calculate the 42-component DII
# Stephanie Wilson
# May 2026

# DII pipeline runner for beginners
calculate_DII = function(report = c("none", "html", "md")) {
  
  # Match user input
  report = match.arg(report)
  
  ##########################################
  # Create log file
  
  # Ensure outputs directory is created
  if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
  
  log_file = here::here("outputs", 
                       paste0("log_dii_", format(Sys.time(), "%Y%m%d_%H%M"), ".log"))
  
  # Captures log messages and also displays during user run
  log_message = function(...) {
    
    txt = paste0(...)
    
    # console output
    message(txt)
    
    # log file output
    cat(txt,"\n", file = log_file, append = TRUE)}
  
  # Let users know where information is going
  log_message("Log started at ", log_file, "\n")
  
  ##########################################
  # Install and load required packages
  source("R/functions/startup_functions.R")     # defines install_if_missing()
  ensure_packages(pkgs = c("dplyr", "here", "vroom", "tidyr", 
                           "stringr", "readxl", "rmarkdown"))
  
  # Load package
  suppressMessages(library(rmarkdown))
  suppressMessages(library(dplyr))
  suppressMessages(library(vroom))
  
  ##########################################
  # Start tracking
  
  # Start time
  start_time = Sys.time()
 
  # Starting log message
  log_message(
    "====================================\n",
    "42-Component DII Calculation Starting \n",
    "May 2026 Release\n",
    "\nSession start: ", format(start_time, "%Y-%m-%d %H:%M:%S"),
    "\nreport type: ", report,
    "\n")

  ##########################################
  # Preliminary Checks
  
  # Polyphenol Estimator must be run prior to DII calculation
  # Output from this pipeline kicks off the DII calculation scripts
  log_message("Checking if Polyphenol Estimator was run...")
  starting_file = here::here("outputs/Diet_Disaggregated_mapped.csv.bz2")
  
  # Check if it was by confirming Disaggregated Dietary Data File exists
  if (!file.exists(starting_file)) {
    stop(log_message("\n Please run estimate_polyphenols before running the DII calculation."))
  } else {
    log_message(" - Done.\n")
  }
  
  # List of DII scripts in order
  dii_steps = file.path("R/scripts", c(
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
  
  ###########################################################################
  # Case 1: Produce reports (html/md) with Rmd files
  ###########################################################################
  if (report != "none") {
    
    for (script in dii_steps) {
      tryCatch(
        {
          log_message("Running: ", script)
          render_fun(script)
          log_message("Done.\n")
        },
        error = function(e) {
          stop(log_message("Error in ", script, ": ", e$message))
        }
      )
    }
    
    ###########################################################################
    # Case 2: Run .R scripts when report == "none"
    ###########################################################################
  } else {
    
    # Generate list
    scripts = character(length(dii_steps))
    
    # Convert Rmd to R quietly
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
      log_message("Running: ", rfile)
      tryCatch({
        suppressMessages(suppressWarnings(source(rfile, local = FALSE)))
        log_message("Done.\n")
      },
      error = function(e) stop(log_message("Error running ", rfile, ": ", e$message)))
    }
    
    # Remove temporary R scripts
    removed = file.remove(scripts)
    if (!all(removed)) {
      log_message("Some temporary R scripts could not be deleted.")
      warning("Some temporary R scripts could not be deleted.", call. = FALSE)
    }
  }
  
  # End timing
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  minutes = floor(total_seconds / 60)
  seconds = round(total_seconds %% 60)
  
  # Completion messages
  log_message("42-Component DII Calculation completed successfully.")
  log_message("Total runtime: ", minutes, " min ", seconds, " sec")
}
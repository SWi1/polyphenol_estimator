# Polyphenol Estimator
# Stephanie Wilson
# May 2026

estimate_polyphenols = function(
    diet_input_file = "user_inputs/VVKAJ_Items.csv",  # default path
    type = c("ASA24", "NHANES"), 
    report = c("none", "html", "md")
) {
  
  # Match user input
  type = match.arg(type)   # ensures type is a single string
  report = match.arg(report)
  
  ##########################################
  # Create log file
  
  # Ensure outputs directory is created
  output_dir = here::here("outputs")
  
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  log_file = here::here("outputs", 
                       paste0("log_PE_", format(Sys.time(), "%Y%m%d_%H%M"), ".log"))
  
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
  
  source(here::here("R/functions/startup_functions.R"))
  ensure_packages(pkgs = c("dplyr", "here", "vroom", "tidyr", 
                           "stringr", "readxl", "rmarkdown"))
  suppressMessages(library(dplyr))
  suppressMessages(library(vroom))
  suppressMessages(library(rmarkdown))
  
  ##########################################
  # Start tracking
  
  start_time = Sys.time()
  
  log_message(
    "\n====================================\n",
    "Polyphenol Estimator \n",
    "\nSession start: ", format(start_time, "%Y-%m-%d %H:%M:%S"),
    "\ninput file: ", diet_input_file,
    "\ninput type: ", type,
    "\nreport type: ", report,
    "\n")
  
  ##########################################
  # Check user diet input
  
  log_message("Checking user diet input file.")
  
  diet_input_file = here::here(diet_input_file)
  
  # Confirm dietary type file exists
  if (!file.exists(diet_input_file)) {
    stop(log_message("Diet recall data file not found: ", diet_input_file))
  } else {
    message(log_message(" - Found diet recall data file."))
  }
  
  # Read data
  diet_dat = tryCatch(
    vroom::vroom(diet_input_file, show_col_types = FALSE),
    error = function(e) stop(log_message(" - Unable to read diet recall file: ", e$message))
  )
  
  # Make diet_input_file visible everywhere
  assign("diet_input_file", diet_input_file, envir = .GlobalEnv)

  # Confirm User Input is an Items File
  required_col = if (identical(type, "ASA24")) "FoodCode" else "DRXIFDCD"
  if (!required_col %in% names(diet_dat)) {
    stop(log_message(" - The diet data file must contain the column '", required_col, "' for ", type, "."))
  } else {
    log_message(" - Required column for ", type, " exists.\n")
  }
  
  ##########################################
  # Define steps based on data source

  polyphenol_steps = if (identical(type, "ASA24")) {
    file.path("R/scripts", c(
      "STEP1_ASA24_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
  } else if (identical(type, "NHANES")) {
    
    file.path("R/scripts", c(
      "STEP1_NHANES_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
    
  } else {
    stop("`type` must be either 'ASA24' or 'NHANES'")
  }
  
  ##########################################
  # Report function
  # Switches between different reports to create
  render_fun = switch(report,
                      html = run_create_html_report,
                      md   = run_create_md_report,
                      none = "none",   # marker for if/else branch
                      stop(log_message("Unknown report type: ", report)))
  
  ###########################################################################
  # Case 1: Produce reports (html/md) with Rmd files
  ###########################################################################
  
  if (report != "none") {
    
    for (script in polyphenol_steps) {
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
    
    if (!dir.exists("reports")) dir.create("reports", recursive = TRUE)
    
    # Convert Rmd to R quietly
    scripts = character(length(polyphenol_steps))
    for (i in seq_along(polyphenol_steps)) {
      
      # Construct .R path
      scripts[i] = file.path(
        dirname(polyphenol_steps[i]),
        paste0(tools::file_path_sans_ext(basename(polyphenol_steps[i])), ".R")
      )
      
      # Convert without printing anything
      knitr::purl(
        input  = polyphenol_steps[i],
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
  
  # Runtime summary
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  
  log_message("Polyphenol Estimator completed successfully.")
  log_message("Total runtime: ", floor(total_seconds/60), " min ", round(total_seconds %% 60), " sec")
}  

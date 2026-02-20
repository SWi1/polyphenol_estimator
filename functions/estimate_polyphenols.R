estimate_polyphenols = function(
    diet_input_file = "user_inputs/VVKAJ_Items.csv",  # default path
    type = c("ASA24", "NHANES"), 
    report = c("none", "html", "md")
) {

  # Match user input
  type = match.arg(type)   # ensures type is a single string
  report = match.arg(report)

  # Install and load required packages
  source("functions/startup_functions.R")
  ensure_packages(pkgs = c("dplyr", "vroom", "tidyr", "stringr", "readxl", "rmarkdown"))
  suppressMessages(library(dplyr))
  suppressMessages(library(vroom))
  suppressMessages(library(rmarkdown))
  
  # Confirm dietary type file exists
  if (!file.exists(diet_input_file)) {
    stop("Diet recall data file not found: ", diet_input_file)
  } else {
    message("Found diet recall data file.\n")
  }
  
  # Read data
  diet_dat = tryCatch(
    vroom::vroom(diet_input_file, show_col_types = FALSE),
    error = function(e) stop("Unable to read diet recall file: ", e$message)
  )
  
  # Make diet_input_file visible everywhere
  assign("diet_input_file", diet_input_file, envir = .GlobalEnv)
  
  # report function
  render_fun = switch(report,
                      html = run_create_html_report,
                      md   = run_create_md_report,
                      none = "none",   # marker for if/else branch
                      stop("Unknown report type: ", report))
  
  ##########################################
  # Data Check Status Message
  ##########################################
  required_col = if (identical(type, "ASA24")) "FoodCode" else "DRXIFDCD"
  if (!required_col %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", required_col, "' for ", type, ".")
  } else {
    message("Required column for ", type, " exists.\n")
  }
  
  ##########################################
  # Check multiple recalls per participant
  ##########################################
  # Determine ID column based on type source
  id_var = if (identical(type, "ASA24")) "UserName" else "SEQN"
  
  # Check that ID column exists
  if (!id_var %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", id_var, "' for ", type, ".")
  }
  
  # Determine if Recall or Record
  if ("RecallNo" %in% names(diet_dat)) {
    # Recall dataset
    n_events = diet_dat %>%
      group_by(.data[[id_var]]) %>%
      summarise(n_events = n_distinct(RecallNo), .groups = "drop")
    
  } else if ("RecordNo" %in% names(diet_dat) || "RecordDayNo" %in% names(diet_dat)) {
    # Record dataset
    n_events = diet_dat %>%
      group_by(.data[[id_var]]) %>%
      summarise(
        n_events = max(
          n_distinct(RecordNo %||% 0),
          n_distinct(RecordDayNo %||% 0)
        ),
        .groups = "drop"
      )
    
  } else {
    stop("Dataset has neither RecallNo nor RecordNo/RecordDayNo columns.")
  }
  
  # Recall Status Message
  if (max(n_events$n_events, na.rm = TRUE) < 2) {
    stop("Your diet file does not contain multiple recalls or records per participant.")
  } else {
    message("Multiple recalls or records detected across participants.\n")
  }
  
  ##########################################
  # Define steps based on data source
  ##########################################
  polyphenol_steps = if (identical(type, "ASA24")) {
    file.path("scripts", c(
      "STEP1_ASA24_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
  } else {
    file.path("scripts", c(
      "STEP1_NHANES_FDD_Disaggregation.Rmd",
      "STEP2_FDD_FooDB_Content_Mapping.Rmd",
      "STEP3a_Polyphenol_Summary_Total.Rmd",
      "STEP3b_Polyphenol_Summary_Class.Rmd",
      "STEP3c_Polyphenol_Summary_Compound.Rmd",
      "STEP3d_Polyphenol_Summary_Food_Contributors.Rmd"
    ))
  }

  ###########################################################################
  # Case 1: Produce reports (html/md) with Rmd files
  ###########################################################################
  
  message("Polyphenol estimation will now begin. The following scripts will also be rendered as ", report, " files.\n")
  start_time = Sys.time()
  
  if (report != "none") {
    
    for (script in polyphenol_steps) {
      tryCatch(
        {
          message("Running: ", script)
          render_fun(script)
          message("Done. Moving to next script.\n")
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
    
  # Runtime summary
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  message("Polyphenol estimation completed successfully.")
  message("Total runtime: ", floor(total_seconds/60), " min ", round(total_seconds %% 60), " sec")
}

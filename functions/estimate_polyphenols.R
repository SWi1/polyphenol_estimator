estimate_polyphenols = function(data = c("ASA24", "NHANES"), output = c("html", "md")) {
  
  # Match user input
  data = match.arg(data)
  output = match.arg(output)
  
  # Install and load required packages
  source("functions/startup_functions.R")
  ensure_packages(pkgs = c("dplyr", "vroom", "tidyr", "stringr", "ggplot2", "readxl", "rmarkdown"))
  suppressMessages(library(dplyr))
  suppressMessages(library(vroom))
  suppressMessages(library(rmarkdown))
  
  ##########################################
  # Check if we have dietary data
  ##########################################
  
  # Load user-specified inputs
  source("specify_inputs.R")
  
  # Confirm dietary data file exists
  if (!exists("diet_input_file") || !file.exists(diet_input_file)) {
    stop("Diet recall data file not found: ", diet_input_file)
  } else {
    message("Checkpoint - Found diet recall data file.\n")
  }
  
  # Read data
  diet_dat = tryCatch(
    vroom::vroom(diet_input_file, show_col_types = FALSE),
    error = function(e) stop("Unable to read diet recall file: ", e$message)
  )
  
  # Data Check Status Message
  required_col = if (data == "ASA24") "FoodCode" else "DRXIFDCD"
  if (!required_col %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", required_col, "' for ", data, " data.")
  } else {
    message("Checkpoint - Required column for ", data, " exists.\n")
  }
  
  ##########################################
  # Check multiple recalls per participant
  ##########################################
  
  # Determine ID column based on data source
  id_var = if (data == "ASA24") "UserName" else "SEQN"
  
  # Check that ID column exists
  if (!id_var %in% names(diet_dat)) {
    stop("The diet data file must contain the column '", id_var, "' for ", data, ".")
  }
  
  recalls_per_user = diet_dat %>%
    group_by(.data[[id_var]]) %>%
    summarise(n_recalls = n_distinct(RecallNo), .groups = "drop")
  
  # Recall Status Message
  if (max(recalls_per_user$n_recalls, na.rm = TRUE) < 2) {
    stop("The diet recall file does not contain multiple recalls per participant.")
  } else {
    message("Checkpoint - Multiple recalls detected across participants.\n")
  }
  
  ##########################################
  # Define steps based on data source
  ##########################################
  
  polyphenol_steps = if (data == "ASA24") {
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
  
  ##########################################
  # Confirm dietary data file exists
  ##########################################

  # Ensure we have flexibility to render different reports
  render_fun = switch(output,
                       html = run_create_html_report,
                       md   = run_create_md_report)
  
  # Creates a report directory
  if (!dir.exists("reports")) dir.create("reports", recursive = TRUE)
  
  message("Pipeline will now start and generate ", output, " reports.\n")
  start_time = Sys.time()
  
  ##########################################
  # Run scripts
  ##########################################
  
  for (script in polyphenol_steps) {
    tryCatch({
      render_fun(script)
      message("Completed: ", script, "\n")
    }, error = function(e) {
      stop("Error in ", script, ": ", e$message)
    })
  }
  
  ##########################################
  # Runtime summary
  ##########################################
  
  end_time = Sys.time()
  total_seconds = as.numeric(difftime(end_time, start_time, units = "secs"))
  message("Polyphenol estimation pipeline completed successfully.")
  message("Total runtime: ", floor(total_seconds/60), " min ", round(total_seconds %% 60), " sec")
}

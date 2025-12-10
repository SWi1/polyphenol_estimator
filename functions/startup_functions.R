# HELPER FUNCTIONS
# Stephanie Wilson

# package installation
# ------------------------------------------------------------
# Function to install pipeline packages if not already installed by user
ensure_packages = function(pkgs, specify_inputs_script = "provided_files.R") {
  # message the user
  message("Checking for dependencies...")
  
  # load the necessary paths
  if (!file.exists(specify_inputs_script)) {
    stop("Cannot find ", specify_inputs_script)
  }
  source(specify_inputs_script)
  
  # make sure the path exists otherwise error out
  if(!dir.exists(Local_R_packages)) {
    stop("The path '", Local_R_packages, "' does not exist. Please check your 
        specify_inputs.R file and ensure the Local_R_packages variable is set correctly.")
  }
  
  # Create a local library directory relative to the script
  local_lib <- file.path(Local_R_packages, "r_packages")
  
  if (!dir.exists(local_lib)) {
    dir.create(local_lib, recursive = TRUE)
  }
  
  # Add to library path if not already there
  if (!local_lib %in% .libPaths()) {
    .libPaths(c(local_lib, .libPaths()))
  }
  
  # Check and install missing packages
  missing_pkgs <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
  
  if (length(missing_pkgs) > 0) {
    message("Installing missing packages to: ", local_lib, "\n")
    for (i in seq_along(missing_pkgs)) {
      pkg <- missing_pkgs[i]
      message("installing: ", pkg)
      install.packages(pkg, lib = local_lib, repos = "https://cran.rstudio.com/", 
                       quiet = TRUE)
      
    }
    message("\nAll packages installed!")
  } else {
    message("All required packages are already installed.")
  }
  
  invisible(TRUE)
}

# rmarkdown::render, run scripts and render html or md reports for a given RMD
# ------------------------------------------------------------
# triggers html yaml components
run_create_html_report = function(file, diet_input_file) {
  rmarkdown::render(
    file,
    output_format = "html_document",
    output_file = NULL,
    output_dir = "reports",
    clean = TRUE,
    quiet = TRUE
  )
}

# Triggers md yaml components
run_create_md_report = function(file, diet_input_file) {
  rmarkdown::render(
    file,
    output_format = "md_document",
    output_file = NULL,
    output_dir = "reports",
    clean = TRUE,
    quiet = TRUE
  )
}

# HELPER FUNCTIONS
# Stephanie Wilson

# package installation
# ------------------------------------------------------------
# Function to install pipeline packages if not already installed by user
install_if_missing =  function(pkgs) {
  for (pkg in pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("Installing package: ", pkg)
      install.packages(pkg)
    }
  }
}

# rmarkdown::render, run scripts and render html or md reports for a given RMD
# ------------------------------------------------------------
# triggers html yaml components
run_create_html_report = function(file) {
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
run_create_md_report = function(file) {
  rmarkdown::render(
    file,
    output_format = "md_document",
    output_file = NULL,
    output_dir = "reports",
    clean = TRUE,
    quiet = TRUE
  )
}

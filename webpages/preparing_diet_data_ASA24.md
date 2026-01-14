---
layout: default
title: ASA24 diet recalls
parent: Preparing Diet Data
nav_order: 1
has_toc: true
---

# Preparing ASA24 Dietary Data
## Use demo data

An example ASA24 Items File is provided from [DietDiveR](https://github.com/computational-nutrition-lab/DietDiveR). You can use this to examine the format of the necessary input file and run Polyphenol Estimator before using your own data.

**IMPORTANT** - Polyphenol Estimator expects data files where there is more than one recall per participant (a future update will run with just one recall).

## Use your own ASA24 data
### 1.  Download the ASA24 Items file from all respondents in your study on the [ASA24 researcher website](https://asa24.nih.gov/researcher/#/login).
![Screenshot of downloading data from ASA24 Researcher Website](../workflow_images/ASA24_download.png)

### 2. Perform dietary quality control checks. 
  - Polyphenol Estimator will automatically include people with more than one recall and complete (`RecallStatus`==5).
  - Any additional dietary quality control checks should be done before running Polyphenol Estimator. The NIH provides [ASA24 quality control guidelines](https://epi.grants.cancer.gov/asa24/resources/cleaning.html), which covers missing data, text entries, outlier review, and duplicate entries.

### 3. Come back to run_pipeline.R and update `diet_input_file` with your own ASA24 file path.
  - Polyphenol Estimator will run the example ASA24 file **unless** you change the input data.

### 4. Run the polyphenol estimation pipeline for your ASA24 data. 
  - Refer to [Start Guide](https://swi1.github.io/polyphenol_pipeline) for instructions to run Polyphenol Estimator.
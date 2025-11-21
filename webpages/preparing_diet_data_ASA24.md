---
layout: default
title: ASA24 diet recalls
parent: Preparing Diet Data
nav_order: 1
has_toc: true
---

# Preparing ASA24 Dietary Data
## Use demo data

An example ASA24 Items File is provided from [DietDiveR](https://github.com/computational-nutrition-lab/DietDiveR). You can use this to examine the format of the necessary input file and run the pipeline before using your own data.

## Use your own ASA24 data
### 1.  Download the ASA24 Items file from your study on the [ASA24 researcher website](https://asa24.nih.gov/researcher/#/login).
    - The Items file contains data by food and beverage item for each of your study participants. This file contains food codes, gram weights, and nutrient and food group values.
    - **IMPORTANT** - The pipeline expects data files where there is more than one recall per participant (a future update will run with just one recall).

### 2. Perform dietary quality control checks. 
    - The pipeline will automatically include people with more than one recall and complete (`RecallStatus`==5).
    - Any additional dietary quality control checks should be done before running the pipeline. The NIH provides [ASA24 quality control guidelines](https://epi.grants.cancer.gov/asa24/resources/cleaning.html), which covers missing data, text entries, outlier review, and duplicate entries.

### 3. Update `diet_input_file` path in specify_inputs.R to your own ASA24 file.
    - The pipeline will run the example ASA24 file **unless** you change the input data.

### 4. Run the polyphenol estimation pipeline for ASA24 data. 
    - Refer to [Start Guide](https://swi1.github.io/polyphenol_pipeline/#polyphenol-estimation-pipeline) for instructions to run the pipeline.
---
title: Start Guide
layout: home
nav_order: 1
---

# Polyphenol Estimation Pipeline

This start guide shows you how to estimate polyphenol intake using the FooDB database from ASA24 or NHANES diet recall data. The guide also covers how to calculate the dietary inflammatory index[^1] from ASA24 or NHANES diet recall data.

Example ASA24 data, borrowed from the DietDiveR Repository[^2], is provided for you to test. We encourage you to check out this file to better understand the input data required for the pipeline

## Get started 
### 1. Download the entire repository (by bash below or clicking [here](https://github.com/SWi1/polyphenol_estimation_beta/archive/refs/heads/main.zip)). 
The repository contains files and scripts used in the tutorial.

```{bash}
git clone https://github.com/username/repo.git
```
###  2. Create and save a new R file into the downloaded repository folder. 
Don't save it in any subdirectories.

### 3. Set your working directory to the downloaded repository folder.

### 4. In your R script, copy and run the code below to load `estimate_polyphenols` and `calculate_DII` functions.

```{r}
# Polyphenol Estimation Pipeline
source('functions/run_polyphenol_pipeline_function.R')

# DII Calculation Pipeline
source('functions/run_DII_function.R')
```
### 5. Copy and run the R code below to run the polyphenol estimation pipeline.
We are specifying that we are running ASA24 data and would like html reports from each pipeline step.

```{r}
estimate_polyphenols(data = "ASA24", output = "html") 
```
<details>
<summary> <b>Test HANES data instead:</b>
</summary>
`estimate_polyphenols` can also be run on NHANES data. To generate NHANES data to test, you can follow the instructions in ["Preparing - NHANES diet recalls"](webpages/Prepare_NHANES_data.md). After you've finished, you must update `diet_input_file` in `specify_inputs.R` with your NHANES output. Once those are complete, you can copy and run the following:

```{r}
estimate_polyphenols(data = "NHANES", output = "html") 
```
</details>

### 6. Copy and run the R code below to calculate the Dietary Inflammatory Index.
The same function can be run on ASA24 and NHANES data. You just need to specify output as "html" or "md".

```{r}
calculate_DII(output = "md")
```

[^1]: [Shivapppa et al. 2013. Designing and developing a literature-derived, population-based dietary inflammatory index](10.1017/S1368980013002115)
[^2]: [DietDiveR Repo](https://computational-nutrition-lab.github.io/DietDiveR/).
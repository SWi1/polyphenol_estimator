---
title: Start Guide
layout: home
nav_order: 1
---

# Polyphenol Estimation Pipeline

This start guide shows you how to take your ASA24 or NHANES dietary data and estimate polyphenol intake using the [FooDB](https://foodb.ca/) and calculate the dietary inflammatory index[^1]. Example ASA24 data, borrowed from the DietDiveR Repository[^2], is provided for you to test. Check out [the example file here](https://github.com/SWi1/polyphenol_pipeline/blob/main/user_inputs/VVKAJ_Items.csv) to see the input structure required for the pipeline.

### 1. Download the entire repository directly [here](https://github.com/SWi1/polyphenol_pipeline/archive/refs/heads/main.zip) then unzip the folder. 
The repository contains files and scripts used in the tutorial.

###  2. Open 'run_pipeline.R' in RStudio.
![Screenshot of run_pipeline.R script](workflow_images/run_pipeline_screenshot.png)

### 3. Update `diet_input_file` path if not using the demo ASA24 data.
![Screenshot of where to update file path.](workflow_images/update_diet_path.png)

### 4. Run the scripts.
In our usage case of ASA24 data, we have specified that the input is ASA24 data and that we would not like a report of what happens in each pipeline step. After you've run `estimate_polyphenols`, you can also run `calculate_DII`. Calculation of DII is *optional*. The function automatically detects whether you've run ASA24 or NHANES data, you only need to specify if you would like to see what happens in each script.

### 5. Check out the resulting files in your output directory!
Find a list of expected outputs below:
- [Polyphenol Estimation Pipeline Outputs](https://swi1.github.io/polyphenol_pipeline/webpages/polyphenol_estimation_pipeline.html#outputs)
- [DII Calculation Outputs](https://swi1.github.io/polyphenol_pipeline/webpages/DII_calculation.html#outputs)

<details>
<summary>Reports: See What's in Each Script</summary>
  <ul>
  For every script that was run, a report was generated in the reports folder. 
  This online tutorial actually shows you what the reports look like if you navigate to pages under "Polyphenol Estimation Pipeline" and "DII Calculation" in your sidebar.
  </ul>
</details>

### Want to test NHANES data instead?
`estimate_polyphenols` can also be run on NHANES WWEIA data. To generate NHANES WWEIA data, follow the instructions in ["Preparing Diet Data - NHANES diet recalls"](https://swi1.github.io/polyphenol_pipeline/webpages/preparing_diet_data_NHANES.html#prepare-nhanes-diet-recall-data). When you've finished: 
1. Come back to run_pipeline.R and update `diet_input_file` with the NHANES output file name. 
2. In `estimate_polyphenols`, change type to "NHANES"
2. Run the script. 

[^1]: [Shivapppa et al. 2013. Designing and developing a literature-derived, population-based dietary inflammatory index](10.1017/S1368980013002115)
[^2]: [DietDiveR Repo](https://computational-nutrition-lab.github.io/DietDiveR/).

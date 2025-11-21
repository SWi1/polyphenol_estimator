---
layout: default
title: Polyphenol Estimation Pipeline
nav_order: 3
show_toc: true
has_children: true
---

# Polyphenol Estimation Pipeline

Each of the pages in this sections shows you a pipeline-generated report. 

## Pipeline Steps

The polyphenol estimation pipeline takes either ASA24 Items Files or NHANES "Individual Foods" Recall Files. Based on the input, STEP 1 will differ but STEPS 2 - 6 are the same.

For simplicity, STEPS 2 - 6 in this tutorial show the output from the demo ASA24 data. The report for STEP 2 shows summary information about the number of unmapped foods, which will vary between datasets.

### Steps Specific to ASA24
1) STEP1_ASA24_FDD_Disaggregation.Rmd
    - For provided ASA24 data, WWEIA food codes are disaggregated to ingredients. A new ingredient amound is calculated based off percentages included in the [FDA's Food Dissagregation Database](https://pub-connect.foodsafetyrisk.org/fda-fdd/). Total nutrient intake is also calculated across recalls for later standardization of polyphenol intake. 
    
### Steps Specific to NHANES
1) STEP1_NHANES_FDD_Disaggregation.Rmd
    - For provided NHANES data, WWEIA food codes are disaggregated to ingredients. A new ingredient amound is calculated based off percentages included in the [FDA's Food Dissagregation Database](https://pub-connect.foodsafetyrisk.org/fda-fdd/). Total nutrient intake is also calculated across recalls for later standardization of polyphenol intake. 
### Steps used on both ASA24 and NHANES
2) STEP2_FDD_FooDB_Content_Mapping.Rmd
    - Connects each of your disaggregated ASA24 Foods to their equivalent food description in FooDB so that polyphenol intake can be estimated.  
    - **IMPORTANT**- Provides summary information about the number of foods in your data that did not map to FooDB.
3) STEP3a_Polyphenol_Summary_Total.Rmd
    - Calculates total polyphenol intake (mg, mg/1000kcal) for each recall as well as an overall subject summary.
4) STEP3b_Polyphenol_Summary_Class.Rmd
    - Calculates class polyphenol intake (mg, mg/1000kcal) for each recall as well as an overall subject summary.
5) STEP3c_Polyphenol_Summary_Compound.Rmd
    - Calculates compound polyphenol intake (mg, mg/1000kcal) for each recall as well as an overall subject summary.
6) STEP3d_Polyphenol_Summary_Food_Contributors.Rmd
    - Examines food contributors to total polyphenol intake.

## Expected Outputs

### Mapping
Our mapping output files are large feature-rich datasets, which we have  compressed.
- Input_Disaggregated.csv.bz2
    - Food codes are shown with their underlying ingredients and newly calculated gram intakes
- Input_Disaggregated_mapped.csv.bz2
    - Food codes are shown with their underlying ingredients and newly calculated gram intakes, and FooDB food name equivalent (no content)
- Input_FooDB_polyphenol_content.csv.bz2
    - Food codes are shown with their underlying ingredients and newly calculated gram intakes, and FooDB food names and polyphenol content

### Intake Summaries
<details>
<summary>Total Polyphenol Intake Files</summary>
  <ul>
  <li>Input_total_nutrients.csv</li>
      - Nutrient totals are provided by recall for each participant
  <li>Input_FooDB_polyphenol_content_total_by_recall.csv</li>
      - polyphenol total intakes by recall for each participant
  <li>Input_FooDB_polyphenol_content_total_by_subject.csv</li>
      - polyphenol total intakes for each participant
  <li>Input_FooDB_polyphenol_food_contributors.csv</li>
      - total polyphenol and intake averages for each food, as well as food frequencies within the input diet data.
  </ul>
</details>

<details>
<summary>Class Polyphenol Intake Files</summary>
  <ul>
  <li>Input_FooDB_polyphenol_content_class_by_recall.csv</li>
      - polyphenol class intakes by recall for each participant
  <li>Input_FooDB_polyphenol_content_class_by_subject.csv</li>
      - polyphenol class intakes for each participant, provided in wide format (classes as rows)
  <li>Input_FooDB_polyphenol_content_class_by_subject_wide.csv</li>
      - polyphenol class intakes for each participant, provided in wide format (classes as columns)
  </ul>
</details>

<details>
<summary>Compound Polyphenol Intake Files</summary>
  <ul>
   <li>Input_FooDB_polyphenol_content_compound_by_recall.csv</li>
      - polyphenol compound intakes by recall for each participant
   <li>Input_FooDB_polyphenol_content_compound_by_subject.csv</li>
      - polyphenol compound intakes for each participant, provided in wide format (compounds as rows)
   <li>Input_FooDB_polyphenol_content_compound_by_subject_wide.csv</li>
      - polyphenol compound intakes for each participant, provided in wide format (compounds as columns)
  </ul>
</details>
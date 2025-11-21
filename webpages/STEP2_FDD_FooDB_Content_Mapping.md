---
layout: default
title: Step 2 Map foods to FooDB
parent: Polyphenol Estimation Pipeline
nav_order: 3
has_toc: true
---

- [Map Disaggregated Foods to FooDB](#map-disaggregated-foods-to-foodb)
  - [INPUTS](#inputs)
  - [OUTPUTS](#outputs)
- [SCRIPTS](#scripts)
  - [Connect Disaggregated ASA to FooDB through key
    link.](#connect-disaggregated-asa-to-foodb-through-key-link.)
  - [Merge FooDB-matched Ingredient Codes to FooDB Polyphenol Content
    File.](#merge-foodb-matched-ingredient-codes-to-foodb-polyphenol-content-file.)
- [Review of Unmapped Foods](#review-of-unmapped-foods)
  - [Find foods and food components that did not map to
    FooDB:](#find-foods-and-food-components-that-did-not-map-to-foodb)
  - [How many recalls had at least one food
    missing](#how-many-recalls-had-at-least-one-food-missing)
  - [Distribution of Unmapped Foods Percentages by
    Recall](#distribution-of-unmapped-foods-percentages-by-recall)

## Map Disaggregated Foods to FooDB

This script takes your disaggregated foods (from ASA24 or NHANES) and
maps them to FooDB to derive polyphenol content.

### INPUTS

- **Input_Disaggregated.csv.bz2**: Input dietary data that has been
  disaggregated using FDD.
- **FDA_FooDB_Mapping_Nov_2025.csv**: FDD to FooDB matches.  
- **FooDB_polyphenol_content_with_dbPUPsubstrates_Aug25.csv.bz2**:
  Phenols pulled out of Compounds.csv and matched to FooDB’s Compounds
  file with cleaned text descriptions. Includes dbPUP substrates
- **FooDB_phenol_content_foodsums_Dec24Update.csv**: Summed polyphenol
  intake per unique food id in FooDB. Specific foods not present in
  FooDB or present but not quantified have had their concentrations
  adjusted.

### OUTPUTS

- **Input_Disaggregated_mapped.csv.bz2**; Dissagregated dietary data,
  mapped to FooDB foods
- **Input_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary
  data, mapped to FooDB foods and polyphenol content

## SCRIPTS

``` r
# Load packages
library(tidyverse)
```

Load data

``` r
# Load user-defined input paths
source("specify_inputs.R")

input = vroom::vroom('outputs/Input_Disaggregated.csv.bz2', 
                     show_col_types = FALSE) %>%
  select(-wweia_food_description)

# FDD to FooDB food mappings
mapping = vroom::vroom(mapping, show_col_types = FALSE) %>%
  select(-c(method, score)) 

#FooDB polyphenol quantities
FooDB_mg_100g = vroom::vroom(FooDB_mg_100g, 
                     show_col_types = FALSE) %>%
  # Since we created orig_content_avg from multiple sources, ensure distinct values
  distinct(food_id, compound_public_id, .keep_all = TRUE) %>%
  select(-c(food_public_id, food_name)) %>%
  relocate(orig_content_avg, .before = citation) %>%
  # Keep only quantified compounds
  filter(!is.na(orig_content_avg_RFadj)) 
```

### Connect Disaggregated ASA to FooDB through key link.

``` r
input_mapped = input %>%
  # Connect to foodb names
  left_join(mapping, by = c("fdd_ingredient"))

vroom::vroom_write(input_mapped, 'outputs/Input_Disaggregated_mapped.csv.bz2')
```

### Merge FooDB-matched Ingredient Codes to FooDB Polyphenol Content File.

- Link between FooDB Polyphenol Content and code-matched data is
  *food_id*.
- Add *pp_consumed*, for polyphenol content (mg/100g multiply by 0.01 to
  get mg/g) by ingredient consumed (grams) to get the polyphenol amount
  consumed (mg).

``` r
input_mapped_content = input_mapped %>%
  # Bring in the Polyphenol Content
  dplyr::left_join(FooDB_mg_100g, by = 'food_id', relationship = "many-to-many") %>%
  select(-c(food_V2_ID.y, aggregate_RF)) %>%
  rename(food_V2_ID = food_V2_ID.x) %>%
  # Calculate polyphenol amount consumed in milligrams
  # Specific Polyphenols in Tea from Duke and DFC seem to correspond to dry weight 
  # apply the correction for dry weight
  mutate(
    pp_consumed = if_else(
      compound_public_id %in% c("FDB000095", "FDB017114") & food_id == 38,
      (orig_content_avg_RFadj * 0.01) * FoodAmt_Ing_g * (ingredient_percent / 100),
      (orig_content_avg_RFadj * 0.01) * FoodAmt_Ing_g))
```

Export polyphenol content file. Compress as this is the largest file
that we generate.

``` r
vroom::vroom_write(input_mapped_content, 'outputs/Input_FooDB_polyphenol_content.csv.bz2')
```

## Review of Unmapped Foods

### Find foods and food components that did not map to FooDB:

    ## [1] "Yeast extract"        "Hops"                
    ## [3] "Seaweed, nori, dried"

### How many recalls had at least one food missing

    ## Number of recalls where all Foods Mapped: 23

    ## Number of recalls where at least one food did not map: 25

### Distribution of Unmapped Foods Percentages by Recall

![](/Users/smgwilso/Desktop/Version_2/reports/STEP2_FDD_FooDB_Content_Mapping_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

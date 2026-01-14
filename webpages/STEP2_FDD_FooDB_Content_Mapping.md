---
layout: default
title: Step 2 Map foods to FooDB
parent: Polyphenol Estimator
nav_order: 3
has_toc: true
---                              
                              
- [Map Disaggregated Foods to FooDB](#map-disaggregated-foods-to-foodb)
- [SCRIPTS](#scripts)
  - [Connect Disaggregated ASA to FooDB through key
    link.](#connect-disaggregated-asa-to-foodb-through-key-link.)
  - [Merge FooDB-matched Ingredient Codes to FooDB Polyphenol Content
    File.](#merge-foodb-matched-ingredient-codes-to-foodb-polyphenol-content-file.)
  - [Review of Unmapped Foods](#review-of-unmapped-foods)

## Map Disaggregated Foods to FooDB

This script takes your disaggregated foods (from ASA24 or NHANES) and
maps them to FooDB to derive polyphenol content.

#### INPUTS

- **Recall_Disaggregated.csv.bz2**: Input dietary data that has been
  disaggregated using FDD.
- **FDA_FooDB_Mapping_Nov_2025.csv**: FDD to FooDB matches.  
- **FooDB_polyphenol_content_with_dbPUPsubstrates_Aug25.csv.bz2**:
  Phenols pulled out of Compounds.csv and matched to FooDB’s Compounds
  file with cleaned text descriptions. Includes dbPUP substrates
- **FooDB_phenol_content_foodsums_Dec24Update.csv**: Summed polyphenol
  intake per unique food id in FooDB. Specific foods not present in
  FooDB or present but not quantified have had their concentrations
  adjusted.

#### OUTPUTS

- **Recall_Disaggregated_mapped.csv.bz2**; Disaggregated dietary data,
  mapped to FooDB foods
- **Recall_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary
  data, mapped to FooDB foods and polyphenol content
- **summary_missing_foods_overview.txt**: Summary of the number of
  unmapped foods between FDA-FDD and FooDB across ALL recalls
- **summary_missing_foods_detailed.csv**: Summary of the number of
  unmapped foods between FDA-FDD and FooDB BY recall

## SCRIPTS

``` r
# Load packages
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
```

Load data

``` r
# Load provided file paths
source("provided_files.R")

input = vroom::vroom('outputs/Recall_Disaggregated.csv.bz2', 
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

vroom::vroom_write(input_mapped, 'outputs/Recall_Disaggregated_mapped.csv.bz2', delim = ",")
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
vroom::vroom_write(input_mapped_content, 'outputs/Recall_FooDB_polyphenol_content.csv.bz2', delim = ",")
```

### Review of Unmapped Foods

Find foods and food components that did not map to FooDB:

``` r
unmapped_foods = input_mapped %>% 
  select(c(fdd_ingredient, orig_food_common_name)) %>% 
  # This extracts the entries that did not map
  filter(!is.na(fdd_ingredient) & is.na(orig_food_common_name)) %>% 
  distinct(fdd_ingredient, .keep_all = TRUE) %>%
  pull(fdd_ingredient)

# Calculate summary statistics
percent_unmapped = (length(unmapped_foods)/length(mapping$fdd_ingredient))*100
```

How many recalls had at least one food missing

``` r
#Count missing mappings for each recall
missing_counts = input_mapped %>%
  group_by(subject, RecallNo) %>%
  summarise(
    missing = sum(is.na(orig_food_common_name)),
    total = n(),
    percent_missing = missing / total * 100,
    .groups = "drop")

# Calculate summary statistics
num_recalls_all_mapped = sum(missing_counts$percent_missing == 0)
num_recalls_some_missing = sum(missing_counts$percent_missing != 0)
```

Create a summary report reflecting the number of missing foods

``` r
# Main Report on Missing Mappings
report_lines = c(
  "=== Unmapped Ingredients Report ===",
  paste("Report Time:", Sys.time()),
  paste("Number of unique FDA-FDD ingredients that did not map to FooDB:", length(unmapped_foods)),
  paste("Percentage of ingredients missing:", round(percent_unmapped, 2), "%"),
  "",
  "List of unmapped ingredients:",
  unmapped_foods,
  "",
  "=== Recall-level Missing Counts ===",
  paste("Number of recalls where all foods mapped:", num_recalls_all_mapped),
  paste("Number of recalls where at least one food did not map:", num_recalls_some_missing))

# Write to text file
writeLines(report_lines, "outputs/summary_missing_foods_overview.txt")

# Write out detailed recall-level data
vroom::vroom_write(missing_counts, 'outputs/summary_missing_foods_detailed.csv', delim = ",")
```

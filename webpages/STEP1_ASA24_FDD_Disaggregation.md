---
layout: default
title: Step 1 Disaggregate food codes (ASA24)
parent: Polyphenol Estimation Pipeline
nav_order: 1
has_toc: true
---                            
                              
- [Disaggregation of ASA24 Foods](#disaggregation-of-asa24-foods)
- [SCRIPT](#script)
  - [Dietary Data Filtering](#dietary-data-filtering)
  - [Sum Recall to get total kcal and Additional Nutrient
    Summaries](#sum-recall-to-get-total-kcal-and-additional-nutrient-summaries)
  - [Minimize the number of columns to the essential
    data](#minimize-the-number-of-columns-to-the-essential-data)
  - [Apply Ingredient Percentage Adjustment for Coffee and Tea
    Brewing](#apply-ingredient-percentage-adjustment-for-coffee-and-tea-brewing)
  - [Disaggregate Food Codes and compute final Ingredient
    Weights](#disaggregate-food-codes-and-compute-final-ingredient-weights)
  - [Write output files](#write-output-files)

## Disaggregation of ASA24 Foods

This script takes in ASA24 ITEMS files, disaggregates WWEIA food codes
to ingredients, and calculates the new ingredient weight. This script
also calculates total caloric intake & other nutrients for each
participant recall so polyphenol intakes can be standardized to caloric
intake later on.

#### INPUTS

- **Your Dietary Data** - This script does not provide filtering for
  portion or nutrient outliers. These may be performed in advance. The
  ASA24 website has cleaning recommendations here: [“Reviewing and
  Cleaning ASA24
  Data”](https://epi.grants.cancer.gov/asa24/resources/cleaning.html).

- **FDA_FDD_All_Records_v_3.1.xlsx** - FDD FoodCodes to Ingredients and
  Ingredient Percentages

#### OUTPUTS

- **Recall_Disaggregated.csv.bz2**: Dietary data that has been
  disaggregated using FDD.
- **Recall_total_nutrients.csv**: Total daily kcal intakes for unique
  subject and recall combination.

## SCRIPT

``` r
# Load packages
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
suppressMessages(library(readxl))
```

Load Example Dietary Data and FDA-FDD V3.6

``` r
# Load provided file paths
source("provided_files.R")

# Load User Dietary Data
input_data = vroom::vroom(diet_input_file, show_col_types = FALSE) %>%
  rename(subject = UserName)

# FDD Disaggregation options
# Rename for ease of use.
FDD_V3 = read_xlsx(FDD_file) %>%
  rename(latest_survey = "Latest Survey",
         wweia_food_code = "WWEIA Food Code",
         wweia_food_description = "WWEIA Food Description",
         fdd_ingredient = "Basic Ingredient Description",
         ingredient_percent = "Ingredient Percent") %>%
  select(wweia_food_code, wweia_food_description,  
         fdd_ingredient, ingredient_percent) %>%
  mutate(wweia_food_code = as.integer(wweia_food_code))
```

### Dietary Data Filtering

Filter IN Individuals With More than Recall and filter OUT incomplete
recalls.

- RecallStatus: 2=Complete; 5=Breakoff/Quit

``` r
input_data_clean = input_data %>%
  group_by(subject) %>%
  # Filter in more than one recall
  filter(n_distinct(RecallNo) > 1) %>%
  ungroup() %>%
  # Filter out incomplete recalls
  filter(!RecallStatus==5)
```

### Sum Recall to get total kcal and Additional Nutrient Summaries

``` r
input_total_nutrients = input_data_clean %>%
  group_by(subject, RecallNo) %>%
  summarize(across(KCAL:B12_ADD, ~ sum(.x, na.rm = TRUE), .names = "Total_{.col}")) %>%
  ungroup()
```

    ## `summarise()` has grouped output by 'subject'. You can override using the
    ## `.groups` argument.

### Minimize the number of columns to the essential data

``` r
input_data_clean_minimal = input_data_clean %>%
  rename(wweia_food_code = FoodCode,
         food_description = Food_Description) %>%
  select(c(subject, RecallNo, wweia_food_code, food_description, FoodAmt))
```

### Apply Ingredient Percentage Adjustment for Coffee and Tea Brewing

``` r
FDD_V3_adjusted = FDD_V3 %>%
  group_by(wweia_food_code) %>%
  mutate(
    
    # Create Flag 
    has_tea    = any(str_detect(fdd_ingredient, regex("Tea", ignore_case = TRUE))),
    has_coffee = any(str_detect(fdd_ingredient, regex("Coffee", ignore_case = TRUE))),
    has_water  = any(str_detect(fdd_ingredient, regex("Water", ignore_case = TRUE))),

    # Add combined coffee|tea + water percentages
    brewing_adjustment_total = case_when(
      # Tea + Water
      has_tea & has_water ~ sum(
        ingredient_percent[str_detect(fdd_ingredient, regex("Tea|Water", ignore_case = TRUE))],
        na.rm = TRUE),
      # Coffee + Water
      has_coffee & has_water ~ sum(
        ingredient_percent[str_detect(fdd_ingredient, regex("Coffee|Water", ignore_case = TRUE))],
        na.rm = TRUE),
      TRUE ~ NA_real_),
    
    # Ensure new brewing adjustment percentage is applied to only coffee|tea
    brewing_adjustment_percentage = if_else(
      str_detect(fdd_ingredient, regex("Coffee|Tea", ignore_case = TRUE)),
      brewing_adjustment_total,
      NA_real_)) %>%
  select(-c(has_tea, has_coffee, has_water, brewing_adjustment_total)) %>%
  ungroup()
```

### Disaggregate Food Codes and compute final Ingredient Weights

``` r
merge = left_join(input_data_clean_minimal, FDD_V3_adjusted, by = "wweia_food_code", 
                  relationship = "many-to-many") %>%
  # Compute final ingredient weight
  # If brewing adjustment exists, it will use this adjustment first.
  mutate(FoodAmt_Ing_g = FoodAmt * (
      coalesce(brewing_adjustment_percentage, ingredient_percent) / 100))
```

### Write output files

Ensure outputs directory is created

``` r
if (!dir.exists("outputs")) dir.create("outputs", recursive = TRUE)
```

Write Files

``` r
vroom::vroom_write(merge, 'outputs/Recall_Disaggregated.csv.bz2')
vroom::vroom_write(input_total_nutrients, 'outputs/Recall_total_nutrients.csv')
```

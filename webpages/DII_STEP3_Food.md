---
layout: default
title: Step 3 Foods and food components
parent: DII Calculation
nav_order: 3
has_toc: true
---                              
                              
- [Calculate DII Foods and Food
  Components](#calculate-dii-foods-and-food-components)
- [SCRIPT](#script)
  - [Specify grouping variables](#specify-grouping-variables)
  - [Isolate FDD descriptions for each food
    group](#isolate-fdd-descriptions-for-each-food-group)
  - [Derive food component intakes](#derive-food-component-intakes)
  - [Export Food Intake Amounts for DII
    Calculation](#export-food-intake-amounts-for-dii-calculation)

## Calculate DII Foods and Food Components

This script takes in your disaggregated and FooDB-linked descriptions to
calculate intake of 7 specific food categories (onion, ginger, garlic,
tea, pepper, turmeric, thyme/oregano).

#### INPUTS

- **Diet_Disaggregated_mapped.csv.bz2** - Disaggregated dietary data,
  mapped to FooDB foods, From Step 2 of the polyphenol estimation
  pipeline
- **FDA-FDD V3.1** - All of FDA FDD descriptions

#### OUTPUTS

- **Diet_DII_foods_by_entry.csv** - Intake of 7 DII food categories by
  participant recall or record

## SCRIPT

Load packages

``` r
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
suppressMessages(library(readxl))
```

Load data

``` r
# Load provided file paths
source("provided_files.R")

# Load Dietary data that has been disaggregated and connected to FooDB
input_mapped = vroom::vroom('outputs/Diet_Disaggregated_mapped.csv.bz2', 
                            show_col_types = FALSE)

# Load FDA-FDD 3.1
fdd = read_xlsx(FDD_file) %>%
  dplyr::distinct(`Basic Ingredient Description`) %>%
  dplyr::rename(fdd_ingredient = 1) 
```

### Specify grouping variables

Column grouping depends on whether output is from a record or recall.

``` r
if ("RecallNo" %in% names(input_mapped)) {
  group_vars = c("subject", "RecallNo", "component")
  
} else if ("RecordNo" %in% names(input_mapped)) {
  group_vars = c("subject", "RecordNo", "RecordDayNo", "component")
  
} else {
  stop("Data must contain RecallNo or RecordNo.")
}
```

### Isolate FDD descriptions for each food group

Ingredient description must contain only one ingredient

``` r
garlic = fdd %>%
  dplyr::filter(grepl("garlic", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'GARLIC')

ginger = fdd  %>%
  dplyr::filter(grepl("ginger", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'GINGER')

onions = fdd %>%
  dplyr::filter(grepl("onion", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'ONION')

turmeric = fdd %>%
  dplyr::filter(grepl("turmeric", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'TURMERIC')

tea = fdd %>%
  dplyr::filter(grepl("tea", fdd_ingredient, ignore.case = TRUE)) %>%
  # Ensure no herbal teas are included
  dplyr::filter(grepl("black|oolong|green", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'TEA')

pepper = fdd %>%
  dplyr::filter(grepl("pepper", fdd_ingredient, ignore.case = TRUE)) %>%
  # Ensure we are getting just spices and not fresh peppers
  dplyr::filter(grepl("spices", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'PEPPER')

# Thyme or oregano
thymeoregano = fdd %>%
  dplyr::filter(grepl("thyme|oregano", fdd_ingredient, ignore.case = TRUE)) %>%
  dplyr::mutate(component = 'THYME')

# SAFFRON AND ROSEMARY do not exist in FDD V3.1
# rosemary = fdd %>% dplyr::filter(grepl("rosemary", fdd_ingredient, ignore.case = TRUE)) %>% dplyr::mutate(component = "ROSEMARY")
# saffron = fdd %>% dplyr::filter(grepl("saffron", fdd_ingredient, ignore.case = TRUE)) %>% dplyr::mutate(component = 'SAFFRON')
```

Merge the foods together into a singular dataframe

``` r
DII_foods = garlic %>%
  dplyr::full_join(ginger) %>%
  dplyr::full_join(onions) %>%
  dplyr::full_join(turmeric) %>%
  dplyr::full_join(tea) %>%
  dplyr::full_join(pepper) %>%
  dplyr::full_join(thymeoregano)
  # These can be added with future updates
  # dplyr::full_join(saffron) %>%
  # dplyr::full_join(rosemary)
```

### Derive food component intakes

``` r
component_sums = input_mapped %>%
  # Extract relevant DII foods
  dplyr::filter(fdd_ingredient %in% DII_foods$fdd_ingredient) %>%
  # let's keep the columns we will need to simplify our df
  dplyr::select(c(subject,
                  any_of(c("RecallNo", "RecordNo", "RecordDayNo")),
                  fdd_ingredient, FoodAmt_Ing_g)) %>%
  # Merge the component name
  dplyr::left_join(DII_foods, by = 'fdd_ingredient') %>%
  # Add component ingredient intakes together
  dplyr::group_by(across(all_of(group_vars))) %>%
  dplyr::mutate(component_sum = sum(FoodAmt_Ing_g, na.rm = TRUE)) %>%
  dplyr::ungroup() %>%
  # Keep distinct entries
  dplyr::distinct(across(all_of(group_vars)), .keep_all = TRUE)%>%
  # Remove food name and intakes now that we have the total component intake
  dplyr::select(-c(fdd_ingredient, FoodAmt_Ing_g)) %>%
  # Make Wide
  tidyr::pivot_wider(names_from = component, values_from = component_sum) 

# In smaller groups, some foods may be missing.
food_list = c("GARLIC", "GINGER", "ONION", "TURMERIC", "TEA", "PEPPER", "THYME")
missing_cols = setdiff(food_list, names(component_sums))
# Add any missing colums as 0
component_sums[missing_cols] =0
```

### Export Food Intake Amounts for DII Calculation

``` r
vroom::vroom_write(component_sums, 'outputs/Diet_DII_foods_by_entry.csv', delim = ",")
```

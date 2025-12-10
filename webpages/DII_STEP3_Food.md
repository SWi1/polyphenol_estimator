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

- **Recall_Disaggregated_mapped.csv.bz2** - Disaggregated dietary data,
  mapped to FooDB foods, From Step 2 of the polyphenol estimation
  pipeline
- **FDA-FDD V3.1** - All of FDA FDD descriptions

#### OUTPUTS

- **Recall_DII_foods_by_recall.csv** - Intake of 7 DII food categories
  by participant recall

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
input_mapped = vroom::vroom('outputs/Recall_Disaggregated_mapped.csv.bz2', 
                            show_col_types = FALSE)

# Load FDA-FDD 3.1
fdd = read_xlsx(FDD_file) %>%
  distinct(`Basic Ingredient Description`) %>%
  rename(fdd_ingredient = 1) 
```

### Isolate FDD descriptions for each food group

Ingredient description must contain only one ingredient

``` r
garlic = fdd %>%
  filter(grepl("garlic", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'GARLIC')

ginger = fdd  %>%
  filter(grepl("ginger", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'GINGER')

onions = fdd %>%
  filter(grepl("onion", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'ONION')

turmeric = fdd %>%
  filter(grepl("turmeric", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'TURMERIC')

tea = fdd %>%
  filter(grepl("tea", fdd_ingredient, ignore.case = TRUE)) %>%
  # Ensure no herbal teas are included
  filter(grepl("black|oolong|green", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'TEA')

pepper = fdd %>%
  filter(grepl("pepper", fdd_ingredient, ignore.case = TRUE)) %>%
  # Ensure we are getting just spices and not fresh peppers
  filter(grepl("spices", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'PEPPER')

# Thyme or oregano
thymeoregano = fdd %>%
  filter(grepl("thyme|oregano", fdd_ingredient, ignore.case = TRUE)) %>%
  mutate(component = 'THYME')

# SAFFRON AND ROSEMARY do not exist in FDD V3.1
# rosemary = fdd %>% filter(grepl("rosemary", fdd_ingredient, ignore.case = TRUE)) %>% mutate(component = "ROSEMARY")
# saffron = fdd %>% filter(grepl("saffron", fdd_ingredient, ignore.case = TRUE)) %>% mutate(component = 'SAFFRON')
```

Merge the foods together into a singular dataframe

``` r
DII_foods = garlic %>%
  full_join(ginger) %>%
  full_join(onions) %>%
  full_join(turmeric) %>%
  full_join(tea) %>%
  full_join(pepper) %>%
  full_join(thymeoregano)
  # These can be added with future updates
  # full_join(saffron) %>%
  # full_join(rosemary)
```

### Derive food component intakes

``` r
component_sums = input_mapped %>%
  # Extract relevant DII foods
  filter(fdd_ingredient %in% DII_foods$fdd_ingredient) %>%
  # let's keep the columns we will need to simplify our df
  select(c(subject, RecallNo, fdd_ingredient, FoodAmt_Ing_g)) %>%
  # Merge the component name
  left_join(DII_foods, by = 'fdd_ingredient') %>%
  # Add component ingredient intakes together
  group_by(subject, RecallNo, component) %>%
  mutate(component_sum = sum(FoodAmt_Ing_g)) %>%
  ungroup() %>%
  # Keep distinct entries
  distinct(subject, RecallNo, component, .keep_all = TRUE) %>%
  # Remove food name and intakes now that we have the total component intake
  select(-c(fdd_ingredient, FoodAmt_Ing_g)) %>%
  # Make Wide
  pivot_wider(names_from = component, values_from = component_sum)
```

### Export Food Intake Amounts for DII Calculation

``` r
vroom::vroom_write(component_sums, 'outputs/Recall_DII_foods_by_recall.csv', delim = ",")
```

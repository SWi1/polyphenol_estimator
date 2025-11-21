---
layout: default
title: Step 3d Summary - Food Contributors
parent: Polyphenol Estimation Pipeline
nav_order: 7
has_toc: true
---

- [Food Contributors to Total Polyphenol
  Intake](#food-contributors-to-total-polyphenol-intake)
  - [INPUTS](#inputs)
  - [OUTPUTS](#outputs)
- [SCRIPTS](#scripts)
  - [Food Consumption Counts](#food-consumption-counts)
  - [Total daily Polyphenol Intake Numbers BY
    RECALL](#total-daily-polyphenol-intake-numbers-by-recall)
  - [Total daily Polyphenol Intake Numbers AVERAGE FOR
    SUBJECT](#total-daily-polyphenol-intake-numbers-average-for-subject)
  - [Obtain food contributors to total polyphenol
    intake](#obtain-food-contributors-to-total-polyphenol-intake)

## Food Contributors to Total Polyphenol Intake

This script examines food contributors to total polyphenol intake.

### INPUTS

- **Input_Disaggregated_mapped.csv.bz2**; Dissagregated dietary data,
  mapped to FooDB foods
- **Input_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary
  data, mapped to FooDB foods and polyphenol content
- **Input_total_nutrients.csv** - total daily nutrient data to go with
  dietary data.

### OUTPUTS

- **Input_FooDB_polyphenol_food_contributors.csv**

## SCRIPTS

``` r
# Load packages
library(tidyverse)
```

``` r
# Load user-defined input paths
source("specify_inputs.R")

# Foods Mapped
input_mappings = vroom::vroom('outputs/Input_Disaggregated_mapped.csv.bz2',
                              show_col_types = FALSE)

# Foods Mapped with content
input_polyphenol_content = vroom::vroom('outputs/Input_FooDB_polyphenol_content.csv.bz2',
                                        show_col_types = FALSE)
input_kcal = vroom::vroom('outputs/Input_total_nutrients.csv', show_col_types = FALSE) %>%
  # Ensure consistent KCAL naming whether ASA24 or NHANES
  rename_with(~ "Total_KCAL", .cols = any_of(c("Total_KCAL", # Specific to ASA24
                                               "Total_DRXIKCAL"))) %>%  # Specific to NHANES
  select(c(subject, RecallNo, Total_KCAL))

# Merge the two files
input_polyphenol_kcal = left_join(input_polyphenol_content, input_kcal)
```

    ## Joining with `by = join_by(subject, RecallNo)`

### Food Consumption Counts

This tells us how many times a food was reported and then if we see all
participants consume a food.

``` r
food_counts = input_mappings %>%
  # Every time a subject consumed food, how much of it in total did they eat? 
  # How many instances did they eat this food in one day?
  group_by(subject, RecallNo, fdd_ingredient) %>%
  summarise(
    amount_consumed_g = sum(FoodAmt_Ing_g, na.rm =TRUE),
    times_consumed = n(),
    .groups = "drop") %>%
  
  # Across the cohort summary
  group_by(fdd_ingredient) %>%
  summarise(
    # How many instances was this food seen
    total_times_consumed = sum(times_consumed),
    
    # How many subjects consumed this food
    n_subjects = n_distinct(subject),
    
    # Information about the Ingredient consumed
    min_amount_consumed_g = min(amount_consumed_g),
    average_amount_consumed_g = mean(amount_consumed_g),
    median_amount_consumed_g= median(amount_consumed_g),
    max_amount_consumed_g = max(amount_consumed_g),
    
    .groups = "drop") %>%
  arrange(desc(total_times_consumed))
```

### Total daily Polyphenol Intake Numbers BY RECALL

``` r
content_by_recall_food = input_polyphenol_kcal %>%
  
  # Sum by Recall and Participant
  group_by(subject, RecallNo, fdd_ingredient) %>%
  mutate(pp_recallsum_mg = sum(pp_consumed, na.rm = TRUE),
         pp_recallsum_mg1000kcal = pp_recallsum_mg/(Total_KCAL/1000)) %>%
  ungroup() %>%
  distinct(subject, RecallNo, fdd_ingredient, .keep_all = TRUE) %>%
  select(c(subject, RecallNo, fdd_ingredient, pp_recallsum_mg, Total_KCAL, pp_recallsum_mg1000kcal))
```

### Total daily Polyphenol Intake Numbers AVERAGE FOR SUBJECT

``` r
content_by_subject_food = content_by_recall_food %>%
  
  # Average by Participant
  group_by(subject, fdd_ingredient) %>%
  mutate(pp_average_mg = mean(pp_recallsum_mg, na.rm = TRUE),
         kcal_average = mean(Total_KCAL, na.rm = TRUE),
         pp_average_mg_1000kcal = pp_average_mg/(kcal_average/1000)) %>%
  ungroup() %>%
  distinct(subject, fdd_ingredient, .keep_all = TRUE) %>%
  select(c(subject, fdd_ingredient, pp_average_mg, kcal_average, pp_average_mg_1000kcal)) 
```

### Obtain food contributors to total polyphenol intake

``` r
content_by_food = content_by_subject_food %>%
  
  # Average by food
  group_by(fdd_ingredient) %>%
  mutate(food_pp_average_mg1000kcal = mean(pp_average_mg_1000kcal, na.rm = TRUE)) %>%
  ungroup() %>%
  distinct(fdd_ingredient, .keep_all = TRUE) %>%
  select(c(fdd_ingredient, food_pp_average_mg1000kcal)) %>%
  left_join(food_counts, by = "fdd_ingredient") %>%
  arrange(desc(food_pp_average_mg1000kcal), desc(n_subjects))

# Export food contributors file 
vroom::vroom_write(content_by_food, 'outputs/Input_FooDB_polyphenol_food_contributors.csv')
```

 ---
layout: default
title: Step 3a Summary - Total
parent: Polyphenol Estimator
nav_order: 4
has_toc: true
---                             
                              
- [Calculate Total Polypenol
  Intakes](#calculate-total-polypenol-intakes)
- [SCRIPTS](#scripts)
- [Total daily Polyphenol Intake Numbers BY
  RECALL](#total-daily-polyphenol-intake-numbers-by-recall)
- [Total daily Polyphenol Intake Numbers AVERAGE FOR
  SUBJECT](#total-daily-polyphenol-intake-numbers-average-for-subject)

## Calculate Total Polypenol Intakes

This script calculates total polyphenol intake (mg, mg/1000kcal) for
provided dietary data.

#### INPUTS

- **Recall_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary
  data, mapped to FooDB polyphenol content, at the compound-level
- **Recall_total_nutrients.csv** - total daily nutrient data to go with
  dietary data.

#### OUTPUTS

- **summary_total_intake_by_subject.csv**
- **summary_total_intake_by_recall.csv**

## SCRIPTS

``` r
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
```

``` r
# Load provided file paths
source("provided_files.R")

# Load dietary data mapped to polyphenol content
input_polyphenol_content = vroom::vroom('outputs/Recall_FooDB_polyphenol_content.csv.bz2',
                                        show_col_types = FALSE)

input_kcal = vroom::vroom('outputs/Recall_total_nutrients.csv', show_col_types = FALSE) %>%
  # Ensure consistent KCAL naming whether ASA24 or NHANES
  rename_with(~ "Total_KCAL", .cols = any_of(c("Total_KCAL", # Specific to ASA24
                                               "Total_DRXIKCAL"))) %>%  # Specific to NHANES
  select(c(subject, RecallNo, Total_KCAL))

# Merge the two files
input_polyphenol_kcal = left_join(input_polyphenol_content, input_kcal)
```

    ## Joining with `by = join_by(subject, RecallNo)`

## Total daily Polyphenol Intake Numbers BY RECALL

``` r
content_by_recall = input_polyphenol_kcal %>%
  
  # Sum by Recall and Participant
  group_by(subject, RecallNo) %>%
  mutate(pp_recallsum_mg = sum(pp_consumed, na.rm = TRUE),
         pp_recallsum_mg1000kcal = pp_recallsum_mg/(Total_KCAL/1000)) %>%
  ungroup() %>%
  distinct(subject, RecallNo, .keep_all = TRUE) %>%
  select(c(subject, RecallNo, pp_recallsum_mg, Total_KCAL, pp_recallsum_mg1000kcal))

# Write Output
vroom::vroom_write(content_by_recall, "outputs/summary_total_intake_by_recall.csv", delim = ",")
```

## Total daily Polyphenol Intake Numbers AVERAGE FOR SUBJECT

``` r
content_by_subject = content_by_recall %>%
  
  # Average by Participant
  group_by(subject) %>%
  mutate(pp_average_mg = mean(pp_recallsum_mg, na.rm = TRUE),
         kcal_average = mean(Total_KCAL, na.rm = TRUE),
         pp_average_mg_1000kcal = pp_average_mg/(kcal_average/1000)) %>%
  ungroup() %>%
  distinct(subject, .keep_all = TRUE) %>%
  select(c(subject, pp_average_mg, kcal_average, pp_average_mg_1000kcal))

# Write Output
vroom::vroom_write(content_by_subject, "outputs/summary_total_intake_by_subject.csv", delim = ",")
```

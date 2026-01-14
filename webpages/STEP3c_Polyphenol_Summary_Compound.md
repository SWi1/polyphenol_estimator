---
layout: default
title: Step 3c Summary - Compound
parent: Polyphenol Estimator
nav_order: 6
has_toc: true
---                              
                              
- [Calculate Compound-Level Polypenol
  Intakes](#calculate-compound-level-polypenol-intakes)
- [SCRIPTS](#scripts)
  - [Daily Class Polyphenol Intake Numbers BY
    RECALL](#daily-class-polyphenol-intake-numbers-by-recall)
  - [Daily Class Intakes by Subject](#daily-class-intakes-by-subject)

## Calculate Compound-Level Polypenol Intakes

This script calculates compound-level polyphenol intake (mg,
mg/1000kcal) for provided dietary data.

#### INPUTS

- **Recall_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary
  data, mapped to FooDB polyphenol content, at the compound-level
- **Recall_total_nutrients.csv** - total daily nutrient data to go with
  dietary data.

#### OUTPUTS

- **summary_compound_intake_by_recall.csv**, polyphenol compound intakes
  by recall for each participant
- **summary_compound_intake_by_subject.csv**, polyphenol compound
  intakes for each participant, provided in long format (compounds as
  rows)
- **summary_compound_intake_by_subject_wide.csv**, polyphenol compound
  intakes for each participant, provided in wide format (compounds as
  columns)

## SCRIPTS

``` r
# Load packages
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
```

``` r
# Load provided file paths
source("provided_files.R")

#Content and kcal data
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

### Daily Class Polyphenol Intake Numbers BY RECALL

``` r
compound_intakes_recall = input_polyphenol_kcal%>%
  
  #Group by Taxonomic Class
  group_by(subject, RecallNo, compound_public_id) %>%
  
  #gets the sum of each compound for each participant's recall
  mutate(compound_intake_mg = sum(pp_consumed, na.rm = TRUE)) %>% 
  select(c(subject, RecallNo, compound_public_id, compound_name, compound_intake_mg, Total_KCAL)) %>%
  ungroup()%>%
  
  #Remove duplicates since we've summed each polyphenol per recall
  distinct(subject, RecallNo, compound_public_id, .keep_all = TRUE)  %>%
  
  #Filter out missing compounds, this is for foods that did not map
  filter(!is.na(compound_public_id)) %>%
  
  #Standardize Intakes to caloric intake
  mutate(compound_intake_mg1000kcal = compound_intake_mg/(Total_KCAL/1000))

# Write output
vroom::vroom_write(compound_intakes_recall,
                   "outputs/summary_compound_intake_by_recall.csv", delim = ",")
```

### Daily Class Intakes by Subject

``` r
# First average caloric intakes
kcal_subject = input_kcal %>%
  group_by(subject) %>%
  summarise(avg_Total_KCAL = mean(Total_KCAL, na.rm = TRUE))

# Then let's average the class intakes
compound_intakes_subject = compound_intakes_recall %>%
  # We will replace these with the subject average
  select(-c(Total_KCAL, compound_intake_mg1000kcal)) %>%
  
  #Average polyphenol intake across recalls for each compound
  group_by(subject, compound_public_id) %>%
  mutate(Avg_compound_intake_mg = mean(compound_intake_mg)) %>%
  ungroup() %>%
  
  #Remove duplicates
  distinct(subject, compound_public_id, .keep_all = TRUE) %>%
  select(-compound_intake_mg) %>%
  
  # Add kcal data
  left_join(kcal_subject, by = 'subject') %>%
  
  # Standardize to caloric intake
  mutate(compound_intake_mg1000kcal = Avg_compound_intake_mg/(avg_Total_KCAL/1000)) 

# Write Output
vroom::vroom_write(compound_intakes_subject,
                   "outputs/summary_compound_intake_by_subject.csv", delim = ",")
```

Available for users who prefer a wide format

``` r
compound_intakes_subject_wide = compound_intakes_subject %>%
  
  #Transpose dataframe where each column is a participant
  # columns are the compound_public_id for simplicity
  pivot_wider(id_cols = subject, names_from = compound_public_id, 
              values_from = compound_intake_mg1000kcal, values_fill = 0)

# Write Output
vroom::vroom_write(compound_intakes_subject_wide,
                   "outputs/summary_compound_intake_by_subject_wide.csv", delim = ",")
```

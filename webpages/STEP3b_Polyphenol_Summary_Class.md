---
layout: default
title: Step 3b Summary - Class
parent: Polyphenol Estimation Pipeline
nav_order: 5
has_toc: true
---                              
                              
- [Calculate Class-Level Polypenol
  Intakes](#calculate-class-level-polypenol-intakes)
- [SCRIPTS](#scripts)
  - [Specify grouping variables](#specify-grouping-variables)
  - [Daily Class Polyphenol Intake Numbers BY ENTRY
    (Record/Recall)](#daily-class-polyphenol-intake-numbers-by-entry-recordrecall)
  - [Daily Class Intakes by SUBJECT](#daily-class-intakes-by-subject)

## Calculate Class-Level Polypenol Intakes

This script calculates class polyphenol intake (mg, mg/1000kcal) for
provided dietary data.

#### INPUTS

- **Diet_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary data,
  mapped to FooDB polyphenol content, at the compound-level
- **Diet_total_nutrients.csv** - total daily nutrient data to go with
  dietary data.
- **Diet_polyphenol_classtax_3072.csv** - class taxonomy is derived from
  FooDB which uses ClassyFire, an automated chemical taxonomic
  classification application based on chemical structure

#### OUTPUTS

- **summary_class_intake_by_entry.csv**, polyphenol class intakes by
  recall for each participant
- **summary_class_intake_by_subject.csv**, polyphenol class intakes for
  each participant, provided in wide format (classes as rows)
- **summary_class_intake_by_subject_wide.csv**, polyphenol class intakes
  for each participant, provided in wide format (classes as columns)

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

#Content and kcal data
input_polyphenol_content = vroom::vroom('outputs/Diet_FooDB_polyphenol_content.csv.bz2',
                                        show_col_types = FALSE)

input_kcal = vroom::vroom('outputs/Diet_total_nutrients.csv', show_col_types = FALSE) %>%
  # Ensure consistent KCAL naming whether ASA24 or NHANES
  dplyr::rename_with(~ "Total_KCAL", .cols = any_of(c("Total_KCAL", # Specific to ASA24
                                               "Total_DRXIKCAL"))) %>%  # Specific to NHANES
  dplyr::select(c(subject, 
            # Ensures we pull correct columns for record or recall
           any_of(c("RecallNo", "RecordNo", "RecordDayNo")),
           Total_KCAL))

# Class taxonomy for FooDB compounds
class_tax = vroom::vroom(class_tax, show_col_types = FALSE) %>%
  dplyr::select(c(compound_public_id, class))

# Merge the two files
input_polyphenol_kcal = dplyr::left_join(input_polyphenol_content, input_kcal)  %>%
  dplyr::left_join(class_tax, by = "compound_public_id")
```

    ## Joining with `by = join_by(subject, RecallNo)`

### Specify grouping variables

Column grouping depends on whether output is from a record or recall.

``` r
if ("RecallNo" %in% names(input_polyphenol_kcal)) {
  group_vars = c("subject", "RecallNo", "class")
  
} else if ("RecordNo" %in% names(input_polyphenol_kcal)) {
  group_vars = c("subject", "RecordNo", "RecordDayNo", "class")
  
} else {
  stop("Data must contain RecallNo or RecordNo.")
}
```

### Daily Class Polyphenol Intake Numbers BY ENTRY (Record/Recall)

``` r
class_intakes_entry = input_polyphenol_kcal %>%
  
  # Recall - Sum by Subject, Recall
  # Record - Sum by Subject, Record Number, Day in Record Number
  # Both recall and record group class.
  dplyr::group_by(across(all_of(group_vars))) %>%
  
  #gets the sum of each compound for each participant's recall
  dplyr::mutate(class_intake_mg = sum(pp_consumed, na.rm = TRUE)) %>% 
  dplyr::select(c(subject, 
                  any_of(c("RecallNo", "RecordNo", "RecordDayNo")),
                  class, class_intake_mg, Total_KCAL)) %>%
  dplyr::ungroup()%>%
  
  #Remove duplicates since we've summed each polyphenol per recall
  dplyr::distinct(across(all_of(group_vars)), .keep_all = TRUE) %>%
  
  #Filter out missing class, this is for foods that did not map
  dplyr::filter(!is.na(class)) %>%
  
  #Standardize Intakes to caloric intake
  dplyr::mutate(class_intake_mg1000kcal = class_intake_mg/(Total_KCAL/1000))

vroom::vroom_write(class_intakes_entry, "outputs/summary_class_intake_by_entry.csv", delim = ",")
```

### Daily Class Intakes by SUBJECT

``` r
# First average caloric intakes
kcal_subject = input_kcal %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(avg_Total_KCAL = mean(Total_KCAL, na.rm = TRUE))

# Then let's average the class intakes
class_intakes_subject = class_intakes_entry %>%
  # We will replace these with the subject average
  dplyr::select(-c(Total_KCAL,class_intake_mg1000kcal)) %>%
  
  #Average polyphenol intake across recalls for each class
  dplyr::group_by(subject, class) %>%
  dplyr::mutate(Avg_class_intake_mg = mean(class_intake_mg)) %>%
  dplyr::ungroup() %>%
  
  #Remove duplicates
  dplyr::distinct(subject, class, .keep_all = TRUE) %>%
  dplyr::select(-class_intake_mg) %>%
  
  # Add kcal data
  dplyr::left_join(kcal_subject, by = 'subject') %>%
  dplyr::mutate(class_intake_mg1000kcal = Avg_class_intake_mg/(avg_Total_KCAL/1000)) 

vroom::vroom_write(class_intakes_subject,
                   "outputs/summary_class_intake_by_subject.csv", delim = ",")
```

Available for users who prefer wide format for their analyses
(e.g. machine learning).

``` r
class_intakes_subject_wide = class_intakes_subject %>%
  
  #Transpose dataframe where each column is a participant
  tidyr::pivot_wider(id_cols = subject, names_from = class, 
              values_from = class_intake_mg1000kcal, values_fill = 0)

vroom::vroom_write(class_intakes_subject_wide,
                   "outputs/summary_class_intake_by_subject_wide.csv", delim = ",")
```

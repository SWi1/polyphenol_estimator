---
layout: default
title: Step 2 Polyphenol subclasses
parent: DII Calculation
nav_order: 2
has_toc: true
---                              
                              
- [Calculate DII Polyphenol
  Subclasses](#calculate-dii-polyphenol-subclasses)
- [SCRIPT](#script)
  - [Filter in relevant DII subclass
    polyphenols](#filter-in-relevant-dii-subclass-polyphenols)
  - [Specify grouping variables](#specify-grouping-variables)
  - [SUM subclass intake](#sum-subclass-intake)
  - [Export Polyphenol Subclass Intakes for DII
    Calculation](#export-polyphenol-subclass-intakes-for-dii-calculation)

## Calculate DII Polyphenol Subclasses

This script takes your data that has been mapped to FooDB polyphenol
content, extracts compounds categorized under the six required DII
subclasses (flavan-3-ols, Flavones, Flavonols, Flavonones,
Anthocyanidins, Isoflavones), and calculates the total intake of these
subclasses per participant recall or record.

#### INPUTS

- **Diet_FooDB_polyphenol_content.csv.bz2**: Disaggregated dietary data,
  mapped to FooDB polyphenol content, at the compound-level
- **FooDB_DII_polyphenol_list.csv** - Polyphenols under the six
  polyphenol subclasses required for DII-2014, Provided File

#### OUTPUTS

- **Diet_DII_subclass_by_entry.csv**: Sum DII polyphenol subclass
  content for each participant recall or record

## SCRIPT

Load packages

``` r
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
```

Load data

``` r
# Load provided file paths
source("provided_files.R")

# Load dietary data mapped to polyphenol content
input_polyphenol_content = vroom::vroom('outputs/Diet_FooDB_polyphenol_content.csv.bz2',
                                        show_col_types = FALSE)

# Polyphenol classifications
subclasses = vroom::vroom(FooDB_DII_subclasses, show_col_types = FALSE)
```

### Filter in relevant DII subclass polyphenols

``` r
input_polyphenol_content_filtered = input_polyphenol_content %>%
  dplyr::filter(compound_public_id %in% subclasses$compound_public_id) %>%
  # Merge the class information so subclasses are grouped correctly
  dplyr::left_join(subclasses)
```

    ## Joining with `by = join_by(compound_public_id, compound_name)`

### Specify grouping variables

Column grouping depends on whether output is from a record or recall.

``` r
if ("RecallNo" %in% names(input_polyphenol_content_filtered)) {
  group_vars = c("subject", "RecallNo", "component")
  
} else if ("RecordNo" %in% names(input_polyphenol_content_filtered)) {
  group_vars = c("subject", "RecordNo", "RecordDayNo", "component")
  
} else {
  stop("Data must contain RecallNo or RecordNo.")
}
```

### SUM subclass intake

The column `component` contains the DII category.

``` r
subclass_intakes = input_polyphenol_content_filtered %>%
  dplyr::group_by(across(all_of(group_vars))) %>%
  # Sum polyphenol category intake, mg by recall
  dplyr::mutate(component_sum = sum(pp_consumed)) %>%
  dplyr::ungroup() %>%
  # Keep distinct entries
  dplyr::distinct(across(all_of(group_vars)), .keep_all = TRUE) %>%
  # Minimize the number of columns for pivoting to wide format
  dplyr::select(c(subject,
                  any_of(c("RecallNo", "RecordNo", "RecordDayNo")),
                  component, component_sum)) %>%
  # pivot to wide version
  tidyr::pivot_wider(names_from = component, values_from = component_sum) %>%
  # Rename the columns to match the DII category names in the DietaryIndex function
  dplyr::rename(
    ISOFLAVONES = Isoflavones,
    "FLA3OL" = "Flavan-3-ols",
    "FLAVONES" = "Flavones",
    "FLAVONOLS" =  "Flavonols",
    "FLAVONONES" = "Flavanones",
    "ANTHOC" = "Anthocyanidins")
```

### Export Polyphenol Subclass Intakes for DII Calculation

``` r
vroom::vroom_write(subclass_intakes, 'outputs/Diet_DII_subclass_by_entry.csv', delim = ",")
```

---
layout: default
title: NHANES diet recalls
parent: Preparing Diet Data
nav_order: 2
has_toc: true
---

- [Prepare NHANES diet recall data](#prepare-nhanes-diet-recall-data)
- [SCRIPTS](#scripts)
  - [Extract 2021-2023 NHANES Data from CDC
    website](#extract-2021-2023-nhanes-data-from-cdc-website)
  - [Clean Column Names](#clean-column-names)
  - [Data Filtering](#data-filtering)
- [Export Data Files](#export-data-files)

## Prepare NHANES diet recall data

This is a tutorial to help users access NHANES dietary data for
downstream utilization in the polyphenol estimation pipeline. The R
scripts below walk you through how to directly download one cycle of
NHANES dietary data from the CDC website and perform several diet
cleaning steps. Users can directly download this code
[here](https://github.com/SWi1/polyphenol_pipeline/blob/main/scripts/preparing_diet_data_NHANES.Rmd)
and generate the same outputs by running the R code in RStudio.

**About NHANES**  
NHANES is a nationally representative sample of non-institutionalized
individuals in the United States. NHANES uses the Food and Nutrient
Database for Dietary Studies (FNDDS) to generate nutrient intakes from
food composition data. FNDDS is released every two-years in conjunction
with the What We Eat in America (WWEIA), NHANES dietary data release.
For each new version of FNDDS, foods/beverages, portions, and nutrient
values are reviewed and updated.

Users interested in analyzing multiple cycles of NHANES dietary data
should utilize cross-walks to harmonize changes in FNDDS foods and
beverages over different cycles. Crosswalk information is available in
the ‘Documentation’ File for each FNDDS release. Visit the USDA Food
Survey Research Group for more information
[here](https://www.ars.usda.gov/northeast-area/beltsville-md-bhnrc/beltsville-human-nutrition-research-center/food-surveys-research-group/docs/fndds-download-databases/).

#### INPUT

1.  **2021 - 2023 Demographic Data**
    - [Official Documentation &
      Codebook](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DEMO_L.htm)
2.  **2021 - 2023 Dietary Interview** - Featuring two separate diet
    recalls
    - [Official Documentation & Codebook- First
      Day](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DR1TOT_L.htm)
    - [Official Documentation & Codebook- Second
      Day](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DR2TOT_L.htm)
3.  **Dietary Interview Technical Support File - Food Codes**
    - [Official
      Documentation](https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DRXFCD_L.htm)

#### OUTPUT

- **NHANES_2021_2023_diet_adults.csv.bz2** - NHANES 2021-2023
  ingredient-level diet data, first and second recalls combined,
  filtered for adults \>=20 years old. Each participant has two complete
  recalls.
- **(Optional) NHANES_2021_2023_demographics_adults.csv.bz** - NHANES
  2021-2023 demographic data

## SCRIPTS

Load packages

``` r
# tidyverse: helps with data wrangling and visualization
# haven: loads SAS files
required = c("tidyverse", "haven")

# Loop to install and load packages
for (pkg in required) {
  # This will install the package if you do not already have it
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  # This will load the package so it's active for this R session
  library(pkg, character.only = TRUE)
}
```

### Extract 2021-2023 NHANES Data from CDC website

To analyze 2021-2023 NHANES dietary data, we need to pull down the
relevant files for our cycle of interest. An array of files from the
2021-2023 NHANES cycle are available from the CDC
[here](https://wwwn.cdc.gov/nchs/nhanes/continuousnhanes/default.aspx?Cycle=2021-2023),
but for our purposes, we will pull down several key files:

1.  **Demographic Data** - We will use this data to filter the number of
    individuals we analyze.
2.  **Dietary Interview** - “Individual Foods, First Day” and
    “Individual Foods, Second Day” - Diet data is stored in separate
    files which we will combine later.
3.  **Dietary Interview Technical Support File - Food Codes** - Contains
    three columns (food codes, a short food description, and a long food
    description)

``` r
# 1. Demographic data
demo_data = read_xpt('https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DEMO_L.xpt')

# 2. Dietary Interview Data
recall1 = read_xpt("https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DR1IFF_L.xpt")
recall2 = read_xpt("https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DR2IFF_L.xpt")

# 3. Food Codes
diet_codes = read_xpt("https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/2021/DataFiles/DRXFCD_L.xpt")
```

**Checkpoint**: How many participants (`SEQN`) are in our starting
files?

    ## 2021-2023 demographic file, n = 11933
    ## 2021-2023 diet recall 1, n = 6751

### Clean Column Names

Many columns in these NHANES recall files are labelled with “DR1” or
“DR2” which denote the recall they came from. Since we want to analyze
both recalls, it makes sense to convert these labels so they are no
longer specific to the recall and we can merge dataframes together (Ex:
`DR1DBIH` and `DR2DBIH` turn into `DRXDBIH`). To make sure we still know
which recall the data came from, we can create a new column specifying
this information.

``` r
recall1_clean = recall1 %>%
  # replace column recall labels
  rename_with(~ sub("^DR1", "DRX", .x), starts_with("DR1")) %>%
  # Create Recall Column
  mutate(RecallNo = 1)

# Repeat for Recall 2
recall2_clean = recall2 %>%
  rename_with(~ sub("^DR2", "DRX", .x), starts_with("DR2")) %>%
  mutate(RecallNo = 2)
```

Now that the columns within our files have been cleaned, we can merge
them together! We can also merge in food descriptions from our
`diet_codes` dataframe.

``` r
recall_merge_clean = full_join(recall1_clean, recall2_clean) %>%
  # Merge food descriptions into recall data, Column names are not exact, so linkage is provided.
  left_join(diet_codes, by = c("DRXIFDCD" = "DRXFDCD")) %>%
  # Move RecallNo Column up
  relocate(RecallNo, .after = SEQN) %>%
  # Move Food Descriptions after food code
  relocate(DRXFCSD, DRXFCLD, .after = DRXIFDCD)
```

    ## Joining with `by = join_by(SEQN, WTDRD1, WTDR2D, DRXILINE, DRXDRSTZ, DRXEXMER,
    ## DRABF, DRDINT, DRXDBIH, DRXDAY, DRXLANG, DRXCCMNM, DRXCCMTX, DRX_020, DRX_030Z,
    ## DRXFS, DRX_040Z, DRXIFDCD, DRXIGRMS, DRXIKCAL, DRXIPROT, DRXICARB, DRXISUGR,
    ## DRXIFIBE, DRXITFAT, DRXISFAT, DRXIMFAT, DRXIPFAT, DRXICHOL, DRXIATOC, DRXIATOA,
    ## DRXIRET, DRXIVARA, DRXIACAR, DRXIBCAR, DRXICRYP, DRXILYCO, DRXILZ, DRXIVB1,
    ## DRXIVB2, DRXINIAC, DRXIVB6, DRXIFOLA, DRXIFA, DRXIFF, DRXIFDFE, DRXICHL,
    ## DRXIVB12, DRXIB12A, DRXIVC, DRXIVD, DRXIVK, DRXICALC, DRXIPHOS, DRXIMAGN,
    ## DRXIIRON, DRXIZINC, DRXICOPP, DRXISODI, DRXIPOTA, DRXISELE, DRXICAFF, DRXITHEO,
    ## DRXIALCO, DRXIMOIS, DRXIS040, DRXIS060, DRXIS080, DRXIS100, DRXIS120, DRXIS140,
    ## DRXIS160, DRXIS180, DRXIM161, DRXIM181, DRXIM201, DRXIM221, DRXIP182, DRXIP183,
    ## DRXIP184, DRXIP204, DRXIP205, DRXIP225, DRXIP226, RecallNo)`

### Data Filtering

With the recalls now cleaned and merged into a singular dataframe, we
will apply several data filtering steps to reduce the number of
participants we will analyze.

1.  Include adults aged 20+ years old. We will leverage the demographic
    file (`RIDAGEYR`) to do this.
2.  Include participants who completed two recalls (`DRDINT`)
3.  Include participants who had dietary recalls that passed quality
    control (Specific by recall: `DR1DRSTZ`, `DR2DRSTZ`).

- 1, Reliable and met the minimum criteria
- 2, Not reliable or not met the minimum criteria
- 4, Reported consuming breast-milk  
- 5, Not done
- ., Missing

**Note**: This is not an exhaustive list of data filtering steps for 24-hour recall data. Users may want to filter for specific populations or perform diet cleaning steps (e.g. Nutrient or Portion Outliers). Diet cleaning cut points based off NHANES data are provided in Appendix A of the CDC's ["Reviewing and Cleaning ASA24 Data"](https://epi.grants.cancer.gov/asa24/resources/asa24-data-cleaning-2020.pdf).

``` r
# Adults we want to include
demo_adults = demo_data %>%
  filter(RIDAGEYR >= 20)

# Let us apply our filters
diet_data_filtered = recall_merge_clean %>%
  # Include only adults 20+
  filter(SEQN %in% demo_adults$SEQN) %>%
  # Include only participants who completed two recalls
  filter(DRDINT == 2) %>%
  # Include recalls that passed QC 
  filter(DRXDRSTZ == 1) %>%
  # Double-check that we have two recalls per participant
  # Some people can escape the above filtering steps
  group_by(SEQN) %>%
  filter(n_distinct(RecallNo) == 2) %>%
  ungroup()
```

**Checkpoint**: How many participants (`SEQN`) remain after filtering?

    ## Participants post-filtering, n = 4284

## Export Data Files

Given the number of entries, we will compress this file to reduce file
size.

``` r
vroom::vroom_write(diet_data_filtered,
                   'user_inputs/NHANES_2021_2023_diet_adults.csv.bz2', delim = ",")

# Optional for users who want to keep the filtered demographic data
#vroom::vroom_write(demo_adults, 'user_inputs/NHANES_2021_2023_demographics_adults.csv.bz2', , delim = ",")
```

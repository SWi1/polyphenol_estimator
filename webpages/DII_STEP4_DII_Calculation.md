---
layout: default
title: Step 4 42-component DII
parent: DII Calculation
nav_order: 4
has_toc: true
---                              
                              
- [Calculate 42-component Dietary Inflammatory
  Index](#calculate-42-component-dietary-inflammatory-index)
- [SCRIPT](#script)
  - [Merge calculations with ASA24 Items
    file](#merge-calculations-with-asa24-items-file)
  - [Clean column names and prepare DII Category
    calculations](#clean-column-names-and-prepare-dii-category-calculations)
  - [BUILD DII calculation scores
    dataframe](#build-dii-calculation-scores-dataframe)
  - [Specify grouping variables](#specify-grouping-variables)
  - [Calculate DII Scores](#calculate-dii-scores)
  - [Export DII total and component scores for downstream
    use](#export-dii-total-and-component-scores-for-downstream-use)

## Calculate 42-component Dietary Inflammatory Index

This script adapts the DII_ASA24.R from the `dietaryindex` package to
include 14 additional components not included in the original
`dietaryindex` calculation (28 components). This updated calculation
relies upon previous calculations of eugenol intake, 6 polyphenol
subclasses, and 7 additional food groups (10 possible).

- Original Calculation,
  [DII_ASA24.R](https://github.com/jamesjiadazhan/dietaryindex/blob/main/R/DII_ASA24.R)
- New Components Added to 28 component DII calculation:
  - Compounds: EUGENOL, ISOFLAVONES, FLA3OL, FLAVONES, ANTHOC,
    FLAVONONES, FLAVONOLS
  - Foods: GARLIC, GINGER, ONION, PEPPER, TEA, TURMERIC, THYME

#### INPUTS

- **Diet_total_nutrients.csv**: Total nutrient intakes for unique
  participant and recall (or record) combination. Generated from step 1
  of the polyphenol estimation pipeline.
- **Diet_FooDB_DII_eugenol_by_entry.csv**: Sum eugenol intake for each
  participant recall or record
- **Diet_FooDB_DII_subclass_by_entry.csv**: Sum of 6 DII polyphenol
  subclass intakes for each participant recall
- **Diet_DII_foods_by_entry.csv** - Intake of 7 DII 2014 food categories
  by participant recall or record

#### OUTPUTS

- **summary_DII_final_scores_by_entry.csv** - Total DII scores and 42
  individual component scores

## SCRIPT

Load package

``` r
suppressMessages(library(dplyr))
suppressMessages(library(vroom))
suppressMessages(library(tidyr))
suppressMessages(library(stringr))
```

Load dietary test data

``` r
# Load dietary data
total_nut = vroom::vroom('outputs/Diet_total_nutrients.csv', show_col_types = FALSE) 

# Load DII calculation files
# eugenol intake
eugenol = vroom::vroom('outputs/Diet_DII_eugenol_by_entry.csv', show_col_types = FALSE) %>%
  # If dataframe is empty, ensure that file still merges
   mutate(across(any_of(c("RecallNo", "RecordNo", "RecordDayNo")), as.numeric))

# polyphenol subclass intakes
subclass = vroom::vroom('outputs/Diet_DII_subclass_by_entry.csv', show_col_types = FALSE) %>%
  # If dataframe is empty, ensure that file still merges
   mutate(across(any_of(c("RecallNo", "RecordNo", "RecordDayNo")), as.numeric))

# food intakes
DII_foods = vroom::vroom('outputs/Diet_DII_foods_by_entry.csv', show_col_types = FALSE) %>%
  # If dataframe is empty, ensure that file still merges
   mutate(across(any_of(c("RecallNo", "RecordNo", "RecordDayNo")), as.numeric))
```

### Merge calculations with ASA24 Items file

``` r
merge = total_nut %>%
  # Remove the total from names
  rename_with(~ gsub("^Total_", "", .x)) %>%
  left_join(eugenol) %>%
  left_join(subclass) %>%
  left_join(DII_foods)
```

    ## Joining with `by = join_by(subject, RecallNo)`
    ## Joining with `by = join_by(subject, RecallNo)`
    ## Joining with `by = join_by(subject, RecallNo)`

### Clean column names and prepare DII Category calculations

ASA24 and NHANES have different naming conventions, so let’s make sure
we can map easily between the two by standardizing the names.

``` r
mapping_df = tribble(
  ~new_name,    ~asa24_name, ~nhanes_name,
  "ALCOHOL",    "ALC",       "DRXIALCO",
  "VITB12",     "VB12",      "DRXIVB12",
  "VITB6",      "VB6",       "DRXIVB6",
  "BCAROTENE",  "BCAR",      "DRXIBCAR",
  "CAFF",       "CAFF",      "DRXICAFF",
  "CARB",       "CARB",      "DRXICARB",
  "CHOLES",     "CHOLE",     "DRXICHOL",
  "KCAL",       "KCAL",      "DRXIKCAL",
  "TOTALFAT",   "TFAT",      "DRXITFAT",
  "FIBER",      "FIBE",      "DRXIFIBE",
  "FOLICACID",  "FA",        "DRXIFA",
  "IRON",       "IRON",      "DRXIIRON",
  "MG",         "MAGN",      "DRXIMAGN",
  "MUFA",       "MFAT",      "DRXIMFAT",
  "NIACIN",     "NIAC",      "DRXINIAC",
  "P183",       "P183",      "DRXIP183",
  "P184",       "P184",      "DRXIP184",
  "P205",       "P205",      "DRXIP205",
  "P225",       "P225",      "DRXIP225",
  "P226",       "P226",      "DRXIP226",
  "P182",       "P182",      "DRXIP182",
  "P204",       "P204",      "DRXIP204",
  "PROTEIN",    "PROT",      "DRXIPROT",
  "PUFA",       "PFAT",      "DRXIPFAT",
  "RIBOFLAVIN", "VB2",       "DRXIVB2",
  "SATFAT",     "SFAT",      "DRXISFAT",
  "SE",         "SELE",      "DRXISELE",
  "THIAMIN",    "VB1",       "DRXIVB1",
  "VITA",       "VARA",      "DRXIVARA",
  "VITC",       "VC",        "DRXIVC",
  "VITD",       "VITD",      "DRXIVD",
  "VITE",       "ATOC",      "DRXIATOC",
  "ZN",         "ZINC",      "DRXIZINC")
```

Conditional Renaming: Flexible between NHANES and ASA24

``` r
# Detect if it's NHANES (any column starts with "DRX")
is_nhanes = any(startsWith(names(merge), "DRX"))

# Pick the right mapping
if (is_nhanes) {
  old_names = mapping_df$nhanes_name
} else {
  old_names = mapping_df$asa24_name
}

new_names = mapping_df$new_name

# Only keep columns that exist in merge
existing_idx = which(old_names %in% names(merge))
old_names = old_names[existing_idx]
new_names = new_names[existing_idx]

# Apply rename to relevant DII columns
merge_renamed = merge %>%
    dplyr::rename(!!!setNames(old_names, new_names))
```

Calculations required for DII

``` r
COHORT1 = merge_renamed %>%
  
        # Apply Calculations
        dplyr::mutate(
            CAFFEINE = CAFF / 1000, # convert to grams
            N3FAT = P183 + P184 + P205 + P225 + P226,
            N6FAT = P182 + P204,
            TURMERIC = TURMERIC * 1000,
            THYME = THYME * 1000) %>%  # Includes oregano
            # MISSING Components
            # ROSEMARY = ROSEMARY * 1000 # convert to mg
        dplyr::select(subject, any_of(c("RecallNo", "RecordNo", "RecordDayNo")),
                      ALCOHOL, VITB12, VITB6, BCAROTENE, 
                      CAFFEINE, CARB, CHOLES, KCAL, TOTALFAT, FIBER, FOLICACID,
                      IRON, MG, MUFA, NIACIN, N3FAT, N6FAT, PROTEIN, PUFA, 
                      RIBOFLAVIN, SATFAT, SE, THIAMIN, VITA,
                      VITC, VITD, VITE, ZN,
                      # NEW COMPONENTS
                      EUGENOL, ISOFLAVONES, FLA3OL, FLAVONES, ANTHOC,
                      FLAVONONES, FLAVONOLS, GARLIC, GINGER, ONION, PEPPER, 
                      TEA, TURMERIC, THYME)
                      # MISSING
                      # SAFFRON, ROSEMARY, TRANSFATS
```

Pivot to long format for ease of calculations

``` r
COHORT2 = COHORT1 %>%
  # Ensure diet features are numeric
  dplyr::mutate(across(-c(subject, any_of(c("RecallNo", "RecordNo", "RecordDayNo"))),
                       as.numeric)) %>%
  tidyr::pivot_longer(
    cols = -c(subject, any_of(c("RecallNo", "RecordNo", "RecordDayNo"))),
    names_to = "Variable",
    values_to = "Value")
```

### BUILD DII calculation scores dataframe

Derived from table 2 values in [Shivappa et
al.](https://pmc.ncbi.nlm.nih.gov/articles/PMC3925198/)

``` r
# DII Food Parameters
Variable = c("ALCOHOL", "VITB12", "VITB6", "BCAROTENE", "CAFFEINE", "CARB", 
             "CHOLES", "KCAL", "EUGENOL", "TOTALFAT", "FIBER", "FOLICACID", 
             "GARLIC", "GINGER", "IRON", "MG", "MUFA", "NIACIN", "N3FAT", "N6FAT",
             "ONION", "PROTEIN", "PUFA", "RIBOFLAVIN", "SAFFRON", "SATFAT", "SE",
             "THIAMIN", "TRANSFAT", "TURMERIC", "VITA", "VITC", "VITD", "VITE", "ZN",
             "TEA", "FLA3OL", "FLAVONES", "FLAVONOLS", "FLAVONONES", "ANTHOC",
             "ISOFLAVONES", "PEPPER", "THYME", "ROSEMARY")

# Raw inflammatory effect score
Overall_inflammatory_score = c(-0.278, 0.106, -0.365, -0.584, -0.11, 0.097, 0.11,
                               0.18, -0.14, 0.298, -0.663, -0.19, -0.412, -0.453,
                               0.032, -0.484, -0.009, -0.246, -0.436, -0.159, -0.301,
                               0.021, -0.337, -0.068, -0.14, 0.373, -0.191, -0.098,
                               0.229, -0.785, -0.401, -0.424, -0.446, -0.419, -0.313,
                               -0.536, -0.415, -0.616, -0.467, -0.25, -0.131, -0.593,
                               -0.131, -0.102, -0.013)

# Global daily mean intake (units/day)
Global_mean = c( 13.98, 5.15, 1.47, 3718, 8.05, 272.2, 279.4, 2056, 0.01, 71.4,
                 18.8, 273, 4.35, 59, 13.35, 310.1, 27, 25.9, 1.06, 10.8, 35.9, 
                 79.4, 13.88, 1.7, 0.37, 28.6, 67, 1.7, 3.15, 533.6, 983.9, 118.2, 
                 6.26, 8.73, 9.84, 1.69, 95.8, 1.55, 17.7, 11.7, 18.05, 1.2, 10,
                 0.33, 1)

# SD of intakes
SD = c(3.72, 2.7, 0.74, 1720, 6.67, 40, 51.2, 338, 0.08, 19.4, 4.9, 70.7, 2.9, 
       63.2, 3.71, 139.4, 6.1, 11.77, 1.06, 7.5, 18.4, 13.9, 3.76, 0.79, 1.78,
       8, 25.1, 0.66, 3.75, 754.3, 518.6, 43.46, 2.21, 1.49, 2.19,1.53, 85.9, 
       0.07, 6.79, 3.82, 21.14, 0.2, 7.07, 0.99, 15)

# Merge variables into one dataframe
DII_STD = data.frame(Variable, Overall_inflammatory_score, Global_mean, SD)
```

### Specify grouping variables

Column grouping depends on whether output is from a record or recall.

``` r
if ("RecallNo" %in% names(COHORT2)) {
  group_vars = c("subject", "RecallNo")
  
} else if ("RecordNo" %in% names(COHORT2)) {
  group_vars = c("subject", "RecordNo", "RecordDayNo")
  
} else {
  stop("Data must contain RecallNo or RecordNo.")
}
```

### Calculate DII Scores

``` r
  # Score calculation for DII
DII_scores = COHORT2 %>%
  # Add DII components for calculations
  dplyr::left_join(DII_STD, by = c("Variable")) %>%
  dplyr::mutate(
    Z_SCORE = (Value - Global_mean) / SD,
    PERCENTILE = pnorm(Z_SCORE) * 2 - 1,
    IND_DII_SCORE = PERCENTILE * Overall_inflammatory_score) %>%
  # Shift data back to wide format
  tidyr::pivot_wider(names_from = Variable, values_from = IND_DII_SCORE) %>%
  dplyr::group_by(across(all_of(group_vars))) %>%
  # Summarize components
  dplyr::summarize(
            DII_ALL = sum(ALCOHOL, VITB12, VITB6, BCAROTENE, CAFFEINE, CARB, 
                          CHOLES, KCAL, TOTALFAT, FIBER, FOLICACID, IRON, MG, MUFA,
                          NIACIN, N3FAT, N6FAT, PROTEIN, PUFA, RIBOFLAVIN, SATFAT,
                          SE, THIAMIN, VITA, VITC, VITD, VITE, ZN,
                          EUGENOL, ISOFLAVONES, FLA3OL, FLAVONES, ANTHOC, 
                          FLAVONONES, FLAVONOLS, GARLIC, GINGER, ONION, PEPPER, 
                          TEA, TURMERIC, THYME, 
                          # SAFFRON, ROSEMARY, TRANS
                          na.rm = TRUE),
            DII_NOETOH = sum(VITB12, VITB6, BCAROTENE, CAFFEINE, CARB, CHOLES, 
                             KCAL, TOTALFAT, FIBER, FOLICACID, IRON, MG, MUFA,
                             NIACIN, N3FAT, N6FAT, PROTEIN, PUFA, RIBOFLAVIN, 
                             SATFAT, SE, THIAMIN, VITA, VITC, VITD, VITE, ZN,
                             EUGENOL, ISOFLAVONES, FLA3OL, FLAVONES, ANTHOC, 
                             FLAVONONES, FLAVONOLS, GARLIC, GINGER, ONION, 
                             PEPPER, TEA, TURMERIC, THYME, 
                             # SAFFRON, ROSEMARY, TRANS
                             na.rm = TRUE),
            ALCOHOL = sum(ALCOHOL, na.rm = TRUE),
            VITB12 = sum(VITB12, na.rm = TRUE),
            VITB6 = sum(VITB6, na.rm = TRUE),
            BCAROTENE = sum(BCAROTENE, na.rm = TRUE),
            CAFFEINE = sum(CAFFEINE, na.rm = TRUE),
            CARB = sum(CARB, na.rm = TRUE),
            CHOLES = sum(CHOLES, na.rm = TRUE),
            KCAL = sum(KCAL, na.rm = TRUE),
            TOTALFAT = sum(TOTALFAT, na.rm = TRUE),
            FIBER = sum(FIBER, na.rm = TRUE),
            FOLICACID = sum(FOLICACID, na.rm = TRUE),
            IRON = sum(IRON, na.rm = TRUE),
            MG = sum(MG, na.rm = TRUE),
            MUFA = sum(MUFA, na.rm = TRUE),
            NIACIN = sum(NIACIN, na.rm = TRUE),
            N3FAT = sum(N3FAT, na.rm = TRUE),
            N6FAT = sum(N6FAT, na.rm = TRUE),
            PROTEIN = sum(PROTEIN, na.rm = TRUE),
            PUFA = sum(PUFA, na.rm = TRUE),
            RIBOFLAVIN = sum(RIBOFLAVIN, na.rm = TRUE),
            SATFAT = sum(SATFAT, na.rm = TRUE),
            SE = sum(SE, na.rm = TRUE),
            THIAMIN = sum(THIAMIN, na.rm = TRUE),
            VITA = sum(VITA, na.rm = TRUE),
            VITC = sum(VITC, na.rm = TRUE),
            VITD = sum(VITD, na.rm = TRUE),
            VITE = sum(VITE, na.rm = TRUE),
            ZN = sum(ZN, na.rm = TRUE),
            ONION = sum(ONION, na.rm = TRUE),
            PEPPER = sum(PEPPER, na.rm = TRUE),
            GARLIC = sum(GARLIC, na.rm = TRUE),
            GINGER =sum(GINGER, na.rm = TRUE),
            TEA = sum(TEA, na.rm = TRUE),
            THYME = sum(THYME, na.rm = TRUE),
            TURMERIC = sum(TURMERIC, na.rm = TRUE),
            FLA3OL = sum(FLA3OL, na.rm = TRUE),
            FLAVONONES = sum(FLAVONONES, na.rm = TRUE),
            ANTHOC = sum(ANTHOC, na.rm = TRUE),
            ISOFLAVONES = sum(ISOFLAVONES, na.rm = TRUE),
            FLAVONOLS = sum(FLAVONOLS, na.rm = TRUE),
            FLAVONES = sum(FLAVONES, na.rm = TRUE),
            EUGENOL = sum(EUGENOL, na.rm = TRUE))
```

    ## `summarise()` has grouped output by 'subject'. You can override using the
    ## `.groups` argument.

``` r
            # Can add with future updats
            # SAFFRON =sum(SAFFRON, na.rm = TRUE),
            # ROSEMARY = sum(ROSEMARY, na.rm = TRUE),
            # TRANS = sum(TRANS, na.rm = TRUE))
```

### Export DII total and component scores for downstream use

``` r
vroom::vroom_write(DII_scores, "outputs/summary_DII_final_scores_by_entry.csv", delim = ",")
```

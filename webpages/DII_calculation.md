---
layout: default
title: DII Calculation
nav_order: 4
show_toc: true
has_children: true
---

## Calculating the Dietary Inflammatory Index
The dietary inflammatory index (DII) is a 45-component index created by Shivappa et al[^1] that reflects the inflammatory potential of the diet. Our script adds 14-components to the 28-component calculation detailed in [DII_ASA24.R](https://github.com/jamesjiadazhan/dietaryindex/blob/main/R/DII_ASA24.R) from the [dietaryindex](https://doi.org/10.1016/j.cdnut.2024.102755) package. In total, 42 of the 45-components can now be calculated from ASA24 and NHANES data.
  
New Components Addeded to 28 component DII calculation:
- **Compounds**: Eugenol, isoflavones, flavan-3-ols, flavones, anthocyanidins, flavonones, flavonols
- **Foods**: Garlic, ginger, onion, pepper (spice), tea, turmeric, thyme/oregano

What is still missing?
- **Compounds** - Trans Fats. Obtaining trans fats requires an additional level of mapping to Food Data Central. We are looking to incorporate this component in a future version of this pipeline.
- **Foods** - Saffron and Rosemary. These foods do not have WWEIA food codes and are not present in the [FDA's Food Disaggregation Database](https://pub-connect.foodsafetyrisk.org/fda-fdd/). Thus, they cannot be added at this time.

### Pipeline Steps
1) **DII_STEP1_Eugenol.Rmd**: This script takes in your disaggregated dietary data and FooDB-linked descriptions to calculate eugenol intake per recall and subject.
2) **DII_STEP2_Polyphenol_Subclass.Rmd** - This script takes your data that has been mapped to FooDB polyphenol content, extracts compounds categorized under the six required DII subclasses (flavan-3-ols, Flavones, Flavonols, Flavonones, Anthocyanidins, Isoflavones), and calculates the total intake of these subclasses per participant recall. 
3) **DII_STEP3_Food.Rmd** - This script takes in your disaggregated and FooDB-linked descriptions to calculate intake of 7 specific food categories (onion, ginger, garlic, tea, pepper, turmeric, thyme/oregano).
4) **DII_STEP4_DII_Calculation.Rmd** - This scripts pulls output from previous scripts to add 14 more components to the DII calculation. An output file is generated for users to apply to other analyses.

### Outputs
1) DII_STEP1_Eugenol.Rmd
    -   **Input_FooDB_DII_eugenol_by_recall.csv**: Sum eugenol content for each participant recall
2) DII_STEP2_Polyphenol_Subclass.Rmd
    -   **Input_FooDB_DII_subclass_by_recall.csv**: Sum DII polyphenol subclass content for each participant recall
3) DII_STEP3_Food.Rmd
    -   **Input_DII_foods_by_recall.csv** - Intake of 7 DII food categories by participant recall
4) DII_STEP4_DII_Calculation.Rmd
    -   **Input_DII_final_scores_by_recall.csv** - Total DII scores and 42 individual component scores

[^1]: [Shivappa et al. 2014. Designing and developing a literature-derived, population-based dietary inflammatory index](https://doi.org/10.1017/s1368980013002115)
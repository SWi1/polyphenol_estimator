---
layout: default
title: DII Calculation
nav_order: 4
show_toc: true
has_children: true
---

## Calculating the Dietary Inflammatory Index
The dietary inflammatory index (DII) is a 45-component index created by [Shivappa et al. (2014)](https://doi.org/10.1017/s1368980013002115) that reflects the inflammatory potential of the diet. The theoretical range for the DII is -8.87 (strongly anti-inflammatory) to 7.98 (strongly pro-inflammatory).

Our script adds 14-components to the 28-component calculation detailed in [DII_ASA24.R](https://github.com/jamesjiadazhan/dietaryindex/blob/main/R/DII_ASA24.R) from the [dietaryindex](https://doi.org/10.1016/j.cdnut.2024.102755) package. In total, 42 of the 45-components can now be quickly calculated from ASA24 and NHANES data.
  
New Components Added to 28 component DII calculation:
- **Compounds**: Eugenol, isoflavones, flavan-3-ols, flavones, anthocyanidins, flavonones, flavonols
- **Foods**: Garlic, ginger, onion, pepper (spice), tea, turmeric, thyme/oregano

Missing Components
- **Compounds** - Trans Fats. Obtaining trans fats requires an additional level of mapping to Food Data Central. We are looking to incorporate this component in a future version of Polyphenol Estimator.
- **Foods** - Saffron and Rosemary. These foods do not have WWEIA food codes and are not present in the [FDA's Food Disaggregation Database](https://pub-connect.foodsafetyrisk.org/fda-fdd/). Thus, they cannot be added at this time.

### DII Calculation Steps
1. **DII_STEP1_Eugenol.Rmd**: This script takes in your disaggregated dietary data and FooDB-linked descriptions to calculate eugenol intake per recall and subject.
2. **DII_STEP2_Polyphenol_Subclass.Rmd** - This script takes your data that has been mapped to FooDB polyphenol content, extracts compounds categorized under the six required DII subclasses (flavan-3-ols, Flavones, Flavonols, Flavonones, Anthocyanidins, Isoflavones), and calculates the total intake of these subclasses per participant recall. 
3. **DII_STEP3_Food.Rmd** - This script takes in your disaggregated and FooDB-linked descriptions to calculate intake of 7 specific food categories (onion, ginger, garlic, tea, pepper, turmeric, thyme/oregano).
4. **DII_STEP4_DII_Calculation.Rmd** - This scripts calculates the 28 components originally outlined in the dietary index package and pulls output from our previous scripts to add 14 more components to the final DII calculation. An output file with the overall DII scores and 42 individual component scores is generated for users to apply to other analyses.

### Outputs
- Recall_DII_eugenol_by_recall.csv
- Recall_DII_foods_by_recall.csv
- Recall_DII_subclass_by_recall.csv
- summary_DII_final_scores_by_recall.csv
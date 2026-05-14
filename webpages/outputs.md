---
layout: default
title: Outputs
nav_order: 5
show_toc: true
---

### Polyphenol Estimator

Polyphenol Estimator provides polyphenol intake summaries at three different resolution levels: total, class, and compound. Click the headings below to examine various outputs:

<details>
<summary>Total Polyphenol Intake</summary>

  <ul>
    <li><strong>Diet_total_nutrients.csv</strong>: Nutrient totals are provided by entry (recall or record and record day) for each participant</li>
    <li><strong>summary_total_intake_by_entry.csv</strong>: polyphenol total intakes by entry (recall or record and record day) for each participant</li>
    <li><strong>summary_total_intake_by_subject.csv</strong>: polyphenol total intakes for each participant</li>
    <li><strong>summary_total_polyphenol_food_contributors.csv</strong>: total polyphenol and intake averages for each food, as well as food frequencies </li>
  </ul>

</details>

<details>
<summary>Class Polyphenol Intake</summary>

  <ul>
   <li><strong>summary_class_by_entry.csv</strong>: polyphenol class intakes by entry (recall or record and record day) for each participant</li>
   <li><strong>summary_class_by_subject.csv</strong>: polyphenol class intakes for each participant, provided in long format (classes as rows)</li>
   <li><strong>summary_class_by_subject_wide.csv</strong>: polyphenol class intakes for each participant, provided in wide format, i.e. classes as columns</li>
  </ul>

</details>

<details>
<summary>Compound Polyphenol Intake</summary>

  <ul>
   <li><strong>summary_compound_by_entry.csv</strong>:  polyphenol compound intakes by entry for each participant</li>
   <li><strong>summary_compound_by_subject.csv</strong>: polyphenol compound intakes for each participant, provided in long format (compounds as rows)</li>
   <li><strong>summary_compound_by_subject_wide.csv</strong>: polyphenol compound intakes for each participant, provided in wide formal, i.e. compounds as columns</li>
  </ul>

</details>

<details>
<summary>Unmapped Foods (i.e. What didn't map to FooDB?)</summary>
  
  <ul> 
    <li><strong>summary_missing_foods_overview.txt</strong>: Summary of the number of unmapped foods between FDA-FDD and FooDB across ALL recalls or records and record days</li>
    <li><strong>summary_missing_foods_detailed.csv</strong>: Summary of the number of unmapped foods between FDA-FDD and FooDB BY recall or record and record day</li>
  </ul>
</details>

<details>
<summary>Intermediate Files</summary>
Our mapping output files are large feature-rich datasets, which we have compressed.

  <ul> 
    <li><strong>Diet_Disaggregated.csv.bz2</strong>: Food codes are shown with their underlying ingredients and newly calculated gram intakes</li>
    <li><strong>Diet_Disaggregated_mapped.csv.bz2</strong>: Food codes are shown with their underlying ingredients and newly calculated gram intakes, and FooDB food name equivalent (no content)</li>
    <li><strong>Diet_FooDB_polyphenol_content.csv.bz2</strong>: Food codes are shown with their underlying ingredients and newly calculated gram intakes, and FooDB food names. Contains polyphenol content.</li>
  </ul>

</details>

<details>
<summary>Log Files</summary>

A log file is also generated for each run of estimate_polyphenols() and calculate_DII(). These files are intended to help users track use and time of Polyphenol Estimator runs, including any runs that experienced an error.

</details>

### Dietary Inflammatory Index (DII) Calculation
We have one output file: 
- **summary_DII_final_scores_by_entry.csv**: Total 42-component DII scores as well as all 42 individual component scores.
<details>
<summary>Intermediate Files</summary>
Intake summary files for the 14 food and polyphenol components are fed into the total DII calculation.

  <ul>
    <li><strong>Diet_DII_eugenol_by_entry.csv</strong>: Eugenol intake by entry (recall or record and record day)</li>
    <li><strong>Diet_DII_foods_by_entry.csv</strong>: Food intake (onion, ginger, garlic, tea, pepper, turmeric, thyme/oregano) by entry (recall or record and record day)</li>
    <li><strong>Diet_DII_subclass_by_entry.csv</strong>: Polyphenol subclass intake (flavan-3-ols, Flavones, Flavonols, Flavonones, Anthocyanidins, Isoflavones) by entry (recall or record and record day)</li>
  </ul>

</details>
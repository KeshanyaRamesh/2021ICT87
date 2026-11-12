# Relationship Between Stress Levels and Sleep Quality

**Student Registration Number:** 2021/ICT/87  


## 1. Project Overview

This project investigates the relationship between perceived stress levels and sleep quality using statistical analysis in R.

The study explores whether individuals experiencing higher levels of perceived stress tend to report poorer sleep quality. The analysis uses the Perceived Stress Scale (PSS-10) to calculate stress scores and examines their relationship with sleep-quality outcomes.

## 2. Objectives

- Analyze perceived stress levels using PSS-10 scoring.
- Examine sleep-quality patterns among participants.
- Investigate the relationship between stress levels and sleep quality.
- Apply appropriate statistical methods to identify associations.
- Present findings using tables, graphs, and statistical summaries.

## 3. Dataset

The study uses questionnaire-based data containing information about participants' stress levels and sleep quality.

### Data Processing Summary

| Description | Records |
|---|---:|
| Imported records | 327 |
| Completed responses | 280 |
| Usable records | 277 |

The dataset was processed to prepare the required variables for statistical analysis.

## 4. Tools and Technologies

- **R:** Statistical computing and analysis
- **RStudio:** Development environment
- **R Markdown:** Reproducible research report
- **ggplot2:** Data visualization
- **dplyr:** Data manipulation
- **readxl:** Excel data importing

## 5. Statistical Methods

The project includes:

- Data importing and preprocessing
- PSS-10 stress score calculation
- Sleep-quality outcome preparation
- Descriptive statistical analysis
- Data visualization
- Spearman's rank correlation analysis
- Interpretation of statistical findings

## 6. Project Structure

```text
2021ICT87/
│
├── code/
│   └── R analysis scripts
│
├── figures/
│   └── Generated visualizations
│
├── report/
│   ├── analysis_report.Rmd
│   └── analysis_report.html
│
├── results/
│   └── Statistical analysis outputs
│
├── .gitignore
└── README.md
```

## 7. How to Run the Project

### Prerequisites

- R
- RStudio
- Required R packages

### Install Required Packages

```r
install.packages(c(
  "rmarkdown",
  "knitr",
  "ggplot2",
  "dplyr",
  "readxl",
  "tidyr"
))
```

### Run the Analysis

1. Clone or download this repository.
2. Open the R project in RStudio.
3. Ensure the required dataset is available in the expected local data directory.
4. Open the relevant R analysis script.
5. Execute the analysis.

### Generate the HTML Report

```r
rmarkdown::render(
  "report/analysis_report.Rmd",
  output_format = "html_document"
)
```

The generated report will be available at:

`report/analysis_report.html`

## 8. Results and Visualizations

The project presents statistical findings through graphical visualizations and analysis outputs.

The generated HTML report provides detailed explanations of the methodology, statistical results, visualizations, and conclusions.

## 9. Conclusion

This project applies statistical techniques to investigate the association between perceived stress levels and sleep quality.

The findings are interpreted using the selected statistical methods, providing an understanding of how stress and sleep-quality measures are related within the analyzed dataset.

## 10. Author

**Student Registration Number:** 2021/ICT/87  
**University:** University of Vavuniya  
**Faculty:** Faculty of Applied Science  
**Programme:** BSc (Hons) in Information Technology

---

*Academic research project developed using R and RStudio.*

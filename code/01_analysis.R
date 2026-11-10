
# ============================================================
# Stress and Sleep Quality: Reproducible R Analysis
# Dataset: UNE, DOI 10.25952/ydqq-kr29
# ============================================================

# 1. Install and load required packages
required_packages <- c(
  "readxl", "dplyr", "tidyr", "ggplot2", "readr", "MASS"
)

missing_packages <- required_packages[
  !required_packages %in% rownames(installed.packages())
]

if (length(missing_packages) > 0) {
  install.packages(
    missing_packages,
    repos = "https://cloud.r-project.org"
  )
}

invisible(lapply(required_packages, library, character.only = TRUE))


# 2. Set project folders
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)
dir.create("figures", recursive = TRUE, showWarnings = FALSE)
dir.create("results", recursive = TRUE, showWarnings = FALSE)


# 3. Locate the original Excel workbook
expected_file <- file.path(
  "data", "raw",
  "opendataset_The Relationship Between Stress, Arousal, Sleep Quality and Affective Symptoms - UNE_January 17, 2022_15.02.xlsx"
)

if (!file.exists(expected_file)) {
  message("Excel file not found at the expected path.")
  message("Please select the downloaded UNE Excel workbook.")
  selected_file <- file.choose()
} else {
  selected_file <- expected_file
}


# 4. Import data
raw_export <- readxl::read_excel(selected_file, sheet = 1)

if (nrow(raw_export) < 2) {
  stop("Workbook does not contain the expected question-label row and responses.")
}

# Remove embedded question-label row
raw_data <- raw_export %>%
  dplyr::slice(-1)

cat("Rows after removing embedded question-label row:",
    nrow(raw_data), "\n")

cat("Imported columns:", ncol(raw_data), "\n")


# 5. Validate expected columns
pss_columns <- paste0("Q20_", 1:10)

required_columns <- c(
  "Finished",
  pss_columns,
  "Q46"
)

missing_columns <- setdiff(
  required_columns,
  names(raw_data)
)

if (length(missing_columns) > 0) {
  stop(
    "Required columns missing from workbook: ",
    paste(missing_columns, collapse = ", "),
    ". Check the workbook version and column headings."
  )
}


# 6. Keep completed responses and select required variables
analysis_data <- raw_data %>%
  dplyr::mutate(
    Finished = suppressWarnings(
      as.numeric(as.character(Finished))
    ),
    dplyr::across(
      dplyr::all_of(c(pss_columns, "Q46")),
      ~ suppressWarnings(as.numeric(as.character(.x)))
    )
  ) %>%
  dplyr::filter(Finished == 1) %>%
  dplyr::select(
    dplyr::all_of(c(pss_columns, "Q46"))
  )


# 7. Validate response ranges
for (column_name in pss_columns) {
  
  unexpected <- setdiff(
    unique(stats::na.omit(analysis_data[[column_name]])),
    1:5
  )
  
  if (length(unexpected) > 0) {
    stop(
      "Unexpected response code in ", column_name, ": ",
      paste(unexpected, collapse = ", ")
    )
  }
}

unexpected_sleep <- setdiff(
  unique(stats::na.omit(analysis_data$Q46)),
  1:4
)

if (length(unexpected_sleep) > 0) {
  stop(
    "Unexpected Q46 response code(s): ",
    paste(unexpected_sleep, collapse = ", ")
  )
}


# 8. Calculate PSS-10 total score
# Original coding: 1=Never to 5=Very often
# Standard PSS coding: 0 to 4
# Reverse-scored items: 4, 5, 7, 8

pss_matrix <- as.data.frame(
  analysis_data[pss_columns]
)

pss_matrix[] <- lapply(
  pss_matrix,
  function(x) x - 1
)

reverse_columns <- paste0(
  "Q20_", c(4, 5, 7, 8)
)

pss_matrix[reverse_columns] <- lapply(
  pss_matrix[reverse_columns],
  function(x) 4 - x
)

# Calculate score only when all 10 answers are available
analysis_data$PSS_Total <- ifelse(
  rowSums(is.na(pss_matrix)) == 0,
  rowSums(pss_matrix),
  NA_real_
)


# 9. Create ordinal sleep-quality variable
# Assumption: Q46 coding is 1=Very good to 4=Very bad
# Verify the original questionnaire labels.

analysis_data$Sleep_Quality <- factor(
  analysis_data$Q46,
  levels = 1:4,
  labels = c(
    "Very good",
    "Fairly good",
    "Fairly bad",
    "Very bad"
  ),
  ordered = TRUE
)


# 10. Create complete analysis dataset
# Participant-level records are not exported.

model_data <- analysis_data %>%
  dplyr::filter(
    !is.na(PSS_Total),
    !is.na(Sleep_Quality)
  )

cat("\nCompleted records:", nrow(analysis_data), "\n")

cat("Usable records for main analysis:",
    nrow(model_data), "\n")

cat(
  "Excluded due to missing PSS or sleep rating:",
  nrow(analysis_data) - nrow(model_data), "\n"
)

if (nrow(model_data) < 20) {
  stop(
    "Too few complete records for the planned analysis. Check data coding."
  )
}


# 11. Descriptive statistics
descriptive_summary <- data.frame(
  Measure = c(
    "PSS-10 total score",
    "PSS-10 total score"
  ),
  Statistic = c(
    "Mean",
    "Standard deviation"
  ),
  Value = c(
    mean(model_data$PSS_Total),
    stats::sd(model_data$PSS_Total)
  )
)

sleep_distribution <- model_data %>%
  dplyr::count(Sleep_Quality, .drop = FALSE) %>%
  dplyr::mutate(
    Percentage = 100 * n / sum(n)
  )

readr::write_csv(
  descriptive_summary,
  "results/descriptive_summary.csv"
)

readr::write_csv(
  sleep_distribution,
  "results/sleep_quality_distribution.csv"
)


# 12. Spearman correlation analysis
# Higher sleep-quality values are assumed to indicate worse sleep.

correlation_result <- stats::cor.test(
  model_data$PSS_Total,
  as.numeric(model_data$Sleep_Quality),
  method = "spearman",
  exact = FALSE
)

capture.output(
  correlation_result,
  file = "results/spearman_correlation.txt"
)


# 13. Ordinal logistic regression
ordinal_model <- MASS::polr(
  Sleep_Quality ~ PSS_Total,
  data = model_data,
  Hess = TRUE
)

model_summary <- summary(ordinal_model)

capture.output(
  model_summary,
  file = "results/ordinal_logistic_regression.txt"
)

# Extract coefficient information
coefs <- coef(model_summary)

p_values <- 2 * stats::pnorm(
  abs(coefs[, "t value"]),
  lower.tail = FALSE
)

coefficient_table <- data.frame(
  Term = rownames(coefs),
  Estimate = coefs[, "Value"],
  Standard_Error = coefs[, "Std. Error"],
  Z_value = coefs[, "t value"],
  P_value = p_values,
  Odds_Ratio = exp(coefs[, "Value"]),
  row.names = NULL
)

readr::write_csv(
  coefficient_table,
  "results/ordinal_model_coefficients.csv"
)


# 14. Figure 1: PSS score distribution
p1 <- ggplot2::ggplot(
  model_data,
  ggplot2::aes(x = PSS_Total)
) +
  ggplot2::geom_histogram(
    binwidth = 2,
    boundary = 0,
    fill = "#3977B8",
    colour = "white"
  ) +
  ggplot2::labs(
    title = "Distribution of Perceived Stress Scores",
    x = "PSS-10 total score (0-40)",
    y = "Number of participants"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "figures/01_stress_score_distribution.png",
  p1,
  width = 8,
  height = 5,
  dpi = 300
)


# 15. Figure 2: Sleep-quality response distribution
p2 <- ggplot2::ggplot(
  sleep_distribution,
  ggplot2::aes(x = Sleep_Quality, y = n)
) +
  ggplot2::geom_col(fill = "#6B5CA5") +
  ggplot2::geom_text(
    ggplot2::aes(
      label = paste0(
        n, " (", round(Percentage, 1), "%)"
      )
    ),
    vjust = -0.35,
    size = 3.5
  ) +
  ggplot2::labs(
    title = "Self-Rated Overall Sleep Quality",
    x = "Sleep quality rating",
    y = "Number of participants"
  ) +
  ggplot2::expand_limits(
    y = max(sleep_distribution$n) * 1.15
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "figures/02_sleep_quality_distribution.png",
  p2,
  width = 8,
  height = 5,
  dpi = 300
)


# 16. Figure 3: Stress score by sleep-quality category
p3 <- ggplot2::ggplot(
  model_data,
  ggplot2::aes(
    x = Sleep_Quality,
    y = PSS_Total,
    fill = Sleep_Quality
  )
) +
  ggplot2::geom_boxplot(
    alpha = 0.75,
    show.legend = FALSE
  ) +
  ggplot2::geom_jitter(
    width = 0.12,
    alpha = 0.25,
    size = 1.2,
    show.legend = FALSE
  ) +
  ggplot2::labs(
    title = "Perceived Stress Across Sleep-Quality Categories",
    x = "Self-rated sleep quality",
    y = "PSS-10 total score"
  ) +
  ggplot2::theme_minimal(base_size = 12)

ggplot2::ggsave(
  "figures/03_stress_by_sleep_quality.png",
  p3,
  width = 8,
  height = 5,
  dpi = 300
)


# 17. Save aggregate analysis summary
run_summary <- data.frame(
  Item = c(
    "Imported participant records",
    "Completed records",
    "Usable records in main analysis",
    "Mean PSS-10 score",
    "SD of PSS-10 score",
    "Spearman rho",
    "Spearman p-value"
  ),
  Value = c(
    nrow(raw_data),
    nrow(analysis_data),
    nrow(model_data),
    round(mean(model_data$PSS_Total), 3),
    round(stats::sd(model_data$PSS_Total), 3),
    round(
      unname(correlation_result$estimate),
      4
    ),
    signif(correlation_result$p.value, 4)
  )
)

readr::write_csv(
  run_summary,
  "results/analysis_run_summary.csv"
)


# 18. Final output
cat("\n====================================\n")
cat("ANALYSIS COMPLETED SUCCESSFULLY!\n")
cat("====================================\n")

cat("Figures saved in figures/ folder.\n")
cat("Aggregate results saved in results/ folder.\n")
cat("Participant-level data were not exported.\n")
cat("====================================\n")

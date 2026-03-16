# 🏡 House Price Prediction — Multiple Linear Regression in R

> Predicting residential sale prices using the **Ames Housing dataset** with feature engineering, stepwise AIC feature selection, full regression diagnostics, and ggplot2 visualizations.

[![R](https://img.shields.io/badge/Language-R%204.3+-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)

---

## 📋 Project Overview

This project applies **multiple linear regression** to predict house sale prices from 80+ property characteristics, demonstrating:

| Skill | Implementation |
|-------|---------------|
| **Feature Engineering** | Total SF, house age, total baths (derived variables) |
| **Log Transformation** | Normalize right-skewed sale prices |
| **Stepwise Feature Selection** | `MASS::stepAIC()` — backward-forward elimination by AIC |
| **Regression Diagnostics** | Residual plots, Q-Q, Scale-Location, Cook's Distance |
| **Formal Assumption Tests** | Shapiro-Wilk, Breusch-Pagan, Durbin-Watson |
| **Multicollinearity** | Variance Inflation Factors (VIF) via `car` |
| **Model Evaluation** | RMSE, MAE, R², MAPE on held-out test set |
| **Visualization** | 9 publication-quality plots with `ggplot2` |

---

## 📁 Project Structure

```
house-price-prediction/
├── R/
│   ├── 01_data_preparation.R    # Load, clean, engineer features
│   ├── 02_eda.R                 # Exploratory data analysis + plots
│   ├── 03_modeling.R            # Fit models, stepwise AIC, evaluate
│   └── 04_diagnostics.R        # Full regression diagnostic suite
├── data/
│   ├── housing_clean.rds        # Cleaned dataset (generated)
│   └── housing_clean.csv        # CSV version (generated)
├── outputs/
│   ├── plots/                   # All ggplot2 visualizations (generated)
│   ├── models/                  # Saved model objects (generated)
│   ├── model_comparison.csv     # Adj R², AIC, BIC comparison
│   ├── test_performance.csv     # RMSE, MAE, R², MAPE
│   └── vif_table.csv            # Multicollinearity diagnostics
├── report.Rmd                   # Full R Markdown report
├── run_all.R                    # Master pipeline runner
├── .gitignore
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

```r
install.packages("pacman")
pacman::p_load(
  tidyverse, AmesHousing, janitor, skimr, naniar,
  broom, car, MASS, lmtest, patchwork, scales,
  ggcorrplot, yardstick, here
)
```

### Run the full pipeline

```r
source("run_all.R")
```

### Or step-by-step

```r
source("R/01_data_preparation.R")
source("R/02_eda.R")
source("R/03_modeling.R")
source("R/04_diagnostics.R")
```

### Render the report

```r
rmarkdown::render("report.Rmd", output_format = "html_document")
```

---

## 📊 Key Results

| Metric | Baseline (2 vars) | Stepwise AIC |
|--------|:-----------------:|:------------:|
| Adj. R² (train) | ~0.78 | ~0.91 |
| RMSE (test, $) | ~$38,000 | ~$24,000 |
| MAE (test, $) | ~$27,000 | ~$17,000 |
| MAPE (%) | ~18% | ~11% |

---

## 📈 Visualizations Generated

| File | Description |
|------|-------------|
| `01_price_distribution.png` | Raw vs log-transformed sale price histograms |
| `02_scatter_predictors.png` | Key numeric predictors vs log(Price) |
| `03_correlation_matrix.png` | Heatmap of numeric feature correlations |
| `04_price_by_neighborhood.png` | Median sale price by neighborhood |
| `05_price_by_quality.png` | Sale price distribution by overall quality rating |
| `06_predicted_vs_actual.png` | Model predictions vs ground truth (test set) |
| `07_regression_diagnostics.png` | 4-panel diagnostic grid |
| `08_residual_histogram.png` | Residual distribution with normal overlay |
| `09_coefficient_plot.png` | Coefficient estimates with 95% CIs |

---

## 🔍 Regression Diagnostics Explained

### Assumption Checks

| Assumption | Method | What to look for |
|-----------|--------|-----------------|
| **Linearity** | Residuals vs Fitted | Points randomly scattered around 0 |
| **Normality** | Q-Q plot + Shapiro-Wilk | Points on the diagonal line |
| **Homoscedasticity** | Scale-Location + Breusch-Pagan | Flat loess line, p > 0.05 |
| **Independence** | Durbin-Watson | DW ≈ 2.0 |
| **No multicollinearity** | VIF | VIF < 5 for all predictors |

---

## 🛠 Feature Engineering Details

```r
# Derived features created in 01_data_preparation.R
total_sf      = gr_liv_area + total_bsmt_sf    # combined living space
total_baths   = full_bath + 0.5 * half_bath    # weighted bathroom count
house_age     = 2010 - year_built              # age at time of sale
remod_age     = 2010 - year_remod_add          # years since remodel
log_sale_price = log(sale_price)               # normalize skewed target
```

---

## 📦 Packages Used

| Package | Purpose |
|---------|---------|
| `tidyverse` | Data wrangling, ggplot2 visualization |
| `AmesHousing` | Dataset source |
| `MASS` | `stepAIC()` for feature selection |
| `car` | `vif()` for multicollinearity diagnostics |
| `broom` | Tidy model outputs (`tidy`, `glance`, `augment`) |
| `lmtest` | Breusch-Pagan, Durbin-Watson tests |
| `ggcorrplot` | Correlation matrix heatmap |
| `yardstick` | RMSE, MAE, R² computation |
| `patchwork` | Combining ggplot2 panels |
| `janitor` | `clean_names()` |

---

## 🗺 Extending This Project

- **Regularization**: Ridge / Lasso with `glmnet`
- **Non-linear models**: Random Forest, XGBoost with `tidymodels`
- **Spatial analysis**: Map neighborhood effects with `sf`
- **Shiny App**: Interactive prediction UI

---

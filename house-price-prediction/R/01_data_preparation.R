# =============================================================================
# House Price Prediction — Data Preparation
# Dataset: Ames Housing (via AmesHousing package or CSV)
# Author: [Your Name]
# =============================================================================

# ── 0. Install / Load Packages ────────────────────────────────────────────────
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  tidyverse,    # data wrangling + ggplot2
  AmesHousing,  # built-in Ames dataset
  janitor,      # clean_names()
  skimr,        # skim()
  naniar,       # missing value viz
  here          # project-relative paths
)

# ── 1. Load Data ──────────────────────────────────────────────────────────────
raw <- AmesHousing::make_ames()   # 2,930 obs × 81 vars (cleaned version)

cat("Dimensions:", dim(raw), "\n")
cat("Sale price range: $", min(raw$Sale_Price), "–", max(raw$Sale_Price), "\n")

# ── 2. Quick Overview ─────────────────────────────────────────────────────────
skimr::skim(raw)

# ── 3. Select & Engineer Features ────────────────────────────────────────────
#   Keep a meaningful subset + create derived features
housing <- raw %>%
  janitor::clean_names() %>%
  transmute(
    # Target
    sale_price        = sale_price,
    log_sale_price    = log(sale_price),           # normalize right-skew

    # Size
    gr_liv_area       = gr_liv_area,               # above-ground sq ft
    total_bsmt_sf     = replace_na(total_bsmt_sf, 0),
    total_sf          = gr_liv_area + total_bsmt_sf,  # DERIVED: total living SF
    lot_area          = lot_area,

    # Rooms
    bedroom_abv_gr    = bedroom_abv_gr,
    full_bath         = full_bath,
    half_bath         = half_bath,
    total_baths       = full_bath + 0.5 * half_bath,  # DERIVED

    # Quality (ordinal → numeric)
    overall_qual      = overall_qual,              # 1–10 scale (already numeric)
    overall_cond      = overall_cond,

    # Age
    year_built        = year_built,
    year_remod_add    = year_remod_add,
    house_age         = 2010 - year_built,         # DERIVED (dataset ~2006-2010)
    remod_age         = 2010 - year_remod_add,

    # Garage
    garage_cars       = replace_na(garage_cars, 0),
    garage_area       = replace_na(garage_area, 0),

    # Categorical
    neighborhood      = neighborhood,
    bldg_type         = bldg_type,
    house_style       = house_style,
    sale_condition    = sale_condition,

    # Exterior / location scores
    exter_qual        = as.numeric(factor(exter_qual,
                          levels = c("Po","Fa","TA","Gd","Ex"))),
    kitchen_qual      = as.numeric(factor(kitchen_qual,
                          levels = c("Po","Fa","TA","Gd","Ex"))),

    # Flags
    has_fireplace     = as.integer(fireplaces > 0),
    has_pool          = as.integer(pool_area > 0),
    has_garage        = as.integer(garage_area > 0)
  ) %>%
  # Remove obvious outliers (per Ames dataset documentation)
  filter(gr_liv_area < 4000)

cat("\nCleaned dataset:", nrow(housing), "rows,", ncol(housing), "cols\n")

# ── 4. Missing Value Check ────────────────────────────────────────────────────
naniar::miss_var_summary(housing) %>% filter(n_miss > 0) %>% print()

# ── 5. Save Cleaned Data ──────────────────────────────────────────────────────
saveRDS(housing, here::here("data", "housing_clean.rds"))
write_csv(housing, here::here("data", "housing_clean.csv"))
cat("\n✓ Data saved to data/housing_clean.rds & .csv\n")

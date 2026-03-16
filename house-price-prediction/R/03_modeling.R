# =============================================================================
# House Price Prediction — Multiple Linear Regression + Feature Selection
# Packages: lm(), MASS::stepAIC(), car, broom
# =============================================================================

pacman::p_load(
  tidyverse, here, broom, car, MASS, patchwork,
  scales, yardstick, lmtest
)

housing <- readRDS(here("data", "housing_clean.rds"))

# ── 1. Train / Test Split (80 / 20) ──────────────────────────────────────────
set.seed(42)
idx        <- sample(nrow(housing), size = floor(0.8 * nrow(housing)))
train      <- housing[idx, ]
test       <- housing[-idx, ]
cat("Train:", nrow(train), "| Test:", nrow(test), "\n")

# ── 2. Full Model (all numeric predictors) ────────────────────────────────────
full_formula <- log_sale_price ~ total_sf + gr_liv_area + lot_area +
  bedroom_abv_gr + total_baths + overall_qual + overall_cond +
  house_age + remod_age + garage_cars + garage_area +
  exter_qual + kitchen_qual + has_fireplace + has_pool +
  neighborhood + bldg_type + sale_condition

model_full <- lm(full_formula, data = train)
cat("\n── Full model summary ──────────────────────────────────────\n")
summary(model_full)

# ── 3. Stepwise Feature Selection (AIC) ───────────────────────────────────────
cat("\n── Stepwise AIC feature selection ─────────────────────────\n")

# Start from the full model; MASS::stepAIC does backward-forward search
model_step <- MASS::stepAIC(model_full,
                            direction = "both",
                            trace     = FALSE)   # set TRUE to see each step
cat("\nSelected formula:\n")
print(formula(model_step))

cat("\n── Stepwise model summary ──────────────────────────────────\n")
summary(model_step)

# ── 4. Simple Baseline Model ──────────────────────────────────────────────────
model_base <- lm(log_sale_price ~ total_sf + overall_qual, data = train)

# ── 5. Model Comparison Table ─────────────────────────────────────────────────
compare <- tibble(
  Model     = c("Baseline (2 vars)", "Stepwise AIC", "Full model"),
  Adj_R2    = c(summary(model_base)$adj.r.squared,
                summary(model_step)$adj.r.squared,
                summary(model_full)$adj.r.squared),
  AIC       = c(AIC(model_base), AIC(model_step), AIC(model_full)),
  BIC       = c(BIC(model_base), BIC(model_step), BIC(model_full))
) %>%
  mutate(across(where(is.numeric), ~round(.x, 3)))

cat("\n── Model Comparison ────────────────────────────────────────\n")
print(compare)
write_csv(compare, here("outputs", "model_comparison.csv"))

# ── 6. Save Final Model ───────────────────────────────────────────────────────
saveRDS(model_step, here("outputs", "models", "model_step.rds"))
saveRDS(model_base, here("outputs", "models", "model_base.rds"))

# ── 7. Test Set Evaluation ────────────────────────────────────────────────────
eval_model <- function(model, newdata, label) {
  preds_log <- predict(model, newdata = newdata)
  preds     <- exp(preds_log)               # back-transform
  actual    <- newdata$sale_price

  tibble(
    Model  = label,
    RMSE   = rmse_vec(actual, preds),
    MAE    = mae_vec(actual, preds),
    R2     = rsq_vec(actual, preds),
    MAPE   = mean(abs((actual - preds) / actual)) * 100
  ) %>% mutate(across(where(is.numeric), ~round(.x, 2)))
}

results <- bind_rows(
  eval_model(model_base, test, "Baseline"),
  eval_model(model_step, test, "Stepwise AIC")
)

cat("\n── Test Set Performance ────────────────────────────────────\n")
print(results)
write_csv(results, here("outputs", "test_performance.csv"))

# ── 8. Predicted vs Actual Plot ───────────────────────────────────────────────
test <- test %>%
  mutate(predicted = exp(predict(model_step, newdata = test)))

ggplot(test, aes(x = sale_price, y = predicted)) +
  geom_point(alpha = 0.3, color = "#2E86AB", size = 1) +
  geom_abline(slope = 1, intercept = 0, color = "#E63946",
              linetype = "dashed", linewidth = 1) +
  scale_x_continuous(labels = dollar_format(scale = 1e-3, suffix = "K")) +
  scale_y_continuous(labels = dollar_format(scale = 1e-3, suffix = "K")) +
  labs(title    = "Predicted vs Actual Sale Price (Test Set)",
       subtitle = "Stepwise AIC model | dashed line = perfect prediction",
       x = "Actual Price", y = "Predicted Price") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(here("outputs", "plots", "06_predicted_vs_actual.png"),
       width = 8, height = 6, dpi = 150)

cat("✓ Modeling complete. Outputs saved.\n")

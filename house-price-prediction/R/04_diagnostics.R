# =============================================================================
# House Price Prediction — Regression Diagnostics
# Assumptions: Linearity, Normality of Residuals, Homoscedasticity,
#              Independence, Multicollinearity (VIF)
# =============================================================================

pacman::p_load(
  tidyverse, here, broom, car, lmtest, patchwork, scales, ggfortify
)

model_step <- readRDS(here("outputs", "models", "model_step.rds"))
housing    <- readRDS(here("data", "housing_clean.rds"))

set.seed(42)
idx   <- sample(nrow(housing), size = floor(0.8 * nrow(housing)))
train <- housing[idx, ]

# ── Helper theme ──────────────────────────────────────────────────────────────
theme_diag <- theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

# ── 1. Augmented Residuals Data Frame ─────────────────────────────────────────
aug <- broom::augment(model_step) %>%
  rename(residuals   = .resid,
         fitted      = .fitted,
         std_resid   = .std.resid,
         leverage    = .hat,
         cooks_d     = .cooksd)

# ── 2. Plot 1 — Residuals vs Fitted ──────────────────────────────────────────
#    Checks: Linearity & Homoscedasticity
p_resfit <- ggplot(aug, aes(x = fitted, y = residuals)) +
  geom_point(alpha = 0.25, size = 0.8, color = "#2E86AB") +
  geom_hline(yintercept = 0, color = "#E63946", linetype = "dashed") +
  geom_smooth(method = "loess", se = FALSE, color = "#F4A261", linewidth = 0.8) +
  labs(title    = "1. Residuals vs Fitted",
       subtitle = "Checks linearity & homoscedasticity",
       x = "Fitted Values (log scale)", y = "Residuals") +
  theme_diag

# ── 3. Plot 2 — Normal Q-Q Plot ───────────────────────────────────────────────
#    Checks: Normality of residuals
p_qq <- ggplot(aug, aes(sample = std_resid)) +
  stat_qq(alpha = 0.3, size = 0.8, color = "#2E86AB") +
  stat_qq_line(color = "#E63946", linewidth = 0.9, linetype = "dashed") +
  labs(title    = "2. Normal Q-Q Plot",
       subtitle = "Checks normality of residuals",
       x = "Theoretical Quantiles", y = "Standardized Residuals") +
  theme_diag

# ── 4. Plot 3 — Scale-Location (√|Std. Residuals| vs Fitted) ─────────────────
#    Checks: Homoscedasticity
p_scale <- ggplot(aug, aes(x = fitted, y = sqrt(abs(std_resid)))) +
  geom_point(alpha = 0.25, size = 0.8, color = "#2E86AB") +
  geom_smooth(method = "loess", se = FALSE, color = "#F4A261", linewidth = 0.8) +
  labs(title    = "3. Scale-Location",
       subtitle = "Checks homoscedasticity",
       x = "Fitted Values", y = "√|Standardized Residuals|") +
  theme_diag

# ── 5. Plot 4 — Residuals vs Leverage (Cook's Distance) ──────────────────────
p_lev <- ggplot(aug, aes(x = leverage, y = std_resid, size = cooks_d)) +
  geom_point(alpha = 0.3, color = "#2E86AB") +
  geom_hline(yintercept = c(-3, 3), linetype = "dashed", color = "#E63946") +
  scale_size_continuous(name = "Cook's D", range = c(0.5, 4)) +
  labs(title    = "4. Residuals vs Leverage",
       subtitle = "Identifies high-influence observations",
       x = "Leverage", y = "Standardized Residuals") +
  theme_diag

# ── Combine & Save ────────────────────────────────────────────────────────────
(p_resfit | p_qq) / (p_scale | p_lev) +
  plot_annotation(
    title   = "Regression Diagnostics — Stepwise AIC Model",
    caption = "Ames Housing Dataset",
    theme   = theme(plot.title = element_text(face = "bold", size = 15))
  )

ggsave(here("outputs", "plots", "07_regression_diagnostics.png"),
       width = 14, height = 10, dpi = 150)

# ── 6. Histogram of Residuals ─────────────────────────────────────────────────
p_hist <- ggplot(aug, aes(x = residuals)) +
  geom_histogram(aes(y = after_stat(density)), bins = 60,
                 fill = "#2E86AB", color = "white", linewidth = 0.2) +
  stat_function(fun = dnorm,
                args = list(mean = mean(aug$residuals),
                            sd   = sd(aug$residuals)),
                color = "#E63946", linewidth = 1) +
  labs(title    = "Distribution of Residuals",
       subtitle = "Red curve = fitted normal distribution",
       x = "Residuals", y = "Density") +
  theme_diag

ggsave(here("outputs", "plots", "08_residual_histogram.png"),
       p_hist, width = 8, height = 5, dpi = 150)

# ── 7. Formal Statistical Tests ───────────────────────────────────────────────
cat("\n══ Assumption Tests ════════════════════════════════════════\n")

# Shapiro-Wilk (sample for large n)
sw_sample <- sample(aug$residuals, min(5000, nrow(aug)))
sw_test   <- shapiro.test(sw_sample)
cat("\nShapiro-Wilk Normality Test (n =", length(sw_sample), "):\n")
cat("  W =", round(sw_test$statistic, 4),
    "| p-value =", format(sw_test$p.value, scientific = TRUE), "\n")

# Breusch-Pagan: Homoscedasticity
bp_test <- lmtest::bptest(model_step)
cat("\nBreusch-Pagan Heteroscedasticity Test:\n")
cat("  BP =", round(bp_test$statistic, 3),
    "| p-value =", format(bp_test$p.value, scientific = TRUE), "\n")

# Durbin-Watson: Independence of residuals
dw_test <- lmtest::dwtest(model_step)
cat("\nDurbin-Watson Independence Test:\n")
cat("  DW =", round(dw_test$statistic, 4),
    "| p-value =", round(dw_test$p.value, 4), "\n")

# ── 8. VIF — Multicollinearity ────────────────────────────────────────────────
cat("\n── Variance Inflation Factors (VIF) ────────────────────────\n")
vif_vals <- car::vif(model_step)

# vif() returns a matrix for factor terms (GVIF); handle both
if (is.matrix(vif_vals)) {
  vif_df <- as.data.frame(vif_vals) %>%
    rownames_to_column("Variable") %>%
    rename(VIF = `GVIF^(1/(2*Df))`) %>%
    mutate(Flag = case_when(VIF > 10 ~ "⚠ HIGH",
                            VIF > 5  ~ "! MODERATE",
                            TRUE     ~ "✓ OK")) %>%
    arrange(desc(VIF))
} else {
  vif_df <- tibble(Variable = names(vif_vals), VIF = vif_vals) %>%
    mutate(Flag = case_when(VIF > 10 ~ "⚠ HIGH",
                            VIF > 5  ~ "! MODERATE",
                            TRUE     ~ "✓ OK")) %>%
    arrange(desc(VIF))
}
print(vif_df, n = 30)
write_csv(vif_df, here("outputs", "vif_table.csv"))

# ── 9. Coefficient Plot ────────────────────────────────────────────────────────
coef_df <- broom::tidy(model_step, conf.int = TRUE) %>%
  filter(term != "(Intercept)") %>%
  mutate(sig = p.value < 0.05)

# Keep only numeric-ish terms for readability (drop neighborhood levels)
coef_top <- coef_df %>%
  filter(!str_detect(term, "^neighborhood|^bldg_type|^house_style|^sale_cond")) %>%
  arrange(estimate)

ggplot(coef_top, aes(x = estimate, y = fct_reorder(term, estimate),
                     color = sig)) +
  geom_point(size = 2.5) +
  geom_errorbarh(aes(xmin = conf.low, xmax = conf.high), height = 0.3) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  scale_color_manual(values = c("TRUE" = "#2E86AB", "FALSE" = "#BBBBBB"),
                     labels = c("TRUE" = "p < 0.05", "FALSE" = "p ≥ 0.05"),
                     name   = "Significance") +
  labs(title    = "Coefficient Plot — Stepwise AIC Model",
       subtitle = "Effect on log(Sale Price) | 95% CI",
       x = "Estimate (log scale)", y = NULL) +
  theme_diag

ggsave(here("outputs", "plots", "09_coefficient_plot.png"),
       width = 10, height = 7, dpi = 150)

cat("\n✓ Diagnostics complete.\n")

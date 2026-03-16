# =============================================================================
# House Price Prediction — Master Runner
# Run this file to execute the full pipeline in sequence
# =============================================================================

cat("╔══════════════════════════════════════════════════════════╗\n")
cat("║   House Price Prediction — Ames Housing Dataset          ║\n")
cat("║   Multiple Linear Regression + Stepwise AIC              ║\n")
cat("╚══════════════════════════════════════════════════════════╝\n\n")

scripts <- c(
  "R/01_data_preparation.R",
  "R/02_eda.R",
  "R/03_modeling.R",
  "R/04_diagnostics.R"
)

for (s in scripts) {
  cat(sprintf("\n▶ Running %s ...\n", s))
  source(s, echo = FALSE)
  cat(sprintf("✓ %s complete.\n", s))
}

cat("\n\n══ Pipeline Complete ════════════════════════════════════════\n")
cat("Outputs in: outputs/plots/ and outputs/models/\n")

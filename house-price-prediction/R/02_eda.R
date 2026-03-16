# =============================================================================
# House Price Prediction — Exploratory Data Analysis
# =============================================================================

pacman::p_load(tidyverse, here, patchwork, scales, ggcorrplot, GGally)

housing <- readRDS(here("data", "housing_clean.rds"))

theme_ames <- theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(color = "grey40"),
    panel.grid.minor = element_blank()
  )
theme_set(theme_ames)

# ── 1. Target Distribution ────────────────────────────────────────────────────
p1 <- ggplot(housing, aes(x = sale_price)) +
  geom_histogram(bins = 60, fill = "#2E86AB", color = "white", linewidth = 0.2) +
  scale_x_continuous(labels = dollar_format(scale = 1e-3, suffix = "K")) +
  labs(title = "Sale Price Distribution (Raw)",
       x = "Sale Price", y = "Count")

p2 <- ggplot(housing, aes(x = log_sale_price)) +
  geom_histogram(bins = 60, fill = "#A23B72", color = "white", linewidth = 0.2) +
  labs(title = "Sale Price Distribution (Log-transformed)",
       x = "log(Sale Price)", y = "Count")

p1 + p2
ggsave(here("outputs", "plots", "01_price_distribution.png"),
       width = 12, height = 5, dpi = 150)

# ── 2. Key Numeric Predictors vs Sale Price ───────────────────────────────────
num_vars <- c("total_sf", "overall_qual", "house_age", "gr_liv_area",
              "total_baths", "garage_area")

plots <- map(num_vars, function(v) {
  ggplot(housing, aes(x = .data[[v]], y = log_sale_price)) +
    geom_point(alpha = 0.25, size = 0.8, color = "#2E86AB") +
    geom_smooth(method = "lm", se = TRUE, color = "#E63946", linewidth = 0.8) +
    labs(title = v, x = NULL, y = "log(Price)")
})

wrap_plots(plots, ncol = 3) +
  plot_annotation(title = "Key Predictors vs log(Sale Price)",
                  theme = theme(plot.title = element_text(face = "bold", size = 15)))
ggsave(here("outputs", "plots", "02_scatter_predictors.png"),
       width = 14, height = 8, dpi = 150)

# ── 3. Correlation Matrix ─────────────────────────────────────────────────────
num_df <- housing %>%
  select(log_sale_price, total_sf, gr_liv_area, lot_area,
         overall_qual, overall_cond, house_age, remod_age,
         total_baths, garage_cars, exter_qual, kitchen_qual)

corr <- cor(num_df, use = "pairwise.complete.obs")

ggcorrplot(corr,
           method    = "square",
           type      = "upper",
           lab       = TRUE,
           lab_size  = 2.8,
           colors    = c("#4575B4", "white", "#D73027"),
           tl.cex    = 9,
           title     = "Correlation Matrix — Numeric Features") +
  theme(plot.title = element_text(face = "bold"))

ggsave(here("outputs", "plots", "03_correlation_matrix.png"),
       width = 10, height = 9, dpi = 150)

# ── 4. Sale Price by Neighborhood ────────────────────────────────────────────
housing %>%
  group_by(neighborhood) %>%
  summarise(median_price = median(sale_price), n = n()) %>%
  filter(n >= 20) %>%
  ggplot(aes(x = median_price,
             y = fct_reorder(neighborhood, median_price))) +
  geom_col(fill = "#2E86AB") +
  geom_text(aes(label = dollar(median_price, scale = 1e-3, suffix = "K")),
            hjust = -0.1, size = 3) +
  scale_x_continuous(labels = dollar_format(scale = 1e-3, suffix = "K"),
                     expand = expansion(mult = c(0, 0.15))) +
  labs(title    = "Median Sale Price by Neighborhood",
       subtitle = "Neighborhoods with ≥ 20 sales",
       x = "Median Sale Price", y = NULL)

ggsave(here("outputs", "plots", "04_price_by_neighborhood.png"),
       width = 10, height = 8, dpi = 150)

# ── 5. Overall Quality Box Plots ─────────────────────────────────────────────
ggplot(housing, aes(x = factor(overall_qual), y = sale_price,
                    fill = factor(overall_qual))) +
  geom_boxplot(outlier.size = 0.5, show.legend = FALSE) +
  scale_y_continuous(labels = dollar_format(scale = 1e-3, suffix = "K")) +
  scale_fill_viridis_d(option = "C") +
  labs(title = "Sale Price by Overall Quality Rating",
       x = "Overall Quality (1–10)", y = "Sale Price")

ggsave(here("outputs", "plots", "05_price_by_quality.png"),
       width = 10, height = 6, dpi = 150)

cat("✓ All EDA plots saved to outputs/plots/\n")

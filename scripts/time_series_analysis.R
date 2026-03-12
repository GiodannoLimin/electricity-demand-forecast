# =========================================================
# Time Series Analysis
# =========================================================

library(tidyverse)
library(forecast)
library(tseries)

# ---------------------------------------------------------
# 1. Load processed data
# ---------------------------------------------------------
preprocess_path <- if (file.exists("scripts/preprocess.R")) {
  "scripts/preprocess.R"
} else {
  "../scripts/preprocess.R"
}

processed <- source(preprocess_path)$value

df_recent <- processed$df_recent
df_daily  <- processed$df_daily

# ---------------------------------------------------------
# 2. Create results folder if needed
# ---------------------------------------------------------
if (!dir.exists("results")) {
  dir.create("results")
}

# ---------------------------------------------------------
# 3. Convert recent daily data to time series
# ---------------------------------------------------------
# Daily data with weekly seasonality
ts_recent <- ts(df_recent$PJME_MW, frequency = 7)

cat("\nTime series object created.\n")
cat("Length:", length(ts_recent), "\n")
cat("Frequency:", frequency(ts_recent), "\n\n")

# ---------------------------------------------------------
# 4. STL decomposition
# ---------------------------------------------------------
stl_fit <- stl(ts_recent, s.window = "periodic")

png("results/stl_decomposition.png", width = 1000, height = 700)
plot(stl_fit, main = "STL Decomposition of Recent Daily Electricity Demand")
dev.off()

cat("STL decomposition saved to results/stl_decomposition.png\n")

# ---------------------------------------------------------
# 5. ADF stationarity test
# ---------------------------------------------------------
adf_result <- adf.test(ts_recent)

cat("\nADF test result:\n")
print(adf_result)
cat("\n")

capture.output(adf_result, file = "results/adf_test.txt")

# ---------------------------------------------------------
# 6. ACF plot
# ---------------------------------------------------------
png("results/acf_plot.png", width = 900, height = 600)
Acf(ts_recent, main = "ACF - Recent Daily Electricity Demand")
dev.off()

cat("ACF plot saved to results/acf_plot.png\n")

# ---------------------------------------------------------
# 7. PACF plot
# ---------------------------------------------------------
png("results/pacf_plot.png", width = 900, height = 600)
Pacf(ts_recent, main = "PACF - Recent Daily Electricity Demand")
dev.off()

cat("PACF plot saved to results/pacf_plot.png\n")

# ---------------------------------------------------------
# 8. Plot recent daily demand
# ---------------------------------------------------------
p_recent <- ggplot(df_recent, aes(x = Date, y = PJME_MW)) +
  geom_line() +
  labs(
    title = "Recent Daily Electricity Demand",
    x = "Date",
    y = "Demand (MW)"
  ) +
  theme_minimal()

ggsave("results/recent_daily_demand_plot.png", p_recent, width = 10, height = 5)

cat("Recent daily demand plot saved to results/recent_daily_demand_plot.png\n")

# ---------------------------------------------------------
# 9. Plot full daily demand
# ---------------------------------------------------------
p_daily <- ggplot(df_daily, aes(x = Date, y = PJME_MW)) +
  geom_line() +
  labs(
    title = "Full Daily Electricity Demand",
    x = "Date",
    y = "Demand (MW)"
  ) +
  theme_minimal()

ggsave("results/full_daily_demand_plot.png", p_daily, width = 10, height = 5)

cat("Full daily demand plot saved to results/full_daily_demand_plot.png\n")

# ---------------------------------------------------------
# 10. Save STL components
# ---------------------------------------------------------
stl_components <- as.data.frame(stl_fit$time.series)
stl_components$Date <- df_recent$Date
write_csv(stl_components, "results/stl_components.csv")

cat("STL components saved to results/stl_components.csv\n")

# ---------------------------------------------------------
# 11. Return useful objects
# ---------------------------------------------------------
list(
  df_daily = df_daily,
  df_recent = df_recent,
  ts_recent = ts_recent,
  stl_fit = stl_fit,
  adf_result = adf_result
)
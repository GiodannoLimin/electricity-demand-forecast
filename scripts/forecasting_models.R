# =========================================================
# Forecasting Models
# =========================================================

library(tidyverse)
library(forecast)

preprocess_path <- if (file.exists("scripts/preprocess.R")) {
  "scripts/preprocess.R"
} else {
  "../scripts/preprocess.R"
}

processed <- source(preprocess_path)$value

df_recent <- processed$df_recent

if (!dir.exists("results")) {
  dir.create("results")
}

ts_recent <- ts(df_recent$PJME_MW, frequency = 7)

cat("\nForecasting time series created.\n")
cat("Length:", length(ts_recent), "\n")
cat("Frequency:", frequency(ts_recent), "\n\n")

train_size <- length(ts_recent) - 30

ts_train <- ts(ts_recent[1:train_size], frequency = 7)
ts_test_ts <- ts(ts_recent[(train_size + 1):length(ts_recent)], frequency = 7)
ts_test <- as.numeric(ts_test_ts)

train_dates <- df_recent$Date[1:train_size]
test_dates  <- df_recent$Date[(train_size + 1):nrow(df_recent)]

cat("Training observations:", length(ts_train), "\n")
cat("Testing observations:", length(ts_test), "\n\n")

train_test_df <- tibble(
  Date = df_recent$Date,
  Demand = df_recent$PJME_MW,
  Set = c(rep("Train", train_size), rep("Test", length(ts_test)))
)

p_split <- ggplot(train_test_df, aes(x = Date, y = Demand, color = Set)) +
  geom_line(linewidth = 0.8) +
  labs(
    title = "Train/Test Split for Electricity Demand",
    x = "Date",
    y = "Demand (MW)"
  ) +
  theme_minimal()

ggsave("results/train_test_split.png", p_split, width = 10, height = 5)
cat("Train/test split plot saved to results/train_test_split.png\n")

arima_fit <- auto.arima(ts_train, seasonal = TRUE)

cat("ARIMA model summary:\n")
print(summary(arima_fit))
cat("\n")

capture.output(summary(arima_fit), file = "results/arima_model_summary.txt")

arima_fc <- forecast(arima_fit, h = length(ts_test))

png("results/arima_forecast.png", width = 1000, height = 650)
plot(arima_fc, main = "ARIMA Forecast vs Actual")
lines(ts_test_ts, col = "red")
legend("topleft", legend = c("Forecast", "Actual"), col = c("blue", "red"), lty = 1)
dev.off()

cat("ARIMA forecast plot saved to results/arima_forecast.png\n")

ets_fit <- ets(ts_train)

cat("ETS model summary:\n")
print(summary(ets_fit))
cat("\n")

capture.output(summary(ets_fit), file = "results/ets_model_summary.txt")

ets_fc <- forecast(ets_fit, h = length(ts_test))

png("results/ets_forecast.png", width = 1000, height = 650)
plot(ets_fc, main = "ETS Forecast vs Actual")
lines(ts_test_ts, col = "red")
legend("topleft", legend = c("Forecast", "Actual"), col = c("blue", "red"), lty = 1)
dev.off()

cat("ETS forecast plot saved to results/ets_forecast.png\n")

arima_acc <- accuracy(arima_fc, x = ts_test)
ets_acc   <- accuracy(ets_fc, x = ts_test)

cat("ARIMA Accuracy:\n")
print(arima_acc)
cat("\n")

cat("ETS Accuracy:\n")
print(ets_acc)
cat("\n")

accuracy_table <- tibble(
  Model = c("ARIMA", "ETS"),
  RMSE = c(arima_acc[2, "RMSE"], ets_acc[2, "RMSE"]),
  MAE  = c(arima_acc[2, "MAE"], ets_acc[2, "MAE"]),
  MAPE = c(arima_acc[2, "MAPE"], ets_acc[2, "MAPE"])
)

print(accuracy_table)

write_csv(accuracy_table, "results/model_accuracy.csv")
cat("Model accuracy table saved to results/model_accuracy.csv\n")

forecast_comparison <- tibble(
  Date = test_dates,
  Actual = ts_test,
  ARIMA_Forecast = as.numeric(arima_fc$mean),
  ETS_Forecast = as.numeric(ets_fc$mean)
)

write_csv(forecast_comparison, "results/forecast_comparison.csv")
cat("Forecast comparison saved to results/forecast_comparison.csv\n")

p_compare <- ggplot(forecast_comparison, aes(x = Date)) +
  geom_line(aes(y = Actual, color = "Actual"), linewidth = 0.9) +
  geom_line(aes(y = ARIMA_Forecast, color = "ARIMA Forecast"), linewidth = 0.9) +
  geom_line(aes(y = ETS_Forecast, color = "ETS Forecast"), linewidth = 0.9) +
  labs(
    title = "Actual vs Forecasted Electricity Demand",
    x = "Date",
    y = "Demand (MW)",
    color = ""
  ) +
  theme_minimal()

ggsave("results/forecast_comparison_plot.png", p_compare, width = 10, height = 5)
cat("Forecast comparison plot saved to results/forecast_comparison_plot.png\n")

best_model <- accuracy_table %>%
  arrange(RMSE) %>%
  slice(1)

cat("\nBest model based on RMSE:", best_model$Model, "\n")
cat("Best RMSE:", best_model$RMSE, "\n\n")

writeLines(
  c(
    paste("Best model based on RMSE:", best_model$Model),
    paste("Best RMSE:", round(best_model$RMSE, 4))
  ),
  "results/best_model.txt"
)

if (best_model$Model == "ARIMA") {
  final_fit <- auto.arima(ts_recent, seasonal = TRUE)
  final_fc <- forecast(final_fit, h = 30)
} else {
  final_fit <- ets(ts_recent)
  final_fc <- forecast(final_fit, h = 30)
}

png("results/final_30_day_forecast.png", width = 1000, height = 650)
plot(final_fc, main = paste("Final 30-Day Forecast using", best_model$Model))
dev.off()

future_dates <- seq(max(df_recent$Date) + 1, by = "day", length.out = 30)

future_forecast <- tibble(
  Date = future_dates,
  Forecast = as.numeric(final_fc$mean)
)

write_csv(future_forecast, "results/final_30_day_forecast.csv")
cat("Final 30-day forecast saved to results/final_30_day_forecast.csv\n")
cat("Final forecast plot saved to results/final_30_day_forecast.png\n")

fitted_values <- tibble(
  Date = train_dates,
  Actual = as.numeric(ts_train),
  ARIMA_Fitted = as.numeric(fitted(arima_fit)),
  ETS_Fitted = as.numeric(fitted(ets_fit))
)

write_csv(fitted_values, "results/fitted_values.csv")
cat("Fitted values saved to results/fitted_values.csv\n")

list(
  df_recent = df_recent,
  ts_recent = ts_recent,
  ts_train = ts_train,
  ts_test = ts_test_ts,
  arima_fit = arima_fit,
  ets_fit = ets_fit,
  arima_fc = arima_fc,
  ets_fc = ets_fc,
  accuracy_table = accuracy_table,
  best_model = best_model,
  final_fit = final_fit,
  final_fc = final_fc,
  forecast_comparison = forecast_comparison,
  future_forecast = future_forecast
)
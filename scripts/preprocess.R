# =========================================================
# Preprocess Electricity Demand Data
# =========================================================

library(tidyverse)
library(lubridate)

# ---------------------------------------------------------
# 1. Load raw data
# ---------------------------------------------------------
load_data_path <- if (file.exists("scripts/load_data.R")) {
  "scripts/load_data.R"
} else {
  "../scripts/load_data.R"
}

df <- source(load_data_path)$value

# ---------------------------------------------------------
# 2. Create results folder if needed
# ---------------------------------------------------------
if (!dir.exists("results")) {
  dir.create("results")
}

# ---------------------------------------------------------
# 3. Remove missing values
# ---------------------------------------------------------
df <- df %>%
  filter(!is.na(Datetime), !is.na(PJME_MW))

# ---------------------------------------------------------
# 4. Remove duplicate timestamps
# ---------------------------------------------------------
df <- df %>%
  distinct(Datetime, .keep_all = TRUE) %>%
  arrange(Datetime)

# ---------------------------------------------------------
# 5. Create calendar features
# ---------------------------------------------------------
df <- df %>%
  mutate(
    Date = as_date(Datetime),
    Year = year(Datetime),
    Month = month(Datetime),
    Day = day(Datetime),
    Hour = hour(Datetime),
    Weekday = wday(Datetime, label = TRUE, abbr = FALSE)
  )

# ---------------------------------------------------------
# 6. Aggregate hourly data to daily data
# ---------------------------------------------------------
# Use daily average demand
df_daily <- df %>%
  group_by(Date) %>%
  summarise(
    PJME_MW = mean(PJME_MW, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(Date)

# ---------------------------------------------------------
# 7. Create recent subset for time series work
# ---------------------------------------------------------
df_recent <- df_daily %>%
  slice_tail(n = 365)

# ---------------------------------------------------------
# 8. Save processed datasets
# ---------------------------------------------------------
write_csv(df_daily, "results/daily_demand.csv")
write_csv(df_recent, "results/recent_daily_demand.csv")

# ---------------------------------------------------------
# 9. Print summary
# ---------------------------------------------------------
cat("\nPreprocessing complete.\n")
cat("Clean hourly rows:", nrow(df), "\n")
cat("Daily rows:", nrow(df_daily), "\n")
cat(
  "Daily date range:",
  format(min(df_daily$Date)),
  "to",
  format(max(df_daily$Date)),
  "\n"
)
cat("Recent subset rows:", nrow(df_recent), "\n")
cat(
  "Recent subset range:",
  format(min(df_recent$Date)),
  "to",
  format(max(df_recent$Date)),
  "\n\n"
)

print(head(df_daily))
print(summary(df_daily))

# ---------------------------------------------------------
# 10. Return processed objects
# ---------------------------------------------------------
list(
  df_hourly = df,
  df_daily = df_daily,
  df_recent = df_recent
)
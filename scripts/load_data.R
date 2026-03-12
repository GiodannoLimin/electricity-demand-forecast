# =========================================================
# Load Electricity Demand Dataset
# =========================================================

library(tidyverse)
library(lubridate)

data_path <- if (file.exists("data/PJME_hourly.csv")) {
  "data/PJME_hourly.csv"
} else {
  "../data/PJME_hourly.csv"
}

if (!file.exists(data_path)) {
  stop("Dataset not found. Please place PJME_hourly.csv inside the data/ folder.")
}

df <- read_csv(data_path, show_col_types = FALSE)

# Standardize column names
names(df) <- c("Datetime", "PJME_MW")

# Ensure sorted
df <- df %>%
  arrange(Datetime)

cat("\nData loaded successfully.\n")
cat("Number of rows:", nrow(df), "\n")
cat(
  "Date range:",
  format(min(df$Datetime)),
  "to",
  format(max(df$Datetime)),
  "\n\n"
)

print(head(df))
print(summary(df))

df
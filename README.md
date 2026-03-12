# Electricity Demand Forecasting Dashboard

![License](https://img.shields.io/badge/license-MIT-blue)
![Language](https://img.shields.io/badge/language-R-blue)
![Framework](https://img.shields.io/badge/framework-Shiny-orange)

Tech stack: R • Shiny • Plotly • Time Series • ARIMA • ETS

An interactive Shiny dashboard for analyzing electricity demand, exploring time series structure, comparing classical forecasting models, and visualizing 30-day demand projections.

[![Open Dashboard](https://img.shields.io/badge/Open-Dashboard-blue?style=for-the-badge)](https://giodannolimin-electricity-demand-forecast.share.connect.posit.cloud/)

---

![Dashboard Preview](dashboard_preview.png)

---

## Overview

This project analyzes electricity demand data from the PJM East region (PJME) and builds forecasting models using classical time series methods.

The workflow includes:

- data cleaning and preprocessing
- daily aggregation of hourly demand
- STL decomposition
- stationarity analysis
- forecasting with ARIMA and ETS
- interactive visualization through a Shiny dashboard

The goal is to understand demand patterns, compare forecasting performance, and present the results in a clean interactive interface.

---

## Why This Project

Electricity demand is a time-dependent process with trend, seasonality, and short-term fluctuations. This project demonstrates how classical statistical forecasting methods can be combined with interactive visualization to make time series analysis more interpretable and accessible.

---

## Dataset

Source: PJM Interconnection electricity demand dataset

Original frequency:
- Hourly electricity demand

Used in this project:
- Aggregated to daily electricity demand
- Most recent 365 days used for focused modeling and forecasting

Variables:

Variable | Description
Datetime | Timestamp of electricity demand
PJME_MW | Electricity demand in megawatts

---

## Project Structure

electricity-demand-forecast

data/
PJME_hourly.csv

scripts/
load_data.R  
preprocess.R  
time_series_analysis.R  
forecasting_models.R  

dashboard/
app.R  
manifest.json  

results/

dashboard_preview.png  
README.md  
.gitignore

---

## Methods

### Data Processing

The raw hourly dataset is processed by:

- removing missing values
- removing duplicate timestamps
- creating calendar-based features
- aggregating hourly demand into daily averages

### Time Series Analysis

The exploratory analysis includes:

- STL decomposition
- ACF and PACF analysis
- Augmented Dickey–Fuller stationarity testing

These steps help identify trend, seasonality, and time series behavior before forecasting.

---

## Forecasting Models

Two classical forecasting models are implemented and compared.

### ARIMA

- Automatically selected using auto.arima()
- Captures autocorrelation and seasonal structure in the series

### ETS

- Exponential smoothing model for level, trend, and seasonality
- Useful for smoother time series patterns

### Model Evaluation

Models are evaluated using:

- RMSE (Root Mean Squared Error)
- MAE (Mean Absolute Error)
- MAPE (Mean Absolute Percentage Error)

The best model is selected based on RMSE.

---

## Dashboard Features

The dashboard provides an interactive interface for exploring the full forecasting workflow.

### Overview

- Full daily electricity demand history
- Recent demand visualization with adjustable time window
- Highlighted recent analysis window within the long-run series

### Decomposition

- STL trend component
- Seasonal component
- Remainder component

### Model Comparison

- Actual demand vs ARIMA forecast
- Actual demand vs ETS forecast
- Accuracy comparison table

### Forecast

- 30-day forecast using the best-performing model
- 80% and 95% prediction intervals
- Forecast table for projected demand values

### Learn

- Beginner-friendly explanations of time series concepts
- Explanations of STL, RMSE, ARIMA, ETS, and forecast interpretation

---

## Running the Project

Install the required R packages:

install.packages(c(
"shiny",
"plotly",
"tidyverse",
"forecast",
"tseries",
"lubridate",
"bslib"
))

Run the dashboard locally:

setwd("electricity-demand-forecast")
shiny::runApp("dashboard")

---

## Outputs

The project generates outputs such as:

- decomposition plots
- ARIMA and ETS forecast plots
- model comparison tables
- fitted values
- final 30-day forecast outputs

These files are saved in the results/ directory.

---

## Technologies Used

- R
- Shiny
- Plotly
- Tidyverse
- forecast
- tseries
- lubridate
- bslib

---

## Future Improvements

Potential extensions include:

- adding additional forecasting models
- incorporating exogenous predictors such as weather
- extending the dashboard to hourly forecasting
- adding residual diagnostics and model validation views
- improving interactive table functionality

---

## Author

Giodanno Limin  
Applied Statistics Specialist  
University of Toronto
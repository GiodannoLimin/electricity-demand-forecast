# =========================================================
# Shiny Dashboard for Electricity Demand Forecasting
# =========================================================

# ---------------------------------------------------------
# 0. Install/load required packages
# ---------------------------------------------------------
library(shiny)
library(plotly)
library(tidyverse)
library(forecast)
library(bslib)
library(lubridate)
library(tseries)

# ---------------------------------------------------------
# 1. Load data from scripts
# ---------------------------------------------------------
project_root <- normalizePath("..", winslash = "/", mustWork = TRUE)
scripts_dir <- file.path(project_root, "scripts")

processed <- source(file.path(scripts_dir, "preprocess.R"))$value
ts_analysis <- source(file.path(scripts_dir, "time_series_analysis.R"))$value
forecast_results <- source(file.path(scripts_dir, "forecasting_models.R"))$value

df_daily <- processed$df_daily
df_recent <- processed$df_recent

stl_fit <- ts_analysis$stl_fit

accuracy_table <- forecast_results$accuracy_table
best_model <- forecast_results$best_model
forecast_comparison <- forecast_results$forecast_comparison
future_forecast <- forecast_results$future_forecast

# ---------------------------------------------------------
# 2. Create STL dataframe for plotting
# ---------------------------------------------------------
stl_df <- as.data.frame(stl_fit$time.series)
stl_df$Date <- df_recent$Date

# ---------------------------------------------------------
# 3. Reusable card style
# ---------------------------------------------------------
card_style <- "
  background: linear-gradient(135deg,#1e293b,#111827);
  padding: 20px;
  border-radius: 12px;
  min-height: 140px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.35);
"

# ---------------------------------------------------------
# 4. UI
# ---------------------------------------------------------
ui <- fluidPage(
  theme = bslib::bs_theme(
    version = 5,
    bootswatch = "darkly"
  ),

  div(
    style = "margin-bottom: 18px;",
    h1("Electricity Demand Forecasting Dashboard", style = "margin-bottom: 0;"),
    tags$p(
      "Interactive time series analysis using ARIMA and ETS models",
      style = "color: #b8b8b8; margin-top: 6px; font-size: 18px;"
    )
  ),

  sidebarLayout(
    sidebarPanel(
      width = 3,
      style = "
        position: sticky;
        top: 20px;
        height: 90vh;
        overflow-y: auto;
      ",

      h4("Dashboard Controls"),

      sliderInput(
        "recent_days",
        "Recent days to display:",
        min = 30,
        max = 365,
        value = 180,
        step = 30,
        ticks = FALSE
      ),

      selectInput(
        "forecast_model",
        "Forecast series to display:",
        choices = c("ARIMA Forecast", "ETS Forecast", "Both"),
        selected = "Both"
      ),

      hr(),

      h4("Project Summary"),
      p("Dataset: PJME hourly electricity demand"),
      p("Modeling frequency: daily data with weekly seasonality"),
      p("Models used: ARIMA and ETS"),
      p(paste("Best model based on RMSE:", best_model$Model))
    ),

    mainPanel(
      width = 9,

      fluidRow(
        column(
          4,
          div(
            style = card_style,
            h4("Best Model"),
            h2(textOutput("bestModelTextTop"), style = "margin-top: 12px;")
          )
        ),
        column(
          4,
          div(
            style = card_style,
            h4("Best RMSE"),
            h2(textOutput("bestRMSETextTop"), style = "margin-top: 12px;")
          )
        ),
        column(
          4,
          div(
            style = card_style,
            h4("Recent Data Points"),
            h2(textOutput("recentPointsText"), style = "margin-top: 12px;")
          )
        )
      ),

      br(),

      tabsetPanel(
        tabPanel(
          "Demand Overview",
          br(),
          h3("Full Daily Electricity Demand"),
          plotlyOutput("fullDailyPlot", height = "380px"),
          br(),
          h3("Recent Daily Electricity Demand"),
          plotlyOutput("recentDailyPlot", height = "420px")
        ),

        tabPanel(
          "Time Series Decomposition",
          br(),
          h3("Trend Component"),
          plotlyOutput("trendPlot", height = "250px"),
          br(),
          h3("Seasonal Component"),
          plotlyOutput("seasonalPlot", height = "250px"),
          br(),
          h3("Remainder Component"),
          plotlyOutput("remainderPlot", height = "250px")
        ),

        tabPanel(
          "Model Comparison",
          br(),
          h3("Actual vs Forecasted Demand"),
          plotlyOutput("forecastComparisonPlot", height = "500px"),
          br(),
          h3("Model Accuracy"),
          tableOutput("accuracyTable")
        ),

        tabPanel(
          "30-Day Forecast",
          br(),
          h3("Next 30 Days Forecast"),
          plotlyOutput("futureForecastPlot", height = "500px"),
          br(),
          h3("Forecast Table"),
          tableOutput("futureForecastTable")
        ),

        tabPanel(
          "Model Summary",
          br(),
          div(
            style = card_style,
            h3("Selected Best Model"),
            h4(textOutput("bestModelText")),
            h4(textOutput("bestRMSEText"))
          )
        )
      )
    )
  )
)

# ---------------------------------------------------------
# 5. Server
# ---------------------------------------------------------
server <- function(input, output, session) {

  recent_filtered <- reactive({
    req(input$recent_days)
    tail(df_recent, input$recent_days)
  })

  stl_filtered <- reactive({
    req(input$recent_days)
    tail(stl_df, input$recent_days)
  })

  output$bestModelTextTop <- renderText({
    best_model$Model
  })

  output$bestRMSETextTop <- renderText({
    round(best_model$RMSE, 2)
  })

  output$recentPointsText <- renderText({
    nrow(df_recent)
  })

  output$fullDailyPlot <- renderPlotly({
    plot_ly(
      data = df_daily,
      x = ~Date,
      y = ~PJME_MW,
      type = "scatter",
      mode = "lines",
      name = "Demand"
    ) %>%
      layout(
        title = "Full Daily Electricity Demand",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Demand (MW)"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$recentDailyPlot <- renderPlotly({
    plot_ly(
      data = recent_filtered(),
      x = ~Date,
      y = ~PJME_MW,
      type = "scatter",
      mode = "lines",
      name = "Recent Demand"
    ) %>%
      layout(
        title = paste("Recent", input$recent_days, "Days of Electricity Demand"),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Demand (MW)"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$trendPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~trend,
      type = "scatter",
      mode = "lines",
      name = "Trend"
    ) %>%
      layout(
        title = "STL Trend Component",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Trend"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$seasonalPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~seasonal,
      type = "scatter",
      mode = "lines",
      name = "Seasonal"
    ) %>%
      layout(
        title = "STL Seasonal Component",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Seasonal"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$remainderPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~remainder,
      type = "scatter",
      mode = "lines",
      name = "Remainder"
    ) %>%
      layout(
        title = "STL Remainder Component",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Remainder"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$forecastComparisonPlot <- renderPlotly({
    p <- plot_ly(data = forecast_comparison, x = ~Date)

    p <- p %>%
      add_lines(y = ~Actual, name = "Actual")

    if (input$forecast_model == "ARIMA Forecast") {
      p <- p %>%
        add_lines(y = ~ARIMA_Forecast, name = "ARIMA Forecast")
    } else if (input$forecast_model == "ETS Forecast") {
      p <- p %>%
        add_lines(y = ~ETS_Forecast, name = "ETS Forecast")
    } else {
      p <- p %>%
        add_lines(y = ~ARIMA_Forecast, name = "ARIMA Forecast") %>%
        add_lines(y = ~ETS_Forecast, name = "ETS Forecast")
    }

    p %>%
      layout(
        title = "Actual vs Forecasted Electricity Demand",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Demand (MW)"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$accuracyTable <- renderTable({
    accuracy_table %>%
      mutate(
        RMSE = round(RMSE, 2),
        MAE = round(MAE, 2),
        MAPE = round(MAPE, 2)
      )
  })

  output$futureForecastPlot <- renderPlotly({
    plot_ly(
      data = future_forecast,
      x = ~Date,
      y = ~Forecast,
      type = "scatter",
      mode = "lines",
      name = "Forecast"
    ) %>%
      layout(
        title = paste("Next 30 Days Forecast using", best_model$Model),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Forecasted Demand (MW)"),
        hovermode = "x unified",
        spikedistance = -1,
        plot_bgcolor = "#1f2630",
        paper_bgcolor = "#1f2630",
        font = list(color = "#e5e5e5")
      )
  })

  output$futureForecastTable <- renderTable({
    future_forecast %>%
      mutate(Forecast = round(Forecast, 2))
  })

  output$bestModelText <- renderText({
    paste("Best Model:", best_model$Model)
  })

  output$bestRMSEText <- renderText({
    paste("RMSE:", round(best_model$RMSE, 2))
  })
}

# ---------------------------------------------------------
# 6. Run app
# ---------------------------------------------------------
shinyApp(ui = ui, server = server)
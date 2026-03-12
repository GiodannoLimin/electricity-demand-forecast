# =========================================================
# Modern Shiny Dashboard for Electricity Demand Forecasting
# =========================================================

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
final_fc <- forecast_results$final_fc

# ---------------------------------------------------------
# 2. Create STL dataframe for plotting
# ---------------------------------------------------------
stl_df <- as.data.frame(stl_fit$time.series)
stl_df$Date <- df_recent$Date

# ---------------------------------------------------------
# 3. Theme + helpers
# ---------------------------------------------------------
app_theme <- bs_theme(
  version = 5,
  bg = "#0b1020",
  fg = "#e5e7eb",
  primary = "#60a5fa",
  secondary = "#94a3b8",
  success = "#22c55e",
  base_font = font_google("Inter"),
  heading_font = font_google("Inter"),
  code_font = font_google("JetBrains Mono")
)

plot_bg <- "#111827"
paper_bg <- "#111827"
grid_col <- "rgba(148,163,184,0.08)"
font_col <- "#e5e7eb"

plot_layout_base <- list(
  hovermode = "x unified",
  spikedistance = -1,
  plot_bgcolor = plot_bg,
  paper_bgcolor = plot_bg,
  font = list(color = font_col),
  margin = list(l = 60, r = 30, t = 90, b = 55),
  xaxis = list(
    title = "",
    showgrid = TRUE,
    gridcolor = grid_col,
    zeroline = FALSE
  ),
  yaxis = list(
    showgrid = TRUE,
    gridcolor = grid_col,
    zeroline = FALSE
  ),
  legend = list(
    orientation = "h",
    x = 0,
    y = 1.03
  )
)

# ---------------------------------------------------------
# 4. UI
# ---------------------------------------------------------
ui <- fluidPage(
  theme = app_theme,

  tags$head(
    tags$style(HTML("
      html, body {
        background:
          radial-gradient(circle at top left, rgba(59,130,246,0.10), transparent 30%),
          radial-gradient(circle at top right, rgba(99,102,241,0.10), transparent 28%),
          linear-gradient(180deg, #0b1020 0%, #0f172a 100%);
        overscroll-behavior: none;
      }

      .app-shell {
        max-width: 1450px;
        margin: 0 auto;
        padding: 28px 22px 40px 22px;
      }

      .hero {
        position: relative;
        overflow: hidden;
        border: 1px solid rgba(255,255,255,0.08);
        background: linear-gradient(135deg, rgba(15,23,42,0.95), rgba(17,24,39,0.88));
        border-radius: 28px;
        padding: 28px 30px;
        box-shadow: 0 20px 60px rgba(0,0,0,0.32);
        margin-bottom: 22px;
      }

      .hero::after {
        content: '';
        position: absolute;
        top: -60px;
        right: -60px;
        width: 220px;
        height: 220px;
        border-radius: 999px;
        background: radial-gradient(circle, rgba(96,165,250,0.22), transparent 65%);
        filter: blur(8px);
      }

      .hero-badge {
        display: inline-block;
        font-size: 12px;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: #93c5fd;
        background: rgba(96,165,250,0.10);
        border: 1px solid rgba(96,165,250,0.24);
        border-radius: 999px;
        padding: 8px 12px;
        margin-bottom: 12px;
      }

      .hero-title {
        font-size: 44px;
        font-weight: 800;
        line-height: 1.05;
        margin: 0 0 10px 0;
        color: #f8fafc;
      }

      .hero-subtitle {
        max-width: 920px;
        color: #cbd5e1;
        font-size: 17px;
        line-height: 1.7;
        margin-bottom: 16px;
      }

      .hero-tags {
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
      }

      .hero-tag {
        background: rgba(255,255,255,0.05);
        border: 1px solid rgba(255,255,255,0.08);
        color: #dbeafe;
        border-radius: 999px;
        padding: 7px 12px;
        font-size: 13px;
      }

      .metric-card,
      .sidebar-card,
      .panel-card {
        backdrop-filter: blur(6px);
        border: 1px solid rgba(255,255,255,0.07);
        background: linear-gradient(180deg, rgba(17,24,39,0.94), rgba(15,23,42,0.92));
        border-radius: 24px;
        box-shadow: 0 18px 45px rgba(0,0,0,0.24);
      }

      .chart-card {
        backdrop-filter: blur(6px);
        border: 1px solid rgba(255,255,255,0.07);
        background: rgba(17,24,39,0.72);
        border-radius: 20px;
        box-shadow: 0 18px 45px rgba(0,0,0,0.18);
      }

      .info-card,
      .learn-card {
        border: 1px solid rgba(255,255,255,0.07);
        background: linear-gradient(180deg, rgba(17,24,39,0.94), rgba(15,23,42,0.92));
        border-radius: 24px;
        box-shadow: 0 18px 45px rgba(0,0,0,0.24);
      }

      .js-plotly-plot .plotly .cursor-crosshair {
        cursor: crosshair;
      }

      .sidebar-card {
        padding: 22px;
        position: sticky;
        top: 22px;
      }

      .section-label {
        font-size: 12px;
        letter-spacing: 0.14em;
        text-transform: uppercase;
        color: #7dd3fc;
        margin-bottom: 10px;
      }

      .sidebar-title {
        font-size: 24px;
        font-weight: 700;
        margin-bottom: 8px;
        color: #f8fafc;
      }

      .sidebar-text {
        color: #94a3b8;
        line-height: 1.7;
        font-size: 14px;
      }

      .control-group-title {
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.10em;
        color: #93c5fd;
        margin-top: 18px;
        margin-bottom: 10px;
      }

      .metric-card {
        padding: 16px 20px;
        min-height: 110px;
        margin-bottom: 16px;
      }

      .metric-label {
        font-size: 13px;
        text-transform: uppercase;
        letter-spacing: 0.10em;
        color: #93c5fd;
        margin-bottom: 10px;
      }

      .metric-value {
        font-size: 30px;
        font-weight: 800;
        color: #f8fafc;
        line-height: 1.1;
      }

      .metric-sub {
        margin-top: 8px;
        color: #94a3b8;
        font-size: 13px;
      }

      .panel-card {
        padding: 22px;
        margin-bottom: 20px;
      }

      .panel-title {
        font-size: 28px;
        font-weight: 750;
        margin-bottom: 6px;
        color: #f8fafc;
      }

      .panel-subtitle {
        color: #94a3b8;
        line-height: 1.7;
        font-size: 15px;
        margin-bottom: 16px;
      }

      .info-card, .learn-card {
        padding: 18px 18px 16px 18px;
        height: 100%;
      }

      .info-card h4, .learn-card h4 {
        font-size: 17px;
        font-weight: 700;
        margin-top: 0;
        margin-bottom: 8px;
        color: #f8fafc;
      }

      .info-card p, .learn-card p {
        color: #cbd5e1;
        line-height: 1.7;
        margin-bottom: 0;
        font-size: 14px;
      }

      .nav-tabs {
        border-bottom: 1px solid rgba(255,255,255,0.08);
        margin-bottom: 20px;
      }

      .nav-tabs > li > a {
        color: #cbd5e1 !important;
        background: transparent !important;
        border: none !important;
        border-bottom: 2px solid transparent !important;
        font-weight: 600;
        padding: 12px 16px;
      }

      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color: #f8fafc !important;
        border: none !important;
        border-bottom: 2px solid #60a5fa !important;
        background: transparent !important;
      }

      .tab-content {
        padding-top: 4px;
      }

      .chart-card {
        padding: 16px;
        margin-bottom: 18px;
      }

      .chart-title {
        font-size: 22px;
        font-weight: 720;
        color: #f8fafc;
        margin-bottom: 6px;
      }

      .chart-note {
        color: #94a3b8;
        font-size: 14px;
        line-height: 1.7;
        margin-bottom: 12px;
      }

      .table-wrap table {
        width: 100%;
        background: transparent;
        color: #e5e7eb;
      }

      .table-wrap thead th {
        background: rgba(255,255,255,0.04);
        color: #bfdbfe;
        border-bottom: 1px solid rgba(255,255,255,0.08) !important;
        padding: 12px !important;
      }

      .table-wrap tbody td {
        border-top: 1px solid rgba(255,255,255,0.06) !important;
        padding: 12px !important;
      }

      .form-control,
      .selectize-input,
      .irs--shiny .irs-bar,
      .irs--shiny .irs-single,
      .irs--shiny .irs-from,
      .irs--shiny .irs-to {
        border-radius: 12px !important;
      }

      .form-control, .selectize-input {
        background-color: rgba(255,255,255,0.05) !important;
        color: #f8fafc !important;
        border: 1px solid rgba(255,255,255,0.10) !important;
      }

      .selectize-dropdown {
        background: #111827 !important;
        color: #f8fafc !important;
        border: 1px solid rgba(255,255,255,0.10) !important;
      }

      .irs--shiny .irs-bar {
        background: #60a5fa !important;
        border-top: 1px solid #60a5fa !important;
        border-bottom: 1px solid #60a5fa !important;
      }

      .irs--shiny .irs-handle {
        background: #bfdbfe !important;
        border: 1px solid #60a5fa !important;
      }

      @media (max-width: 991px) {
        .hero-title {
          font-size: 34px;
        }
        .sidebar-card {
          position: static;
          margin-bottom: 20px;
        }
      }
    "))
  ),

  div(
    class = "app-shell",

    div(
      class = "hero",
      div(class = "hero-badge", "Interactive Time Series Dashboard"),
      h1(class = "hero-title", "Electricity Demand Forecasting"),
      p(
        class = "hero-subtitle",
        "A modern forecasting dashboard for analyzing daily electricity demand patterns, ",
        "comparing ARIMA and ETS models, examining STL decomposition, and exploring ",
        "short-term future demand projections."
      ),
      div(
        class = "hero-tags",
        span(class = "hero-tag", "ARIMA"),
        span(class = "hero-tag", "ETS"),
        span(class = "hero-tag", "STL Decomposition"),
        span(class = "hero-tag", "Daily Aggregation"),
        span(class = "hero-tag", "Interactive Plotly Charts")
      )
    ),

    fluidRow(
      column(
        width = 3,
        div(
          class = "sidebar-card",

          div(class = "section-label", "Controls"),
          div(class = "sidebar-title", "Analysis Panel"),
          p(
            class = "sidebar-text",
            "Adjust the time window, choose which forecast model to compare, and explore ",
            "how demand patterns change across trend, seasonality, and short-term forecasts."
          ),

          conditionalPanel(
            condition = "input.main_tab == 'Overview' || input.main_tab == 'Decomposition'",
            div(class = "control-group-title", "Recent Window"),
            sliderInput(
              "recent_days",
              label = "Number of recent days used in focused views",
              min = 30,
              max = 365,
              value = 180,
              step = 30,
              ticks = FALSE
            )
          ),

          conditionalPanel(
            condition = "input.main_tab == 'Model Comparison'",
            div(class = "control-group-title", "Forecast View"),
            selectInput(
              "forecast_model",
              label = "Choose the forecast series displayed in the comparison plot",
              choices = c("ARIMA Forecast", "ETS Forecast", "Both"),
              selected = "Both"
            )
          ),

          tags$hr(style = "border-color: rgba(255,255,255,0.08); margin: 22px 0;"),

          div(class = "section-label", "About This Project"),
          p(class = "sidebar-text", HTML(
            "<strong style='color:#f8fafc;'>Dataset:</strong> PJME hourly electricity demand<br><br>
             <strong style='color:#f8fafc;'>Modeling frequency:</strong> daily aggregated time series with weekly seasonality<br><br>
             <strong style='color:#f8fafc;'>Forecasting models:</strong> ARIMA and ETS<br><br>
             <strong style='color:#f8fafc;'>Selected best model:</strong> "
          )),
          tags$div(
            style = "margin-top: -6px; margin-bottom: 12px; color: #bfdbfe; font-weight: 700;",
            textOutput("bestModelTextSide", inline = TRUE)
          ),

          div(class = "section-label", "How To Read It"),
          p(
            class = "sidebar-text",
            "Use the Overview tab for demand behavior, Decomposition to separate trend and seasonality, ",
            "Model Comparison to compare forecast quality, and Forecast to inspect the next 30-day projection."
          )
        )
      ),

      column(
        width = 9,

        fluidRow(
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Best Model"),
              div(class = "metric-value", textOutput("bestModelTextTop", inline = TRUE)),
              div(class = "metric-sub", "Lowest error among evaluated models")
            )
          ),
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Lowest RMSE"),
              div(class = "metric-value", textOutput("bestRMSETextTop", inline = TRUE)),
              div(class = "metric-sub", "Rounded to 2 decimal places")
            )
          ),
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Data Range"),
              div(class = "metric-value", textOutput("dataRangeText", inline = TRUE)),
              div(class = "metric-sub", "Coverage of the daily dataset")
            )
          ),
          column(
            3,
            div(
              class = "metric-card",
              div(class = "metric-label", "Forecast Horizon"),
              div(class = "metric-value", "30 Days"),
              div(class = "metric-sub", "Short-term projected demand")
            )
          )
        ),

        div(
          class = "panel-card",
          div(class = "panel-title", "Explore Demand, Models, and Forecast Behavior"),
          p(
            class = "panel-subtitle",
            "This dashboard is designed to help users move from raw demand history to interpretable time-series components and model-based forecasting. ",
            "It combines interactive charts with short explanations so the results feel easier to understand."
          ),

          tabsetPanel(
            id = "main_tab",

            tabPanel(
              "Overview",

              div(
                class = "chart-card",
                div(class = "chart-title", "Full Daily Electricity Demand"),
                div(
                  class = "chart-note",
                  "This chart shows the full daily demand history after aggregating the original hourly PJME data. ",
                  "The highlighted band marks the recent window selected in the control panel, so users can connect the zoomed analysis to the full historical context."
                ),
                plotlyOutput("fullDailyPlot", height = "420px")
              ),

              div(
                class = "chart-card",
                div(class = "chart-title", "Recent Demand Window"),
                div(
                  class = "chart-note",
                  "This filtered view focuses on the most recent portion of the series selected in the control panel. ",
                  "It is useful for examining local movement, short-term volatility, and recent seasonal patterns."
                ),
                plotlyOutput("recentDailyPlot", height = "420px")
              ),

              fluidRow(
                column(
                  6,
                  div(
                    class = "info-card",
                    h4("Why use daily demand?"),
                    p("The original data is hourly, but daily aggregation reduces noise and makes medium-term patterns easier to interpret. This is especially useful when comparing forecasting models and decomposition results.")
                  )
                ),
                column(
                  6,
                  div(
                    class = "info-card",
                    h4("What should you look for?"),
                    p("Look for recurring cycles, structural changes, spikes, and changes in recent variability. Those patterns often influence how well ARIMA or ETS performs.")
                  )
                )
              )
            ),

            tabPanel(
              "Decomposition",

              div(
                class = "chart-card",
                div(class = "chart-title", "Trend Component"),
                div(
                  class = "chart-note",
                  "The trend captures the smoother long-run movement in the demand series after removing repeating seasonal fluctuations."
                ),
                plotlyOutput("trendPlot", height = "300px")
              ),

              div(
                class = "chart-card",
                div(class = "chart-title", "Seasonal Component"),
                div(
                  class = "chart-note",
                  "The seasonal component shows recurring cyclical behavior. In this project, weekly structure is especially important after daily aggregation."
                ),
                plotlyOutput("seasonalPlot", height = "300px")
              ),

              div(
                class = "chart-card",
                div(class = "chart-title", "Remainder Component"),
                div(
                  class = "chart-note",
                  "The remainder contains the irregular portion of the series not explained by trend or seasonality. Large spikes may indicate shocks, anomalies, or model difficulty."
                ),
                plotlyOutput("remainderPlot", height = "300px")
              ),

              fluidRow(
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("What is STL?"),
                    p("STL stands for Seasonal and Trend decomposition using Loess. It separates a time series into trend, seasonal, and remainder components to make the structure easier to interpret.")
                  )
                ),
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("Why decomposition matters"),
                    p("A forecasting model often performs better when the structure of the series is understood first. Decomposition helps identify whether the data is dominated by trend, stable seasonality, or irregular noise.")
                  )
                ),
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("How to interpret remainder"),
                    p("A smaller and less structured remainder suggests the main patterns were captured well. Large erratic remainder values may indicate difficult-to-predict movement.")
                  )
                )
              )
            ),

            tabPanel(
              "Model Comparison",

              div(
                class = "chart-card",
                div(class = "chart-title", "Actual vs Forecasted Demand"),
                div(
                  class = "chart-note",
                  "Compare the observed demand series against the selected forecast outputs. This view helps assess whether ARIMA or ETS tracks the actual pattern more closely."
                ),
                plotlyOutput("forecastComparisonPlot", height = "520px")
              ),

              div(
                class = "chart-card table-wrap",
                div(class = "chart-title", "Model Accuracy Summary"),
                div(
                  class = "chart-note",
                  "RMSE measures the typical size of forecast errors, MAE measures average absolute error, and MAPE expresses error relative to the true scale of demand."
                ),
                tableOutput("accuracyTable")
              ),

              fluidRow(
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("ARIMA"),
                    p("ARIMA models autocorrelation and differencing structure in a time series. It is often useful when the data shows strong temporal dependence and can be made approximately stationary.")
                  )
                ),
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("ETS"),
                    p("ETS stands for Error, Trend, and Seasonality. It is often effective when the time series has stable level, trend, and seasonal patterns that can be smoothed over time.")
                  )
                ),
                column(
                  4,
                  div(
                    class = "learn-card",
                    h4("How to compare them"),
                    p("The best model is not just the one that looks visually smoother. It should also minimize forecast error metrics and follow the actual series closely during the evaluation period.")
                  )
                )
              )
            ),

            tabPanel(
              "Forecast",

              div(
                class = "chart-card",
                div(class = "chart-title", "30-Day Forecast"),
                div(
                  class = "chart-note",
                  "This chart shows the projected electricity demand for the next 30 days using the selected best-performing model, along with 80% and 95% prediction intervals to communicate forecast uncertainty."
                ),
                plotlyOutput("futureForecastPlot", height = "520px")
              ),

              div(
                class = "chart-card table-wrap",
                div(class = "chart-title", "Forecast Table"),
                div(
                  class = "chart-note",
                  "The table below provides the projected daily demand values used in the forecast chart."
                ),
                tableOutput("futureForecastTable")
              ),

              fluidRow(
                column(
                  6,
                  div(
                    class = "info-card",
                    h4("How should forecast values be used?"),
                    p("These values are model-based projections, not guaranteed outcomes. They are most useful for planning, comparison, and understanding short-term expected demand behavior.")
                  )
                ),
                column(
                  6,
                  div(
                    class = "info-card",
                    h4("What affects forecast quality?"),
                    p("Forecast accuracy depends on how stable the recent pattern is, whether structural changes occurred, and whether the selected model captures the trend and seasonality well.")
                  )
                )
              )
            ),

            tabPanel(
              "Learn",

              fluidRow(
                column(
                  6,
                  div(
                    class = "learn-card",
                    h4("What is a time series?"),
                    p("A time series is a sequence of observations collected over time. In this project, electricity demand is observed repeatedly and modeled as a structured temporal process.")
                  )
                ),
                column(
                  6,
                  div(
                    class = "learn-card",
                    h4("What is seasonality?"),
                    p("Seasonality refers to patterns that repeat at regular intervals. Electricity demand often shows repeated cycles due to behavioral, weather, and operational factors.")
                  )
                )
              ),
              br(),
              fluidRow(
                column(
                  6,
                  div(
                    class = "learn-card",
                    h4("What does RMSE mean?"),
                    p("RMSE stands for root mean squared error. Lower RMSE means the forecast is, on average, closer to the actual observed values, with larger errors penalized more heavily.")
                  )
                ),
                column(
                  6,
                  div(
                    class = "learn-card",
                    h4("Why compare models?"),
                    p("Different models capture different structures. Comparing ARIMA and ETS helps determine which approach better fits the observed demand dynamics in this dataset.")
                  )
                )
              ),
              br(),
              fluidRow(
                column(
                  12,
                  div(
                    class = "learn-card",
                    h4("Project takeaway"),
                    p("This dashboard is not only a forecasting tool but also a learning interface: it connects raw demand data, decomposition, forecast comparison, and future projections in one interpretable workflow.")
                  )
                )
              )
            )
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

  output$bestModelTextSide <- renderText({
    best_model$Model
  })

  output$bestRMSETextTop <- renderText({
    format(round(best_model$RMSE, 2), nsmall = 2)
  })

  output$dataRangeText <- renderText({
    paste(format(min(df_daily$Date), "%Y"), "\u2013", format(max(df_daily$Date), "%Y"))
  })

  output$fullDailyPlot <- renderPlotly({
    recent_start <- max(df_recent$Date) - days(input$recent_days - 1)

    plot_ly(
      data = df_daily,
      x = ~Date,
      y = ~PJME_MW,
      type = "scatter",
      mode = "lines",
      name = "Demand",
      line = list(color = "#60a5fa", width = 2.2)
    ) %>%
      layout(
        title = list(text = "Long-Run Demand History"),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Demand (MW)")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend,
        shapes = list(
          list(
            type = "rect",
            xref = "x",
            yref = "paper",
            x0 = recent_start,
            x1 = max(df_recent$Date),
            y0 = 0,
            y1 = 1,
            fillcolor = "rgba(56,189,248,0.10)",
            line = list(width = 0)
          )
        ),
        annotations = list(
          list(
            x = recent_start,
            y = 1.08,
            xref = "x",
            yref = "paper",
            text = paste("Selected recent window:", input$recent_days, "days"),
            showarrow = FALSE,
            font = list(color = "#93c5fd", size = 12)
          )
        )
      )
  })

  output$recentDailyPlot <- renderPlotly({
    plot_ly(
      data = recent_filtered(),
      x = ~Date,
      y = ~PJME_MW,
      type = "scatter",
      mode = "lines",
      name = "Recent Demand",
      line = list(color = "#38bdf8", width = 2.4)
    ) %>%
      layout(
        title = list(text = paste("Zoomed View:", input$recent_days, "Recent Days")),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Demand (MW)")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$trendPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~trend,
      type = "scatter",
      mode = "lines",
      name = "Trend",
      line = list(color = "#818cf8", width = 2.2)
    ) %>%
      layout(
        title = list(text = "STL Trend"),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Trend")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$seasonalPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~seasonal,
      type = "scatter",
      mode = "lines",
      name = "Seasonal",
      line = list(color = "#22d3ee", width = 2.2)
    ) %>%
      layout(
        title = list(text = "STL Seasonal Pattern"),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Seasonal")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$remainderPlot <- renderPlotly({
    plot_ly(
      data = stl_filtered(),
      x = ~Date,
      y = ~remainder,
      type = "scatter",
      mode = "lines",
      name = "Remainder",
      line = list(color = "#f59e0b", width = 1.9)
    ) %>%
      layout(
        title = list(text = "STL Remainder"),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Remainder")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$forecastComparisonPlot <- renderPlotly({
    p <- plot_ly(data = forecast_comparison, x = ~Date)

    p <- p %>%
      add_lines(
        y = ~Actual,
        name = "Actual",
        line = list(color = "#e5e7eb", width = 2.8)
      )

    if (input$forecast_model == "ARIMA Forecast") {
      p <- p %>%
        add_lines(
          y = ~ARIMA_Forecast,
          name = "ARIMA Forecast",
          line = list(color = "#60a5fa", width = 2.2)
        )
    } else if (input$forecast_model == "ETS Forecast") {
      p <- p %>%
        add_lines(
          y = ~ETS_Forecast,
          name = "ETS Forecast",
          line = list(color = "#22c55e", width = 2.2)
        )
    } else {
      p <- p %>%
        add_lines(
          y = ~ARIMA_Forecast,
          name = "ARIMA Forecast",
          line = list(color = "#60a5fa", width = 2.2)
        ) %>%
        add_lines(
          y = ~ETS_Forecast,
          name = "ETS Forecast",
          line = list(color = "#22c55e", width = 2.2)
        )
    }

    p %>%
      layout(
        title = list(text = "Actual vs Forecasted Demand"),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Demand (MW)")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$accuracyTable <- renderTable({
    accuracy_table %>%
      mutate(
        RMSE = round(RMSE, 2),
        MAE = round(MAE, 2),
        MAPE = round(MAPE, 2)
      )
  }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "m")

  output$futureForecastPlot <- renderPlotly({
    forecast_plot_df <- future_forecast %>%
      mutate(
        Lo80 = as.numeric(final_fc$lower[, 1]),
        Hi80 = as.numeric(final_fc$upper[, 1]),
        Lo95 = as.numeric(final_fc$lower[, 2]),
        Hi95 = as.numeric(final_fc$upper[, 2])
      )

    plot_ly(data = forecast_plot_df, x = ~Date) %>%
      add_ribbons(
        ymin = ~Lo95, ymax = ~Hi95,
        name = "95% Interval",
        fillcolor = "rgba(56,189,248,0.10)",
        line = list(color = "transparent")
      ) %>%
      add_ribbons(
        ymin = ~Lo80, ymax = ~Hi80,
        name = "80% Interval",
        fillcolor = "rgba(56,189,248,0.20)",
        line = list(color = "transparent")
      ) %>%
      add_lines(
        y = ~Forecast,
        name = "Forecast",
        line = list(color = "#38bdf8", width = 2.5)
      ) %>%
      add_markers(
        y = ~Forecast,
        name = "Forecast Points",
        marker = list(size = 5, color = "#93c5fd"),
        showlegend = FALSE
      ) %>%
      layout(
        title = list(text = paste("Next 30 Days Forecast using", best_model$Model)),
        xaxis = c(plot_layout_base$xaxis, list(title = "Date")),
        yaxis = c(plot_layout_base$yaxis, list(title = "Forecasted Demand (MW)")),
        hovermode = plot_layout_base$hovermode,
        spikedistance = plot_layout_base$spikedistance,
        plot_bgcolor = plot_layout_base$plot_bgcolor,
        paper_bgcolor = plot_layout_base$paper_bgcolor,
        font = plot_layout_base$font,
        margin = plot_layout_base$margin,
        legend = plot_layout_base$legend
      )
  })

  output$futureForecastTable <- renderTable({
    future_forecast %>%
      mutate(
        `Point Forecast` = round(Forecast, 2),
        `80% Lower` = round(as.numeric(final_fc$lower[, 1]), 2),
        `80% Upper` = round(as.numeric(final_fc$upper[, 1]), 2),
        `95% Lower` = round(as.numeric(final_fc$lower[, 2]), 2),
        `95% Upper` = round(as.numeric(final_fc$upper[, 2]), 2)
      ) %>%
      select(Date, `Point Forecast`, `80% Lower`, `80% Upper`, `95% Lower`, `95% Upper`)
  }, striped = TRUE, hover = TRUE, bordered = FALSE, spacing = "m")
}

# ---------------------------------------------------------
# 6. Run app
# ---------------------------------------------------------
shinyApp(ui = ui, server = server)
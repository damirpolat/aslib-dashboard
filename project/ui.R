library(shiny)
library(scatterD3)
library(shinyFiles)
library(shinythemes)
library(shinydashboard)

ui = dashboardPage(
  dashboardHeader(title = "Visualize Algorithm Selection Experiments", 
                  titleWidth = 440),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Input", tabName = "inputs", icon = icon("folder-open")),
      menuItem("Comparison", tabName = "compare", icon = icon("balance-scale"))
    )
  ),
  dashboardBody(
    tabItems(
      # input tab
      tabItem(tabName = "inputs",
        fluidRow(
          column(3,
            uiOutput("scenario_loader"),
            uiOutput("selector1_loader"),
            uiOutput("selector2_loader"),
            actionButton("run", "Run!")
          ),
          column(width = 2,
                 selectInput("scenario_type", label = h4(strong("Scenario source")),
                             choices = c("ASlib", "Custom")),
                 selectInput("selector1_type", label = h4(strong("Selector source")),
                             choices = c("mlr/llama", "Custom")),
                 selectInput("selector2_type", label = h4(strong("Selector source")),
                             choices = c("mlr/llama", "Custom"))
          )
        ),
        br(),
        br(),
        # summary
        column(width = 4,
          htmlOutput("scenario_title"),
          verbatimTextOutput("scenario_summary")
        ),
        column(width = 2,
          htmlOutput("selector1_title"),
          verbatimTextOutput("selector1_summary")
        ),
        column(width = 2,
          htmlOutput("selector2_title"),
          verbatimTextOutput("selector2_summary")
        )
      ),
      # comparison tab
      tabItem(tabName = "compare", 
        fluidRow(
          column(10, offset = 0, scatterD3Output("plot1")), 
          column(2,
                 selectInput("metric", "Select metric", choices = c("mcp", "par10")),
                 htmlOutput("summary")
          )
        )
      )
    )
  )
)
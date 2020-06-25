library(shiny)
library(scatterD3)
library(shinyFiles)
library(shinythemes)
library(shinydashboard)


# line break
linebreak = function(n) {
  HTML(strrep(br(), n))
}

ui = dashboardPage(
  dashboardHeader(title = "Visualize Algorithm Selection Experiments", 
                  titleWidth = 440),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Input", tabName = "inputs", icon = icon("file-import")),
      menuItem("Comparison", tabName = "compare", icon = icon("chart-area"))
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
        linebreak(2),
        # summary
        column(width = 4,
          htmlOutput("scenario_title"),
          verbatimTextOutput("scenario_summary")
        ),
        column(width = 6, offset = 1,
          htmlOutput("perf_title"),
          verbatimTextOutput("algo_perf")
        )
      ),
      # comparison tab
      tabItem(tabName = "compare", 
        fluidRow(
          column(10, offset = 0, scatterD3Output("plot1")), 
          column(2,
                 selectInput("metric", "Select metric", choices = c("mcp", "par10")),
                 htmlOutput("summary")
          ),
          linebreak(10),
          column(width = 1,
            radioButtons("x_axis", label = "x-axis", 
              choices = c("algorithm selector", "single best solver", "virtual best solver"),
              selected = "algorithm selector")
          ),
          column(width = 1,
            radioButtons("y_axis", label = "y-axis", 
              choices = c("algorithm selector", "single best solver", "virtual best solver"),
              selected = "algorithm selector")
          )
        )
      )
    )
  )
)

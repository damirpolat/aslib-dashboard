library(shiny)
library(scatterD3)
library(shinyFiles)
library(shinythemes)
library(shinydashboard)
library(plotly)
library(DT)


# line break
linebreak = function(n) {
  HTML(strrep(br(), n))
}

ui = dashboardPage(
  dashboardHeader(title = "ASlib Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Input", tabName = "inputs", icon = icon("file-import")),
      menuItem("Comparison", tabName = "compare", icon = icon("chart-area")),
      menuItem("Consistency", tabName = "consistency", icon = icon("chart-line")),
      menuItem("Errors", tabName = "errors", icon = icon("chart-bar"))
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
          # summary
          column(width = 4,
                 htmlOutput("scenario_title"),
                 verbatimTextOutput("scenario_summary")
          ),
          column(width = 8, offset = 0,
                 htmlOutput("perf_title"),
                 DT::dataTableOutput("algo_perf"), style = "overflow-y: scroll;overflow-x: scroll;"
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
      ),
      tabItem(tabName = "consistency", 
        fluidRow(
          column(width = 10, 
                 plotlyOutput("plot2", width = "100%", height = "700px")), 
          column(2,
                 selectInput("metric_cons", "Select metric", choices = c("mcp", "par10"))
          ),
          linebreak(10),
          column(width = 1,
             radioButtons("method_1", label = "method-1", 
                          choices = c("algorithm selector", "single best solver", "virtual best solver"),
                          selected = "algorithm selector")
          ),
          column(width = 1,
             radioButtons("method_2", label = "method-2", 
                          choices = c("algorithm selector", "single best solver", "virtual best solver"),
                          selected = "algorithm selector")
          )
        )
      ),
      tabItem(tabName = "errors",
        fluidRow(
          column(width = 10, 
                 plotlyOutput("errors", width = "100%", height = "700px")),
          column(width = 2, 
                 radioButtons("barplot", label = h3("Ratio Type"), 
                              choices = list("(selector 1 / selector 2) - 1" = "ratio1",
                                             "(selector 2 / selector 1) - 1" = "ratio2"),
                              selected = "ratio1"
                 )
                )
        )
      )
    )
  )
)

# compareSelectors.R
# Damir Pulatov
# cannot access selectInput of main app ui from within modules
# need to split into more refined modules

library(shiny)
library(mlr)
library(llama)
library(aslib)
library(purrr)
library(scatterD3)
library(shinyFiles)
source("./helpers.R")
source("./modules.R")

set.seed(1L)

# reference lines for scatter plot
default_lines = data.frame(slope = c(0, Inf, 1), intercept = c(0, 0, 0), 
                           stroke_width = 1, stroke_dasharray = 5)


# Define UI 
ui = fluidPage(
  titlePanel(strong("Comparing Selectors")),
  p("Compare algorithm selectors with ASlib scenarios"),
  fluidRow(
    column(2,
           scenarioInput("scenario"),
           textInput("selector1", label = h4(strong("Type learner name")),
                     placeholder = "ex. Random Forest", value = "regr.featureless"),
           textInput("selector2", label = h4(strong("Type learner name")),
                     placeholder = "ex. Random Forest", value = "regr.featureless"),
           actionButton("run", "Run!")
    ), 
    column(1,
           scenarioSourceUI("source"), 
           selectInput("selector1_source", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom")),
           selectInput("selector2_source", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom"))
    ),
    #column(7, offset = 0, scatterD3Output("plot1")), 
    column(7, offset = 0, testUI("test")),
    column(2,
           selectInput("metric", "Select metric", choices = c("mcp", "par10")),
           tableOutput("summary")
    ),
    mainPanel()
  )
)


# Define server logic 
server = function(input, output) {
  source = callModule(scenarioSourceServer, "source")
  load_scenario = callModule(scenarioServer, "scenario", source = source, run = reactive(input$run))
  callModule(testServer, "test", text = reactive(load_scenario$data()))
  
  lines = reactive({ default_lines })
  learner1 = eventReactive(input$run, {
    makeImputeWrapper(learner = setHyperPars(makeLearner(input$selector1)),
                      classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                                     factor = imputeConstant("NA"), character = imputeConstant("NA")))
  })
  
  learner2 = eventReactive(input$run, {
    makeImputeWrapper(learner = setHyperPars(makeLearner(input$selector2)),
                      classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                                     factor = imputeConstant("NA"), character = imputeConstant("NA")))
  })
  
 
}

# Run the app 
shinyApp(ui = ui, server = server)
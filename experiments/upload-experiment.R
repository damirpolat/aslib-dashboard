# compareSelectors.R
# Damir Pulatov

library(shiny)
library(mlr)
library(llama)
library(aslib)
library(purrr)
library(scatterD3)
library(shinyFiles)
source("../helpers.R")

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
           uiOutput("scenario_loader"),
           actionButton("run", "Run!")
    ), 
    column(1,
           selectInput("scenario_type", label = h5(strong("Scenario source")),
                       choices = c("ASlib", "Custom"))
    ),
    column(2, offset = 0, textOutput("p1")), 
    column(2, offset = 0, textOutput("p2")),     
    column(2, textOutput("ids")),
    mainPanel()
  )
)

# Define server logic 
server = function(input, output) {
  
  shinyDirChoose(
    input,
    'scenario_upload',
    roots = c(home = '~'),
    filetypes = c('', 'txt', 'arff', 'csv')
  )
  
  # dynamic UI for selecting scenarios
  output$scenario_loader = renderUI({
    switch(input$scenario_type,
           "ASlib" = textInput("scenario", label = h4(strong("Type ASlib scenario")),
                               placeholder = "ex. SAT11-INDU", value = "SAT11-INDU"),
           "Custom" =  list(shinyDirButton("scenario_upload", label = "Upload scenario",
                                           "Select directory with scenario"),
                            verbatimTextOutput("scenario_dir", placeholder = TRUE))
    )
  })
  
  # set up default directory for printing
  global = reactiveValues(datapath = getwd())
  scenario_dir = reactive(input$scenario_upload)
  output$scenario_dir = renderText({
    global$datapath
  })
  
  # print updated scenario directory
  observeEvent(ignoreNULL = TRUE,
               eventExpr = {
                 input$scenario_upload
               },
               handlerExpr = {
                 if (!"path" %in% names(scenario_dir())) return()
                 home = normalizePath("~")
                 global$datapath =
                   file.path(home, paste(unlist(scenario_dir()$path[-1]), collapse = .Platform$file.sep))
               }
  )
  
  scenario = reactive(input$scenario)
  # function to load ASlib scenario
  load_scenario = eventReactive(input$run, {
    getCosealASScenario(scenario())
    #read_scenario(input$scenario_type, global$datapath, input$scenario)
  })
  
  #printable = reactive(sprintf("%s", load_scenario()))
  
  # convert data into llama format
  scenario_data = reactive(get_data(load_scenario()))
  ids = reactive(get_ids(scenario_data()))

  output$ids = renderPrint({
    print(getCosealASScenario(scenario())$algo.runs)
  })
}

# Run the app 
shinyApp(ui = ui, server = server)
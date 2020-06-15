# compareSelectors.R
# Damir Pulatov
options(shiny.maxRequestSize=100*1024^2)

library(shiny)
library(mlr)
library(llama)
library(aslib)
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
           fileInput("selector1_upload", label = "Upload selector results",
                     accept = c(".RData", ".rds")),
           actionButton("run", "Run!")
    ), 
    column(1,
           selectInput("scenario_type", label = h5(strong("Scenario source")),
                       choices = c("ASlib", "Custom"))
    ),
    column(7, offset = 0, verbatimTextOutput("plot1")), 
    column(2,
           selectInput("metric", "Select metric", choices = c("mcp", "par10")),
           tableOutput("summary")
    ),
    mainPanel()
  )
)

# Define server logic 
server = function(input, output) {
  lines = reactive({ default_lines })
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
  
  
  file1 = eventReactive(input$run, {
    req(input$selector1_upload)
    input$selector1_upload
  })
  
  selector1 = reactive({
    req(input$selector1_upload)
    create_model(type = "Custom", 
                 learner_name = NULL, 
                 file_name = input$selector1_upload,
                 data = scenario_data())
  })
  
  
  # function to load ASlib scenario
  scenario_data = eventReactive(input$run, {
    get_data(read_scenario(input$scenario_type, global$datapath, input$scenario))
  })
  
  # convert data into llama format
  #scenario_data = reactive(get_data(load_scenario()))
  get_ids = reactive(scenario_data()$data[unlist(scenario_data()$test), scenario_data()$ids]) 
  
  # compute metrics of interest
  penalties1 = reactive({
    #req(input$)
    misclassificationPenalties(scenario_data(), selector1())
  })
  
 
  # make names for selectors
  selector1_name = eventReactive(input$run, {
    file1()$name
  })

  
  # make scatterplot with misclassification penalties
  output$plot1 = renderPrint({
    misclassificationPenalties(scenario_data(), selector1())
  })
}

# Run the app 
shinyApp(ui = ui, server = server)
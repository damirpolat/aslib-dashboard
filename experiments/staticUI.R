# compareSelectors.R
# Damir Pulatov
options(shiny.maxRequestSize = 30*1024^2)

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
           fileInput("selector1_upload", label = "Upload selector results",
                     accept = c(".RData", ".rds")),
           fileInput("selector2_upload", label = "Upload selector results",
                     accept = c(".RData", ".rds")),
           actionButton("run", "Run!")
    ), 
    column(1,
           selectInput("scenario_type", label = h5(strong("Scenario source")),
                       choices = c("ASlib", "Custom"))
    ),
    column(7, offset = 0, scatterD3Output("plot1")), 
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
    input$selector1_upload
  })
  file2 = eventReactive(input$run, {
    input$selector2_upload
  })
  
  
  # function to load ASlib scenario
  load_scenario = eventReactive(input$run, {
    read_scenario(input$scenario_type, global$datapath, input$scenario)
  })
  
  # convert data into llama format
  scenario_data = reactive(get_data(load_scenario()))
  get_ids = reactive(scenario_data()$data[unlist(scenario_data()$test), scenario_data()$ids]) 
  
  # create data for plot
  data = reactive(
    if (input$metric == "mcp") {
      build_mcp()
    } 
  )
  
  model1_mcp = reactive(mean(penalties1()))
  model2_mcp = reactive(mean(penalties2()))
  
  # compute gaps closed
  model1_gap_mcp = reactive(compute_gap(model1_mcp(), virtual_mcp(), single_mcp()))
  model2_gap_mcp = reactive(compute_gap(model2_mcp(), virtual_mcp(), single_mcp()))
  
  # might need to rewrite this
  temp_vals = reactiveValues()
  observe({
    # create or read models
    
    if(input$metric == "mcp") {
      temp_vals$summary = data.frame("x" = model1_gap_mcp(), "y" = model2_gap_mcp())
    }
    
  })
  
  # build summary for mcp
  output$summary = renderTable({
    temp_vals$summary
  }, include.rownames = FALSE)
  
  
  # make names for selectors
  selector1_name = eventReactive(input$run, {
    "file1"  
  })
  
  selector2_name = eventReactive(input$run, {
    "file2"  
  })
  
  make_par_title = reactive({
    paste("PAR10 Scores for ", selector1_name(), " vs. ", selector2_name())
  })
  
  plot.text = reactive({
    if(input$metric == "mcp") {
      paste("Misclassification Penalties for ", selector1_name(), " vs. ", selector2_name())
    } 
  })
  
  title = reactive(
    if(input$metric == "mcp") {
      paste("Misclassification Penalties")
    } 
  )
  
  # make scatterplot with misclassification penalties
  output$plot1 = renderScatterD3({
    scatterD3(data = data(), x = x, y = y,
              point_size = 100, point_opacity = 0.5,
              hover_size = 3, hover_opacity = 1,
              color = "purple",
              lines = lines(),
              transitions = TRUE)
  })
}

# Run the app 
shinyApp(ui = ui, server = server)
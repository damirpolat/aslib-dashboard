# compareSelectors.R
# Damir Pulatov
options(shiny.maxRequestSize=100*1024^2)

library(shiny)
library(mlr)
library(llama)
library(aslib)
library(purrr)
library(scatterD3)
library(shinyFiles)
source("./helpers.R")

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
  scenario_data = eventReactive(input$run, {
    if(input$scenario_type == "ASlib") {
      return(get_data("ASlib", path = NULL, scenario_name = input$scenario))
    }
    else if(input$scenario_type == "Custom") {
      return(get_data("Custom", path = global$datapath, scenario_name = NULL))
    }
  })
  
  # convert data into llama format
  #scenario_data = reactive(get_data(load_scenario()))
  get_ids = reactive(scenario_data()$data[unlist(scenario_data()$test), scenario_data()$ids]) 
  
  # compute metrics of interest
  penalties1 = reactive(misclassificationPenalties(scenario_data(), temp_vals$selector1))
  penalties2 = reactive(misclassificationPenalties(scenario_data(), temp_vals$selector2))
  par1 = reactive(parscores(scenario_data(), temp_vals$selector1))
  par2 = reactive(parscores(scenario_data(), temp_vals$selector2))
  
  build_mcp = reactive(build_data(get_ids(), penalties1(), penalties2()))
  build_par = reactive(build_data(get_ids(), par1(), par2()))
  # create data for plot
  data = reactive(
    if (input$metric == "mcp") {
      build_mcp()
    } else if (input$metric == "par10") {
      build_par()
    }
  )
  
  # compute mean mcp for each model
  single_mcp = reactive(compute_metric(scenario_data(), choice = "sbs", 
                                       method = "mcp"))
  virtual_mcp = reactive(compute_metric(scenario_data(), choice = "vbs", 
                                        method = "mcp"))
  model1_mcp = reactive(mean(penalties1()))
  model2_mcp = reactive(mean(penalties2()))
  
  # compute mean par10 for each model
  single_par = reactive(compute_metric(scenario_data(), choice = "sbs", 
                                       method = "par10"))
  virtual_par = reactive(compute_metric(scenario_data(), choice = "vbs", 
                                        method = "par10"))
  model1_par = reactive(mean(par1()))
  model2_par = reactive(mean(par2()))
  
  # compute gaps closed
  model1_gap_mcp = reactive(compute_gap(model1_mcp(), virtual_mcp(), single_mcp()))
  model2_gap_mcp = reactive(compute_gap(model2_mcp(), virtual_mcp(), single_mcp()))
  model1_gap_par = reactive(compute_gap(model1_par(), virtual_par(), single_par()))
  model2_gap_par = reactive(compute_gap(model2_par(), virtual_par(), single_par()))
  
  # might need to rewrite this
  temp_vals = reactiveValues()
  observe({
    # create or read models
    temp_vals$selector1 = create_model(file_name = file1())
    temp_vals$selector2 = create_model(file_name = file2())
    
    if(input$metric == "mcp") {
      temp_vals$summary = data.frame("x" = model1_gap_mcp(), "y" = model2_gap_mcp())
    } else if (input$metric == "par10") {
      temp_vals$summary = data.frame("x" = model1_gap_par(), "y" = model2_gap_par())
    }
    
  })
  
  # build summary for mcp
  output$summary = renderTable({
    temp_vals$summary
  }, include.rownames = FALSE)
  
  
  tooltip = reactive(paste("instance_id = ", data()$instance_id, "<br>x = ", 
                           data()$x, "<br>y = ", data()$y))
  
  # make names for selectors
  selector1_name = eventReactive(input$run, {
    file1()$name
  })
  
  selector2_name = eventReactive(input$run, {
    file2()$name
  })
  
  make_par_title = reactive({
    paste("PAR10 Scores for ", selector1_name(), " vs. ", selector2_name())
  })
  
  plot.text = reactive({
    if(input$metric == "mcp") {
      paste("Misclassification Penalties for ", selector1_name(), " vs. ", selector2_name())
    } else if (input$metric == "par10") {
      paste("PAR10 Scores for ", selector1_name(), " vs. ", selector2_name())
    }
  })
  
  title = reactive(
    if(input$metric == "mcp") {
      paste("Misclassification Penalties")
    } else if (input$metric == "par10") {
      paste("PAR10 Scores")
    }
  )
  
  # make scatterplot with misclassification penalties
  output$plot1 = renderScatterD3({
    scatterD3(data = data(), x = x, y = y, tooltip_text = tooltip(),
              tooltip_position = "top right",
              xlab = selector1_name(), ylab = selector2_name(),
              point_size = 100, point_opacity = 0.5,
              hover_size = 3, hover_opacity = 1,
              color = "purple",
              lines = lines(),
              caption = list(text = plot.text(),
                             title = title()),
              transitions = TRUE)
  })
}

# Run the app 
shinyApp(ui = ui, server = server)
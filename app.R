# compareSelectors.R
# Damir Pulatov
options(shiny.maxRequestSize=100*1024^2)

library(shiny)
library(mlr)
library(llama)
library(aslib)
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
           uiOutput("selector1_loader"),
           uiOutput("selector2_loader"),
           actionButton("run", "Run!")
    ), 
    column(1,
           selectInput("scenario_type", label = h5(strong("Scenario source")),
                       choices = c("ASlib", "Custom")),
           selectInput("selector1_type", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom")),
           selectInput("selector2_type", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom"))
    ),
    column(7, offset = 0, scatterD3Output("plot1")), 
    column(2,
           selectInput("metric", "Select metric", choices = c("mcp", "par10")),
           htmlOutput("summary")
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
  
  # dynamic UI for selecting selectors
  output$selector1_loader = renderUI({
    switch(input$selector1_type,
           "mlr/llama" = textInput("learner1", label = h4(strong("Type learner name")),
                                   placeholder = "ex. regr.featureless"),
           "Custom" =  list(
             fileInput("selector1_upload", label = "Upload selector results",
                                      accept = c(".RData", ".rds")))
    )
  })
  
  # dynamic UI for selecting selectors
  output$selector2_loader = renderUI({
    switch(input$selector2_type,
           "mlr/llama" = textInput("learner2", label = h4(strong("Type learner name")),
                                   placeholder = "ex. regr.featureless"),
           "Custom" =  list(
             fileInput("selector2_upload", label = "Upload selector results",
                                      accept = c(".RData", ".rds")))
    )
  })
  
  
  results = reactiveValues(data = NULL)
  selectors = reactiveValues(learner1 = NULL,
                             learner2 = NULL,
                             file1 = NULL,
                             file2 = NULL)
  # get names of learners
  observeEvent(input$run, {
    req(input$learner1)
    selectors$learner1 = input$learner1
  })
  observeEvent(input$run, {
    req(input$learner2)
    selectors$learner2 = input$learner2
  })
  
  observeEvent(input$run, {
    req(input$selector1_upload)
    selectors$file1 = input$selector1_upload
  })
  observeEvent(input$run, {
    req(input$selector2_upload)
    selectors$file2 = input$selector2_upload
  })
  
  
  # build selectors
  selector1 = reactive({
    if(input$selector1_type == "Custom") {
      req(selectors$file1)
      return(create_model(type = "Custom", 
                          learner_name = NULL, 
                          file_name = selectors$file1,
                          data = NULL))
    } else if(input$selector1_type == "mlr/llama") {
      req(selectors$learner1)
      return(create_model(type = "mlr/llama", 
                          learner_name = selectors$learner1, 
                          file_name = NULL,
                          data = scenario_data()))
    }
  })
  
  
  selector2 = reactive({
    if(input$selector2_type == "Custom") {
      req(selectors$file2)
      return(create_model(type = "Custom", 
                          learner_name = NULL, 
                          file_name = selectors$file2,
                          data = NULL))
    } else if(input$selector2_type == "mlr/llama") {
      req(selectors$learner2)
      return(create_model(type = "mlr/llama", 
                          learner_name = selectors$learner2, 
                          file_name = NULL,
                          data = scenario_data()))
    }
  })
  
  
  # function to load ASlib scenario
  load_scenario = eventReactive(input$run, {
    read_scenario(input$scenario_type, global$datapath, input$scenario)
  })
  
  # convert data into llama format
  scenario_data = reactive(get_data(load_scenario()))
  ids = reactive(get_ids(scenario_data())) 
  
  # compute metrics of interest
  penalties1 = reactive(misclassificationPenalties(scenario_data(), selector1()))
  penalties2 = reactive(misclassificationPenalties(scenario_data(), selector2()))
  par1 = reactive(parscores(scenario_data(), selector1()))
  par2 = reactive(parscores(scenario_data(), selector2()))
  
  build_mcp = reactive(build_data(ids(), penalties1(), penalties2()))
  build_par = reactive(build_data(ids(), par1(), par2()))
  # create data for plot
  observe({
    if (input$metric == "mcp") {
      results$data = build_mcp()
    } else if (input$metric == "par10") {
      results$data = build_par()
    }
  })
  
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
    if(input$metric == "mcp") {
      temp_vals$gap1 = model1_gap_mcp()
      temp_vals$gap2 = model2_gap_mcp()
    } else if (input$metric == "par10") {
      temp_vals$gap1 = model1_gap_par()
      temp_vals$gap2 = model2_gap_par()
    }
    temp_vals$summary = sprintf("Percentage gap closed between single best and virtual best solvers:\n
                      %s: %s\n%s: %s\n", selector1_name(), temp_vals$gap1, selector2_name(), temp_vals$gap2)
  })
  
  # build summary for mcp
  output$summary = renderUI({
    summary1 = paste("Percentage gap closed between single best and virtual best solvers:")
    summary2 = paste("<b>", selector1_name(), "</b>: ", temp_vals$gap1)
    summary3 = paste("<b>", selector2_name(), "</b>: ", temp_vals$gap2)
    HTML(paste(summary1, summary2, summary3, sep = "<br/>"))
  })
  
  
  tooltip = reactive(paste("instance_id = ", ids(), "<br>", selector1_name(), 
                           " = ", results$data$x, "<br>", selector2_name(), " = ", results$data$y))
  
  # make names for selectors
  selector1_name = eventReactive(input$run, {
    if(input$selector1_type == "mlr/llama") {
      selectors$learner1
    } else if(input$selector1_type == "Custom" && !is.null(selectors$file1)) {
      selectors$file1$name
    }
  })
  
  selector2_name = eventReactive(input$run, {
    if(input$selector2_type == "mlr/llama") {
      selectors$learner2
    } else if(input$selector2_type == "Custom" && !is.null(selectors$file2)) {
      selectors$file2$name
    }
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
    req(results$data)
    scatterD3(data = results$data, x = x, y = y, tooltip_text = tooltip(),
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

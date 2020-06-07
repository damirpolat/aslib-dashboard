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
           #selectInput("scenario_type", label = h5(strong("Scenario source")),
           #           choices = c("ASlib", "Custom")),
           selectInput("selector1_source", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom")),
           selectInput("selector2_source", label = h5(strong("Selector source")),
                       choices = c("mlr/llama", "Custom"))
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
  source = callModule(scenarioSourceServer, "source")
  callModule(scenarioServer, "scenario", source = source)
  
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
  
  # function to load ASlib scenario
  load_scenario = eventReactive(input$run, {
    read_scenario(input$scenario_type, global$datapath, input$scenario)
  })
  
  # convert data into llama format
  get_data = reactive(trainTest(convertToLlama(load_scenario())))
  get_ids = reactive(get_data()$data[get_data()$test[[1]], get_data()$ids])
  
  # compute metrics of interest
  penalties1 = reactive(misclassificationPenalties(get_data(), temp_vals$selector1))
  penalties2 = reactive(misclassificationPenalties(get_data(), temp_vals$selector2))
  par1 = reactive(parscores(get_data(), temp_vals$selector1))
  par2 = reactive(parscores(get_data(), temp_vals$selector2))
  
  build_mcp = reactive(build_data(get_ids(), penalties1(), penalties2(), par1 = NULL, par2 = NULL))
  build_par = reactive(build_data(get_ids(), penalties1 = NULL, penalties2 = NULL, par1(), par2()))
  # create data for plot
  data = reactive(
    if (input$metric == "mcp") {
      build_mcp()
    } else if (input$metric == "par10") {
      build_par()
    }
  )
  
  # compute mean mcp for each model
  single_mcp = reactive(compute_metric(load_scenario(), get_data(), choice = "sbs", 
                                       method = "mcp"))
  virtual_mcp = reactive(compute_metric(load_scenario(), get_data(), choice = "vbs", 
                                        method = "mcp"))
  model1_mcp = reactive(mean(penalties1()))
  model2_mcp = reactive(mean(penalties2()))
  
  # compute mean par10 for each model
  single_par = reactive(compute_metric(load_scenario(), get_data(), choice = "sbs", 
                                       method = "par10"))
  virtual_par = reactive(compute_metric(load_scenario(), get_data(), choice = "vbs", 
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
    temp_vals$selector1 = regression(learner1(), get_data())
    temp_vals$selector2 = regression(learner2(), get_data())
    
    if(input$metric == "mcp") {
      temp_vals$summary = data.frame("x" = model1_gap_mcp(), "y" = model2_gap_mcp())
      #row.names(temp_vals$summary) = "Percentage Gap Closed"
      #colnames(temp_vals$summary) = c("sbs", "vbs", paste(input$selector1), paste(input$selector2))
      #temp_vals$summary = temp_vals$tmp
      #temp_vals$summary[, input$selector1] = model1_mcp()
    } else if (input$metric == "par10") {
      temp_vals$summary = data.frame("x" = model1_gap_par(), "y" = model1_gap_par())
    }
    
  })
  
  # build summary for mcp
  output$summary = renderTable({
    temp_vals$summary
  }, include.rownames = FALSE)
  
  
  tooltip = reactive(paste("instance_id = ", data()$instance_id, "<br>x = ", 
                           data()$x, "<br>y = ", data()$y))
  
  make_par_title = reactive( paste("PAR10 Scores for ", input$selector1, " vs. ", input$selector2) )
  #metric = reactive({ input$metric })
  # build info text
  caption = reactiveValues()
  #caption$plot.text = reactive({
  #  if(metric() == "mcp") {
  #    paste("Misclassification Penalties for ", input$selector1, " vs. ", input$selector2)
  #  } else if (metric() == "par10") {
  #    #make_par_title()
  #    paste("PAR10 Scores for ", input$selector1, " vs. ", input$selector2)
  #  }
  #})
  
  plot.text = reactive({
    if(input$metric == "mcp") {
      paste("Misclassification Penalties for ", input$selector1, " vs. ", input$selector2)
    } else if (input$metric == "par10") {
      #make_par_title()
      paste("PAR10 Scores for ", input$selector1, " vs. ", input$selector2)
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
              xlab = input$selector1, ylab = input$selector2,
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
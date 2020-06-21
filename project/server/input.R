# input.R
# Damir Pulatov

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
     fileInput("selector1_upload", label = h4(strong("Upload selector results")),
               accept = c(".RData", ".rds")))
  )
})
  
# dynamic UI for selecting selectors
output$selector2_loader = renderUI({
  switch(input$selector2_type,
    "mlr/llama" = textInput("learner2", label = h4(strong("Type learner name")),
                           placeholder = "ex. regr.featureless"),
    "Custom" =  list(
     fileInput("selector2_upload", label = h4(strong("Upload selector results")),
               accept = c(".RData", ".rds")))
  )
})
  
# scenario summary
output$scenario_summary = renderPrint({
  req(load_scenario())
  print(load_scenario())
})
output$scenario_title = renderUI({
  req(load_scenario())
  h4(strong("Scenario summary"))
})
  
  
# selector summaries
output$selector1_summary = renderPrint({
  req(selector1())
  print(selector1())
})
output$selector1_title = renderUI({
  req(selector1())
  h4(strong(paste(" ", selector1_name(), "summary")))
})
  
# selector summaries
output$selector2_summary= renderPrint({
  req(selector2())
  print(selector2())
})
output$selector2_title = renderUI({
  req(selector2())
  h4(strong(paste(" ", selector2_name(), "summary")))
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
  
# function to load ASlib scenario
load_scenario = eventReactive(input$run, {
  read_scenario(input$scenario_type, global$datapath, input$scenario)
})
  
# convert data into llama format
scenario_data = reactive(get_data(load_scenario()))
ids = reactive(get_ids(scenario_data())) 

# input.R
# Damir Pulatov

shinyDirChoose(
  input,
  'scenario_upload',
  roots = c(home = '/home/'),
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
   home = normalizePath("/home/")
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
  
# x and y axis
x_axis = reactive(input$x_axis)
y_axis = reactive(input$y_axis)

# scenario summary
output$scenario_summary = renderPrint({
  req(load_scenario())
  print(load_scenario())
})
output$scenario_title = renderUI({
  req(load_scenario())
  h4(strong("Scenario summary"))
})
  
  
# algorithm summaries
output$algo_perf = renderDataTable({
  req(load_scenario())
  datatable(summarizeAlgoPerf(load_scenario(), load_scenario()$desc$performance_measures), 
            height = '70px', options = list(paging = TRUE, pageLength = 8,
                                            lengthMenu = c(8, 16, 24, 32, 40)))
})
output$perf_title = renderUI({
  req(load_scenario())
  h4(strong(paste("Algorithm Summary for", load_scenario()$desc$scenario_id)))
})
  

results = reactiveValues(data = NULL, errors = NULL, box_data = NULL)
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


# get single best and virtual best solvers
sbs = reactive({
  req(scenario_data())
  return(get_sbs(scenario_data()))
})

vbs = reactive({
  req(scenario_data())
  return(get_vbs(scenario_data()))
})

toListenX = reactive({
  list(input$run, x_axis())
})
toListenY = reactive({
  list(input$run, y_axis())
})

names = reactiveValues(selector1_name = NULL,
                       selector2_name = NULL)
observeEvent(toListenX(), {
  if(x_axis() == "algorithm selector") {
    if(input$selector1_type == "mlr/llama") {
      names$selector1_name = selectors$learner1
    } else if(input$selector1_type == "Custom" && !is.null(selectors$file1)) {
      names$selector1_name = selectors$file1$name
    }
  } else {
    names$selector1_name = x_axis()
  }
})

observeEvent(toListenY(), {
  if(y_axis() == "algorithm selector") {
    if(input$selector2_type == "mlr/llama") {
      names$selector2_name = selectors$learner2
    } else if(input$selector2_type == "Custom" && !is.null(selectors$file2)) {
      names$selector2_name = selectors$file2$name
    }
  } else {
    names$selector2_name = y_axis()
  }
})


# function to load ASlib scenario
load_scenario = eventReactive(input$run, {
  read_scenario(input$scenario_type, global$datapath, input$scenario)
})
  
# convert data into llama format
scenario_data = reactive(get_data(load_scenario()))
ids = reactive(get_ids(scenario_data())) 

# store metric selection
metric = reactive(input$metric)

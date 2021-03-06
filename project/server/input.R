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
         "custom" =  list(shinyDirButton("scenario_upload", label = "Upload scenario",
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
         "regression" = selectInput("learner1", label = h4(strong("Select learner by name")), 
                                    choices = regr_learners),
         "classification" = selectInput("learner1", label = h4(strong("Select learner by name")), 
                                    choices = classif_learners),
         "custom" = list(
           fileInput("selector1_upload", label = h4(strong("Upload selector results")),
                     accept = c(".RData", ".rds")))
  )
})

# dynamic UI for selecting selectors
output$selector2_loader = renderUI({
  switch(input$selector2_type,
         "regression" = selectInput("learner2", label = h4(strong("Select learner by name")), 
                                    choices = regr_learners),
         "classification" = selectInput("learner2", label = h4(strong("Select learner by name")), 
                                        choices = classif_learners),
         "custom" =  list(
           fileInput("selector2_upload", label = h4(strong("Upload selector results")),
                     accept = c(".RData", ".rds")))
  )
})

# x and y axis
x_axis = reactive(input$x_axis)
y_axis = reactive(input$y_axis)

# first and second boxplots
method_1 = reactive(input$method_1)
method_2 = reactive(input$method_2)

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
  if(input$selector1_type == "custom") {
    req(selectors$file1)
    return(read_model(file_name = selectors$file1))
  } else {
    req(selectors$learner1)
    return(create_model(type = input$selector1_type, 
                        learner_name = selectors$learner1, 
                        data = scenario_data()))
  }
})


selector2 = reactive({
  if(input$selector2_type == "custom") {
    req(selectors$file2)
    return(read_model(file_name = selectors$file2))
  } else {
    req(selectors$learner2)
    return(create_model(type = input$selector2_type, 
                        learner_name = selectors$learner2,
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

# listen to x and y axis choices
toListenX = reactive({
  list(input$run, x_axis())
})
toListenY = reactive({
  list(input$run, y_axis())
})

# listen to method choices
toListenMethod1 = reactive({
  list(input$run, method_1())
})
toListenMethod2 = reactive({
  list(input$run, method_2())
})

names = reactiveValues(selector1_name = NULL,
                       selector2_name = NULL,
                       selector1_cons = NULL,
                       selector2_cons = NULL)

observeEvent(toListenX(), {
  if(x_axis() == "algorithm selector") {
    if(input$selector1_type == "regression" || 
       input$selector1_type == "classification") {
      names$selector1_name = selectors$learner1
    } else if(input$selector1_type == "custom" && !is.null(selectors$file1)) {
      names$selector1_name = selectors$file1$name
    }
  } else {
    names$selector1_name = x_axis()
  }
})

observeEvent(toListenY(), {
  if(y_axis() == "algorithm selector") {
    if(input$selector2_type == "regression"|| 
       input$selector2_type == "classification") {
      names$selector2_name = selectors$learner2
    } else if(input$selector2_type == "custom" && !is.null(selectors$file2)) {
      names$selector2_name = selectors$file2$name
    }
  } else {
    names$selector2_name = y_axis()
  }
})

observeEvent(toListenMethod1(), {
  if(method_1() == "algorithm selector") {
    if(input$selector1_type == "regression" || 
       input$selector1_type == "classification") {
      names$selector1_cons = selectors$learner1
    } else if(input$selector1_type == "custom" && !is.null(selectors$file1)) {
      names$selector1_cons = selectors$file1$name
    }
  } else {
    names$selector1_cons = method_1()
  }
})

observeEvent(toListenMethod2(), {
  if(method_2() == "algorithm selector") {
    if(input$selector2_type == "regression" || 
       input$selector2_type == "classification") {
      names$selector2_cons = selectors$learner2
    } else if(input$selector2_type == "custom" && !is.null(selectors$file2)) {
      names$selector2_cons = selectors$file2$name
    }
  } else {
    names$selector2_cons = method_2()
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
metric_cons = reactive(input$metric_cons)

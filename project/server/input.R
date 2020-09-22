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
         "ASlib" = selectInput("scenario", label = h4(strong("Type ASlib scenario")), 
                               choices = short_sc), 
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
         "regression" = selectInput("learner1_regr", label = h4(strong("Select learner by name")), 
                                    choices = regr_learners),
         "classification" = selectInput("learner1_classif", label = h4(strong("Select learner by name")), 
                                    choices = classif_learners),
         "custom" = list(
           fileInput("selector1_upload", label = h4(strong("Upload selector results")),
                     accept = c(".RData", ".rds")))
  )
})

# dynamic UI for selecting selectors
output$selector2_loader = renderUI({
  switch(input$selector2_type,
         "regression" = selectInput("learner2_regr", label = h4(strong("Select learner by name")), 
                                    choices = regr_learners),
         "classification" = selectInput("learner2_classif", label = h4(strong("Select learner by name")), 
                                        choices = classif_learners),
         "custom" =  list(
           fileInput("selector2_upload", label = h4(strong("Upload selector results")),
                     accept = c(".RData", ".rds")))
  )
})

# scenario summary
output$scenario_summary = renderPrint({
  req(scenarios$scenario)
  print(scenarios$scenario)
})
output$scenario_title = renderUI({
  req(scenarios$scenario)
  h4(strong("Scenario summary"))
})


# algorithm summaries
output$algo_perf = renderDataTable({
  req(scenarios$scenario)
  datatable(summarizeAlgoPerf(scenarios$scenario, scenarios$scenario$desc$performance_measures), 
            height = '70px', options = list(paging = TRUE, pageLength = 8,
                                            lengthMenu = c(8, 16, 24, 32, 40)))
})
output$perf_title = renderUI({
  req(scenarios$scenario)
  h4(strong(paste("Algorithm Summary for", scenarios$scenario$desc$scenario_id)))
})


results = reactiveValues(data = NULL, errors = NULL, box_data = NULL)
selectors = reactiveValues(learner1_regr = NULL,
                           learner1_classif = NULL,
                           learner2_regr = NULL,
                           learner2_classif = NULL,
                           file1 = NULL,
                           file2 = NULL)

shinyjs::onclick("run", {
  # get names of learners
  if (input$selector1_type == "custom") {
    req(input$selector1_upload)
    selectors$file1 = input$selector1_upload
  } else if (input$selector1_type == "regression") {
    req(input$learner1_regr)
    selectors$learner1_regr = input$learner1_regr
  } else if (input$selector1_type == "classification") {
    req(input$learner1_classif)
    selectors$learner1_classif = input$learner1_classif
  }
  
  if (input$selector2_type == "custom") {
    req(input$selector2_upload)
    selectors$file2 = input$selector2_upload
  } else if (input$selector2_type == "regression") {
    req(input$learner2_regr)
    selectors$learner2_regr = input$learner2_regr
  } else if (input$selector2_type == "classification") {
    req(input$learner2_classif)
    selectors$learner2_classif = input$learner2_classif
  }

  
  # names for comparison tab
  if(input$x_axis == "algorithm selector") {
    if(input$selector1_type == "regression") {
      names$selector1_name = selectors$learner1_regr
    } else if (input$selector1_type == "classification") {
      names$selector1_name = selectors$learner1_classif
    } else if(input$selector1_type == "custom" && !is.null(selectors$file1)) {
      names$selector1_name = selectors$file1$name
    }
  } else {
    names$selector1_name = input$x_axis
  }
  
  if(input$y_axis == "algorithm selector") {
    if(input$selector2_type == "regression") {
      names$selector2_name = selectors$learner2_regr
    } else if (input$selector2_type == "classification") {
      names$selector2_name = selectors$learner2_classif
    } else if(input$selector2_type == "custom" && !is.null(selectors$file2)) {
      names$selector2_name = selectors$file2$name
    }
  } else {
    names$selector2_name = input$y_axis
  }
  
  
  # names for consistency tab
  if(input$method_1 == "algorithm selector") {
    if(input$selector1_type == "regression") {
      names$selector1_cons = selectors$learner1_regr
    } else if (input$selector1_type == "classification") {
      names$selector1_cons = selectors$learner1_classif
    } else if(input$selector1_type == "custom" && !is.null(selectors$file1)) {
      names$selector1_cons = selectors$file1$name
    }
  } else {
    names$selector1_cons = input$method_1
  }
  
  if(input$method_2 == "algorithm selector") {
    if(input$selector2_type == "regression") {
      names$selector2_cons = selectors$learner2_regr
    } else if (input$selector2_type == "classification") {
      names$selector2_cons = selectors$learner2_classif
    } else if(input$selector2_type == "custom" && !is.null(selectors$file2)) {
      names$selector2_cons = selectors$file2$name
    }
  } else {
    names$selector2_cons = input$method_2
  }

  # load ASlib scenario
  scenarios$scenario = read_scenario(input$scenario_type, global$datapath, input$scenario)
  
  # convert data into llama format
  scenarios$data = get_data(scenarios$scenario)
  scenarios$ids = get_ids(scenarios$data) 
})

# build selectors
selector1 = reactive({
  if(input$selector1_type == "custom") {
    req(selectors$file1)
    return(read_model(file_name = selectors$file1))
  } else if (input$selector1_type == "regression") {
    req(selectors$learner1_regr)
    return(create_model(type = input$selector1_type, 
                        learner_name = selectors$learner1_regr, 
                        data = scenarios$data))
  } else if (input$selector1_type == "classification") {
    req(selectors$learner1_classif)
    return(create_model(type = input$selector1_type, 
                        learner_name = selectors$learner1_classif, 
                        data = scenarios$data))
  } 
})


selector2 = reactive({
  if(input$selector2_type == "custom") {
    req(selectors$file2)
    return(read_model(file_name = selectors$file2))
  } else if (input$selector2_type == "regression") {
    req(selectors$learner2_regr)
    return(create_model(type = input$selector2_type, 
                        learner_name = selectors$learner2_regr,
                        data = scenarios$data))
  } else if (input$selector2_type == "classification") {
    req(selectors$learner2_classif)
    return(create_model(type = input$selector2_type, 
                        learner_name = selectors$learner2_classif,
                        data = scenarios$data))
  }
})


# get single best and virtual best solvers
sbs = reactive({
  req(scenarios$data)
  return(get_sbs(scenarios$data))
})

vbs = reactive({
  req(scenarios$data)
  return(get_vbs(scenarios$data))
})

names = reactiveValues(selector1_name = NULL,
                       selector2_name = NULL,
                       selector1_cons = NULL,
                       selector2_cons = NULL)


scenarios = reactiveValues(scenario = NULL, data = NULL, ids = NULL)


# store metric selection
metric = reactive(input$metric)
metric_cons = reactive(input$metric_cons)

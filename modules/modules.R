# modules.R
# Damir Pulatov

# I can put everything related to selecting and typing scenario into one module
scenarioInput = function(id) {
  ns = NS(id)
  list(uiOutput(ns("scenario_loader")))
}

scenarioServer = function(input, output, session, source) {
  shinyDirChoose(
    input,
    'scenario_upload',
    roots = c(home = '~'),
    filetypes = c('', 'txt', 'arff', 'csv')
  )
  
  # dynamic UI for selecting scenarios
  output$scenario_loader = renderUI({
    ns = session$ns
    switch(source$scenario_type(),
           "ASlib" = textInput(ns("scenario"), label = h4(strong("Type ASlib scenario")),
                               placeholder = "ex. SAT11-INDU", value = "SAT11-INDU"),
           "Custom" =  list(shinyDirButton(ns("scenario_upload"), label = "Upload scenario",
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
}

# scenario source selection UI
scenarioSourceUI = function(id) {
  ns = NS(id)
  
  list(
    selectInput(ns("scenario_type"), label = h5(strong("Scenario source")),
                choices = c("ASlib", "Custom"))
  )
}

# server for scenario source selection
scenarioSourceServer = function(input, output, session) {
  return(
    list(
      scenario_type = reactive( input$scenario_type ))
  )
}
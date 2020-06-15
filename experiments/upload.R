library(shiny)
library(shinyFiles)

ui <- fluidPage(
  shinyFilesButton("GetFile", "Choose a file" ,
                   title = "Please select a file:", multiple = FALSE,
                   buttonType = "default", class = NULL),
  
  actionButton(inputId = "reload", label = "Reload data"),
  
  tableOutput("test")     
)


server <- function(input,output,session){
  
  volumes <- getVolumes()
  
  v = reactiveValues(path = NULL)
  
  observe({
    shinyFileChoose(input, "GetFile", roots = volumes, session = session)
    
    if (!is.null(input$GetFile)) {
      file_selected <- parseFilePaths(volumes, input$GetFile)
      v$path <- as.character(file_selected$datapath)
      req(v$path)
      v$data <- read.csv(v$path)
    }
  })
  
  observeEvent(input$reload, {
    req(v$path)
    v$data <- read.csv(v$path)
    
  })
  
  output$test <- renderTable({
    print(v$path)
    if (is.null(v$data)) return()
    v$data
  })
  
}

shinyApp(ui = ui, server = server)
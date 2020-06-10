library(shiny)
ui <- shinyUI(bootstrapPage(
  actionButton("test1", "test1"),
  actionButton("test2", "test2"))
)

server <- shinyServer(function(input, output) {
  
  toListen <- reactive({
    list(input$test1,input$test2)
  })
  #observeEvent({
  #    input$test1
  #    input$test2
  #    1
  #  }, print('Hello World')
  #)
  
  
  observeEvent(toListen(), {
    val = 0
    if(input$test1 == 0 || input$test2 == 0) {
      val = val + 1
      if(input$test1 == 0 || input$test2 == 0) {
        val = val + 1
      }
      if(val == 2){
        return()
      }
    }
    val = 0
    print('Hello World')

  })
})

shinyApp(ui, server)
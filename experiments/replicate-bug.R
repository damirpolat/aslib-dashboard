library(shiny)
library(scatterD3)

ui = fluidPage(
  fluidRow(
    column(2,
           selectInput("choose", "Choose", choices = c("a", "b"))
    ), 
    column(7, offset = 0, scatterD3Output("plot"))
  )
  
)

server = function(input, output) {
  
  choosing = reactive(input$choose)
  
  plot.text = reactive({
    if(choosing() == "a") {
      paste("Title for a ")
    } else if (choosing() == "b") {
      paste("Title for b ")
    }
  })
  
  title = reactive(
    if(choosing() == "a") {
      paste("Text for ", input$choose)
    } else if (choosing() == "b") {
      paste("Text for ", input$choose)
    }
  )
 
  var = renderText(input$variable) 
  
  output$plot = renderScatterD3({
    scatterD3(data = mtcars, x = mpg, y = disp,
              point_size = 100, point_opacity = 0.5,
              hover_size = 3, hover_opacity = 1,
              color = "purple",
              caption = list(text = plot.text(),
                             title = title()),
              transitions = TRUE)
  })
  
}

shinyApp(ui = ui, server = server)
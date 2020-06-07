# exploring possible bug in scatterD3
library(scatterD3)
library(shiny)

x1 = data.frame(x = 1:5)
y1 = data.frame(y = 5:10, m = "m")
m1 = data.frame(x = 6:11)
n1 = data.frame(y = 4:9, m = "a'")

x = rbind(x1, m1)
y = rbind(y1, n1)

data = data.frame(ids = letters[1:10])
data = cbind.data.frame(data, x, y)

ui = fluidPage(
  checkboxInput("mcp", "Misclassification Penalties", value = TRUE),
  checkboxInput("par", "PAR10 Scores"),
  scatterD3Output("plot")
  
)

server = function(input, output) {

  output$plot1 = renderScatterD3({
    scatterD3(data = data(), x = x, y = y, tooltip_text = tooltip(),
      tooltip_position = "top right",
      xlab = input$selector1, ylab = input$selector2,
      point_size = 100, point_opacity = 0.5,
      hover_size = 3, hover_opacity = 1,
      lines = lines(),
      caption = list(text = paste("Misclassification Penalties for ", input$selector1, " vs. ", input$selector2),
                     title = "Misclassification Penalties"))
  })
}


shinyApp(ui = ui, server = server)
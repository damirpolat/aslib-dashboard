# error.R
# Damir Pulatov

# select ratio type
output$barplot_options = renderUI({
  req(names$selector1_name)
  req(names$selector2_name)
  
  return (radioButtons("barplot", label = h3("ratio type"), 
                       choices = list("(selector 1 / selector 2) - 1" = "ratio1",
                                      "(selector 2 / selector 1) - 1" = "ratio2"),
                       selected = "ratio1"
  ))
})

ratio_type = reactive(input$barplot)


errors1 = reactive({calculate_errors(load_scenario(), scenario_data(), selector1())})
errors2 = reactive({calculate_errors(load_scenario(), scenario_data(), selector2())})
errors = reactive({
  req(errors1())
  req(errors2())
  if(ratio_type() == "ratio1") {
    return(build_errors(errors1(), errors2()))
  } else if(ratio_type() == "ratio2") {
    return(build_errors(errors2(), errors1()))
  }
})



output$errors = renderPlotly({
  req(errors())
  # bar chart with plotly
  plot = plot_ly(data = errors(), x = ~solver, y = ~RMSE, type = "bar",
                 marker = list(color = 'rgb(158,202,225)',
                               line = list(color = 'rgb(8,48,107)',
                                           width = 1.5)),
                 hovertemplate = 'solver: %{x}<br>value: %{y:.3f}</br><extra></extra>',
                 showlegend = FALSE) %>% onRender("
  function(el, x) {
    Plotly.d3.select('.cursor-crosshair').style('cursor', 'default')
  }
  ")

  plot = plot %>% layout(title = sprintf("RMSE Ratios", names$selector1_name, names$selector2_name),
                         xaxis = list(title = '<b>Solvers<b>', tickangle = 45),
                         yaxis = list(title = '<b>Value<b>'),
                         margin = list(t = 50))
  plot = plot %>% config(mathjax = 'cdn')
  
  # remove unnecessary menu options
  plot = plot %>% config(displaylogo = FALSE,
             modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d", 
                                        "lasso2d", "select2d",
                                        "hoverClosestCartesian",
                                        "hoverCompareCartesian",
                                        "toggleSpikelines"))
})
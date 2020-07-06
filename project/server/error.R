# error.R
# Damir Pulatov

# select ratio type
ratio_type = reactive(input$barplot)

# compute error values
errors1 = reactive({calculate_errors(load_scenario(), scenario_data(), selector1())})
errors2 = reactive({calculate_errors(load_scenario(), scenario_data(), selector2())})

observe({
  req(errors1())
  req(errors2())
  if(ratio_type() == "ratio1") {
    results$errors = build_errors(errors1(), errors2())
  } else if(ratio_type() == "ratio2") {
    results$errors = build_errors(errors2(), errors1())
  }
})


output$errors = renderPlotly({
  req(results$errors)
  # bar chart with plotly
  plot = plot_ly(data = results$errors, x = ~solver, y = ~RMSE, type = "bar",
                 marker = list(color = 'rgb(158,202,225)',
                               line = list(color = 'rgb(8,48,107)',
                                           width = 1.5)),
                 hovertemplate = 'solver: %{x}<br>value: %{y:.3f}</br><extra></extra>',
                 showlegend = FALSE) %>% onRender("
function(el, x) {
  Plotly.d3.select('.cursor-crosshair').style('cursor', 'default')
}
")
  
  # add smooth transition
  plot = plot %>% animation_opts(frame = 500, transition = 500, redraw = FALSE)
  
  
  plot = plot %>% layout(title = sprintf("RMSE Ratios Subtracted by 1", names$selector1_name, names$selector2_name),
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
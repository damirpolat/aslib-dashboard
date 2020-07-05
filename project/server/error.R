# error.R
# Damir Pulatov

errors1 = reactive({calculate_errors(load_scenario(), scenario_data(), selector1())})
errors2 = reactive({calculate_errors(load_scenario(), scenario_data(), selector2())})
errors = reactive({ build_errors(errors1(), errors2()) })


output$errors = renderPlotly({
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
  plot = plot %>% layout(title = "RMSE Ratios subtracted by 1",
                         xaxis = list(title = '<b>Solvers<b>', tickangle = 45),
                         yaxis = list(title = '<b>Value<b>'),
                         margin = list(t = 50))
  
  # remove unnecessary menu options
  plot = plot %>% config(displaylogo = FALSE,
             modeBarButtonsToRemove = c("zoomIn2d", "zoomOut2d", 
                                        "lasso2d", "select2d",
                                        "hoverClosestCartesian",
                                        "hoverCompareCartesian",
                                        "toggleSpikelines"))
})
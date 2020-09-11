# compare_consistency.R
# Damir Pulatov

# compute metrics of interest
cons_metric = reactiveValues(m1 = NULL, m2 = NULL)
observe({
  # calculate metric for each selector
  if(method_1() == "algorithm selector") {
    cons_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = selector1())
  } else if(method_1() == "single best solver") {
    cons_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = sbs())
  } else if(method_1() == "virtual best solver") {
    cons_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = vbs())
  }
  
  if(method_2() == "algorithm selector") {
    cons_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = selector2())
  } else if(method_2() == "single best solver") {
    cons_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = sbs())
  } else if(method_2() == "virtual best solver") {
    cons_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric_cons(), selector = vbs())
  }
})


# create data for plot
observe({
  req(cons_metric$m1)
  req(cons_metric$m2)
  results$box_data = cons_data(ids(), cons_metric$m1, cons_metric$m2, names$selector1_cons, 
                                names$selector2_cons)
})


# compute coefficient of variation
model1_cv = reactive(compute_cv(results$box_data, names$selector1_cons, names$selector2_cons))
model2_cv = reactive(compute_cv(results$box_data, names$selector2_cons, names$selector1_cons))

# build summary for variation
output$summary_var = renderUI({
  req(results$box_data)
  summary1 = paste("Coefficient of variation:")
  summary2 = paste("<b>", names$selector1_cons, "</b>: ", model1_cv(), "%", sep = "")
  summary3 = paste("<b>", names$selector2_cons, "</b>: ", model2_cv(), "%", sep = "")
  HTML(paste(summary1, summary2, summary3, sep = "<br/>"))
})

output$plot2 = renderPlotly({
  req(results$box_data)
  plot = plot_ly(data = results$box_data, x = ~method, y = ~value, type = "box",
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
  
  
  plot = plot %>% layout(title = sprintf("Consistency Between %s and %s", names$selector1_cons, names$selector2_cons),
                         xaxis = list(title = '<b>Method<b>', tickangle = 45),
                         yaxis = list(title = '<b>Scores<b>'),
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
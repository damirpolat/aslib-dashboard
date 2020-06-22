# compare.R
# Damir Pulatov

# reference lines for scatter plot
default_lines = data.frame(slope = c(0, Inf, 1), intercept = c(0, 0, 0), 
                           stroke_width = 1, stroke_dasharray = 5)
lines = reactive({ default_lines })

# compute metrics of interest
selector_metric = reactiveValues(m1 = NULL, m2 = NULL)
observe({
  # calculate metric for each selector
  if(x_axis() == "algorithm selector") {
    selector_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = selector1())
  } else if(x_axis() == "single best solver") {
    selector_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = sbs())
  } else if(x_axis() == "virtual best solver") {
    selector_metric$m1 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = vbs())
  }
  
  if(y_axis() == "algorithm selector") {
    selector_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = selector2())
  } else if(y_axis() == "single best solver") {
    selector_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = sbs())
  } else if(y_axis() == "virtual best solver") {
    selector_metric$m2 = compute_metric(data = scenario_data(), 
                                        method = metric(), selector = vbs())
  }
})

# create data for plot
observe({
  req(selector_metric$m1)
  req(selector_metric$m2)
  results$data = build_data(ids(), selector_metric$m1, selector_metric$m2)
})

# compute mean metric for each model
single_mean = reactive(mean(compute_metric(data = scenario_data(), 
                      method = metric(), selector = sbs())))
virtual_mean = reactive(mean(compute_metric(data = scenario_data(), 
                      method = metric(), selector = vbs())))
model1_mean = reactive({
  req(selector_metric$m1)
  mean(selector_metric$m1)
})
model2_mean = reactive({
  req(selector_metric$m2)
  mean(selector_metric$m2)
})


# compute gaps closed
model1_gap = reactive(compute_gap(model1_mean(), virtual_mean(), single_mean()))
model2_gap = reactive(compute_gap(model2_mean(), virtual_mean(), single_mean()))


# might need to rewrite this
temp_vals = reactiveValues()
observe({
  temp_vals$gap1 = model1_gap()
  temp_vals$gap2 = model2_gap()
})

# build summary for mcp
output$summary = renderUI({
  summary1 = paste("Percentage gap closed between single best and virtual best solvers:")
  summary2 = paste("<b>", names$selector1_name, "</b>: ", temp_vals$gap1, "%", sep = "")
  summary3 = paste("<b>", names$selector2_name, "</b>: ", temp_vals$gap2, "%", sep = "")
  HTML(paste(summary1, summary2, summary3, sep = "<br/>"))
})


tooltip = reactive(paste("instance_id = ", ids(), "<br>", names$selector1_name, 
                         " = ", results$data$x, "<br>", names$selector2_name, " = ", results$data$y))



make_par_title = reactive({
  paste("PAR10 Scores for ", names$selector1_name, " vs. ", names$selector2_name)
})

plot.text = reactive({
  if(metric() == "mcp") {
    paste("Misclassification Penalties for ", names$selector1_name, " vs. ", names$selector2_name)
  } else if (metric() == "par10") {
    paste("PAR10 Scores for ", names$selector1_name, " vs. ", names$selector2_name)
  }
})

title = reactive(
  if(input$metric == "mcp") {
    paste("Misclassification Penalties")
  } else if (input$metric == "par10") {
    paste("PAR10 Scores")
  }
)

# make scatterplot with misclassification penalties
output$plot1 = renderScatterD3({
  req(results$data)
  scatterD3(data = results$data, x = x, y = y, tooltip_text = tooltip(),
            tooltip_position = "top right",
            xlab = names$selector1_name, ylab = names$selector2_name,
            point_size = 100, point_opacity = 0.5,
            hover_size = 3, hover_opacity = 1,
            color = "purple",
            lines = lines(),
            caption = list(text = plot.text(),
                           title = title()),
            transitions = TRUE)
})
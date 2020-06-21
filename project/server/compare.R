# compare.R
# Damir Pulatov

# reference lines for scatter plot
default_lines = data.frame(slope = c(0, Inf, 1), intercept = c(0, 0, 0), 
                           stroke_width = 1, stroke_dasharray = 5)
lines = reactive({ default_lines })

# compute metrics of interest
penalties1 = reactive(misclassificationPenalties(scenario_data(), selector1()))
penalties2 = reactive(misclassificationPenalties(scenario_data(), selector2()))
par1 = reactive(parscores(scenario_data(), selector1()))
par2 = reactive(parscores(scenario_data(), selector2()))

build_mcp = reactive(build_data(ids(), penalties1(), penalties2()))
build_par = reactive(build_data(ids(), par1(), par2()))
# create data for plot
observe({
  if (input$metric == "mcp") {
    results$data = build_mcp()
  } else if (input$metric == "par10") {
    results$data = build_par()
  }
})

# compute mean mcp for each model
single_mcp = reactive(compute_metric(scenario_data(), choice = "sbs", 
                                     method = "mcp"))
virtual_mcp = reactive(compute_metric(scenario_data(), choice = "vbs", 
                                      method = "mcp"))
model1_mcp = reactive(mean(penalties1()))
model2_mcp = reactive(mean(penalties2()))

# compute mean par10 for each model
single_par = reactive(compute_metric(scenario_data(), choice = "sbs", 
                                     method = "par10"))
virtual_par = reactive(compute_metric(scenario_data(), choice = "vbs", 
                                      method = "par10"))
model1_par = reactive(mean(par1()))
model2_par = reactive(mean(par2()))

# compute gaps closed
model1_gap_mcp = reactive(compute_gap(model1_mcp(), virtual_mcp(), single_mcp()))
model2_gap_mcp = reactive(compute_gap(model2_mcp(), virtual_mcp(), single_mcp()))
model1_gap_par = reactive(compute_gap(model1_par(), virtual_par(), single_par()))
model2_gap_par = reactive(compute_gap(model2_par(), virtual_par(), single_par()))


# might need to rewrite this
temp_vals = reactiveValues()
observe({
  if(input$metric == "mcp") {
    temp_vals$gap1 = model1_gap_mcp()
    temp_vals$gap2 = model2_gap_mcp()
  } else if (input$metric == "par10") {
    temp_vals$gap1 = model1_gap_par()
    temp_vals$gap2 = model2_gap_par()
  }
})

# build summary for mcp
output$summary = renderUI({
  summary1 = paste("Percentage gap closed between single best and virtual best solvers:")
  summary2 = paste("<b>", selector1_name(), "</b>: ", temp_vals$gap1, "%", sep = "")
  summary3 = paste("<b>", selector2_name(), "</b>: ", temp_vals$gap2, "%", sep = "")
  HTML(paste(summary1, summary2, summary3, sep = "<br/>"))
})


tooltip = reactive(paste("instance_id = ", ids(), "<br>", selector1_name(), 
                         " = ", results$data$x, "<br>", selector2_name(), " = ", results$data$y))



make_par_title = reactive({
  paste("PAR10 Scores for ", selector1_name(), " vs. ", selector2_name())
})

plot.text = reactive({
  if(input$metric == "mcp") {
    paste("Misclassification Penalties for ", selector1_name(), " vs. ", selector2_name())
  } else if (input$metric == "par10") {
    paste("PAR10 Scores for ", selector1_name(), " vs. ", selector2_name())
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
            xlab = selector1_name(), ylab = selector2_name(),
            point_size = 100, point_opacity = 0.5,
            hover_size = 3, hover_opacity = 1,
            color = "purple",
            lines = lines(),
            caption = list(text = plot.text(),
                           title = title()),
            transitions = TRUE)
})
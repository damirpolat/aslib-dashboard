# compareSelectors.R
# Damir Pulatov
library(llama)
library(aslib)
library(scatterD3)
source("./helpers.R")

default_lines = data.frame(slope = c(0, Inf, 1), intercept = c(0, 0, 0), 
                           stroke_width = 1, stroke_dasharray = 5)

# set up default directory for printing
path = "../example-inputs/SAT11-INDU/"
file1 = "../example-inputs/id.RData"
file2 = "../example-inputs/metrics.RData"

selector1 = create_model1(file_name = file1)
selector2 = create_model1(file_name = file2)

# function to load ASlib scenario
scenario_data = get_data("Custom", path = path, scenario_name = NULL)

# convert data into llama format
#scenario_data = reactive(get_data(load_scenario()))
get_ids = scenario_data$data[unlist(scenario_data$test), scenario_data$ids]

# compute metrics of interest
penalties1 = misclassificationPenalties(scenario_data, selector1)
penalties2 = misclassificationPenalties(scenario_data, selector2)
#par1 = reactive(parscores(scenario_data(), temp_vals$selector1))
#par2 = reactive(parscores(scenario_data(), temp_vals$selector2))

build_mcp = build_data(get_ids, penalties1, penalties2)
data = build_mcp
#build_par = reactive(build_data(get_ids(), par1(), par2()))
# create data for plot

# compute mean mcp for each model
single_mcp = compute_metric(scenario_data, choice = "sbs", 
                                     method = "mcp")
virtual_mcp = compute_metric(scenario_data, choice = "vbs", 
                                      method = "mcp")
model1_mcp = mean(penalties1)
model2_mcp = mean(penalties2)

# compute gaps closed
model1_gap_mcp = compute_gap(model1_mcp, virtual_mcp, single_mcp)
model2_gap_mcp = compute_gap(model2_mcp, virtual_mcp, single_mcp)

tooltip = paste("instance_id = ", get_ids, "<br>x = ", 
                         data$x, "<br>y = ", data$y)

# make names for selectors
selector1_name = file1
selector2_name = file2

make_par_title = paste("PAR10 Scores for ", selector1_name, " vs. ", selector2_name)


plot.text = paste("Misclassification Penalties for ", selector1_name, " vs. ", selector2_name)
title = paste("Misclassification Penalties")

# make scatterplot with misclassification penalties
plot1 = scatterD3(data = data, x = x, y = y, tooltip_text = tooltip,
            tooltip_position = "top right",
            xlab = selector1_name, ylab = selector2_name,
            point_size = 100, point_opacity = 0.5,
            hover_size = 3, hover_opacity = 1,
            color = "purple",
            lines = default_lines,
            caption = list(text = plot.text,
                           title = title),
            transitions = TRUE)

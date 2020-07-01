# testing r2d3
library(aslib)
library(r2d3)

load("../data/id.RData")
model1 = combined_model
load("../data/metrics.RData")
model2 = combined_model

sc = parseASScenario("../data/aslib_scenarios/SAT11-INDU/")
data = convertToLlamaCVFolds(sc)
data = fixFeckingPresolve(sc, data)

error1 = calculate_errors(sc, data, model1)
error2 = calculate_errors(sc, data, model2)
errors = data.frame(matrix(ncol = 2, nrow = length(error1[, 1])))
colnames(errors) = c("RMSE", "solver")
errors$RMSE = error1$RMSE - error2$RMSE
errors$solver = error1$solver

r2d3(data = errors, script = "./barplot.js")

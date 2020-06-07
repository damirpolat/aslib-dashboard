# getting started with scatterd3
library(scatterD3)
library(llama)
library(aslib)
library(mlr)

learner1 = makeImputeWrapper(learner = setHyperPars(makeLearner("regr.featureless")),
                    classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                    factor = imputeConstant("NA"), character = imputeConstant("NA")))

learner2 = makeImputeWrapper(learner = setHyperPars(makeLearner("regr.randomForest")),
                             classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                             factor = imputeConstant("NA"), character = imputeConstant("NA")))

sc = getCosealASScenario("SAT11-INDU")
llama.cv = convertToLlama(sc)
llama.cv = trainTest(llama.cv)

selector1 = regression(learner1, llama.cv)
selector2 = regression(learner2, llama.cv)

penalties1 = misclassificationPenalties(llama.cv, selector1)
penalties2 = misclassificationPenalties(llama.cv, selector2)

par1 = parscores(llama.cv, selector1)
par2 = parscores(llama.cv, selector2)

x_mcp = cbind.data.frame(x = penalties1)
y_mcp = cbind.data.frame(y = penalties2, method = "mcp")

x_par = cbind.data.frame(x = par1)
y_par = cbind.data.frame(y = par2, method = "par10")

x = rbind(x_mcp, x_par)
y = rbind(y_mcp, y_par)

data = data.frame(instance_id = llama.cv$data[llama.cv$test[[1]], llama.cv$ids])

data = cbind.data.frame(data, x, y)

tooltip = paste("instance_id = ", data$instance_id, "<br>x = ", data$x, "<br>y = ", data$y)
scatterD3(data = data, x = x, y = y, col_var = method, tooltip_text = tooltip,
          tooltip_position = "top right",
          xlab = "regr.featureless", ylab = "regr.featureless",
          point_size = 100, point_opacity = 0.5,
          hover_size = 3, hover_opacity = 1,
          lines = data.frame(slope = c(0, Inf, 1), intercept = c(0, 0, 0), stroke_width = 1, 
                             stroke_dasharray = 5),
          caption = list(text = paste("Misclassification Penalties for ", learner1$id, " vs. ", learner1$id),
                    title = "Misclassification Penalties"))


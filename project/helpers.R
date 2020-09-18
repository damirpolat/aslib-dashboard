# helpers.R
# Damir Pulatov

library(llama)
library(tidyr)

# list of integrated learners and their mlr names
regr_learners = c("featureless", "random forest")
regr_mlr = c("regr.featureless", "regr.randomForest")

classif_learners = c("featureless", "random forest")
classif_mlr = c("classif.featureless", "classif.randomForest")

# build data for scatter plot
build_data = function(ids, m1, m2) {
  data = data.frame(instance_id = ids, x = m1, y = m2)
  return(data)
}

# build data for box plot
cons_data = function(ids, m1, m2, name1, name2) {
  if (name1 == name2) {
    name1 = sprintf("%s_1", name1)
    name2 = sprintf("%s_2", name2)
  }
  data = data.frame(instance_id = ids, x = m1, y = m2)
  colnames(data) = c("instance_id", name1, name2)
  data = gather(data, "method", "value", c(name1, name2))
  return(data)
}


# get single best solver 
get_sbs = function(data) {
  sbs = llama:::singleBest(data)
  sbs = list(predictions = sbs)
  attr(sbs, "hasPredictions") = TRUE
  return(sbs)
}


# get virtual best solver
get_vbs = function(data) {
  vbs = llama:::vbs(data)
  vbs = list(predictions = vbs)
  attr(vbs, "hasPredictions") = TRUE
  return(vbs)
}


# compute mean mcp or gap closed
compute_metric = function(data, method, selector) {
  if(method == "mcp") {
    val = misclassificationPenalties(data, selector)
  } else if(method == "par10") {
    val = parscores(data, selector)
  }
  return(val)
}

# compute percentage of closed gap
compute_gap = function(model_val, vbs_val, sbs_val) {
  return(round(1 - (model_val - vbs_val) / (sbs_val - vbs_val), 2) * 100)
}

# compute coefficient of variation
compute_cv = function(data, name1, name2) {
  if (name1 == name2) {
    name1 = sprintf("%s_1", name1)
    name2 = sprintf("%s_2", name2)
  }
  vals = data[data$method == name1, ]$value
  return(round((sd(vals) / mean(vals)) * 100, 2))
}


# wrapper for loading scenario
read_scenario = function(switch, path = NULL, scenario_name = NULL) {
  if(switch == "ASlib") {
    scenario = getCosealASScenario(scenario_name)
    return(scenario)
  } else if (switch == "Custom") {
    scenario = parseASScenario(path)
    return(scenario)
  }
}


# make plot text
make_text = function(metric, selector1, selector2) {
  if(metric == "mcp") {
    return(paste("Misclassification Penalties for ", selector1, " vs. ", selector2))
  } else if (metric == "par10") {
    return(paste("PAR10 Scores for ", selector1, " vs. ", selector2))
  }
}


# build data from scenario
get_data = function(scenario) {
  llama.cv = convertToLlamaCVFolds(scenario)
  data = fixFeckingPresolve(scenario, llama.cv)
  return(data)
}


# read model from file
read_model = function(file_name) {
  var_name = load(file_name$datapath) 
  model = get(var_name)
  return(model)
}

# build model from scratch
create_model = function(type, learner_name, data) {
  if (type == "regression") {
    ind = match(learner_name, regr_learners)
    learner_mlr = regr_mlr[ind]
  } else if (type == "classification") {
    ind = match(learner_name, classif_learners)
    learner_mlr = classif_mlr[ind]
  }
  learner = makeImputeWrapper(learner = setHyperPars(makeLearner(learner_mlr)),
                              classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                                             factor = imputeConstant("NA"), character = imputeConstant("NA")))
  
  if (type == "regression") {
    model = regression(learner, data)
  } else if (type == "classification") {
    model = classify(learner, data)
  }

  return(model)
}


summarize = function(type, mcp1, mcp2, par1, par2) {
  if(type == "mcp") {
    data = data.frame("x" = mcp1, "y" = mcp2)
  } else if(type == "par10") {
    data = data.frame("x" = par1, "y" = par2)
  }
  return(data)
}


get_ids = function(data) {
  ids = data$data[unlist(data$test), data$ids]
  return(ids)
}


# compute MSE ratios for each solver
calculate_errors = function(scenario, data, model) {
  errors = rbind.fill(lapply(seq_along(1:length(names(scenario$desc$metainfo_algorithms))), function(solver.id) {
    truth = select(data$data, c("instance_id", names(scenario$desc$metainfo_algorithms)[solver.id]))
    colnames(truth) = c("instance_id", "score")
    truth = truth[order(truth$instance_id), ]
    truth = truth[[2]]
    
    preds = subset(model$predictions, model$predictions$algorithm == names(scenario$desc$metainfo_algorithms)[solver.id])
    preds = select(preds, c("instance_id", "score"))
    preds = preds[order(preds$instance_id), ]
    preds = preds[[2]]
    error = measureRMSE(truth, preds)
    
    val = list(RMSE = error, solver = names(scenario$desc$metainfo_algorithms)[solver.id])
    val = as.data.frame(val)
    return(val)  
  }))
}

# create data for error barplot
build_errors = function(e1, e2) {
  data = data.frame(matrix(ncol = 2, nrow = length(e1[, 1])))
  colnames(data) = c("RMSE", "solver")
  data$RMSE = (e1$RMSE / e2$RMSE) - 1
  data$solver = e1$solver
  return(data)
}
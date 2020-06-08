# helpers.R
# Damir Pulatov

library(llama)

# build data for scatter plot
build_data = function(ids, penalties1 = NULL, penalties2 = NULL, par1 = NULL, par2 = NULL) {
  # data for mcp 
  if(!is.null(penalties1) && !is.null(penalties2)) {
    x_mcp = cbind.data.frame(x = penalties1)
    y_mcp = cbind.data.frame(y = penalties2, method = "mcp")
    
    data = data.frame(instance_id = ids, x = penalties1, y = penalties2, method = "mcp")
  } 
  
  # data for par10
  if (!is.null(par1) && !is.null(par2)) {
    x_par = cbind.data.frame(x = par1)
    y_par = cbind.data.frame(y = par2, method = "par10")
    
    data = data.frame(instance_id = ids, x = par1, y = par2, method = "par10")
  }
  
  # data when both mcp and par10 are selected
  if(!is.null(penalties1) && !is.null(penalties2) 
     && !is.null(par1) && !is.null(par2)) {
    
    x = rbind(x_mcp, x_par)
    y = rbind(y_mcp, y_par)
    
    data = data.frame(instance_id = rep(ids, 2))
    data = cbind.data.frame(data, x, y)
  }
  
  return(data)
}

# compute mean mcp or gap closed
compute_metric = function(scenario, llama.cv, choice, method) {
  data = fixFeckingPresolve(scenario, llama.cv)
  
  if(method == "mcp") {
    if(choice == "sbs") {
      single = llama:::singleBest(llama.cv)
      single = list(predictions = single)
      attr(single, "hasPredictions") = TRUE
      
      val = mean(misclassificationPenalties(data, single))
    } else if(choice == "vbs") {
      vbs = llama:::vbs(llama.cv)
      vbs = list(predictions = vbs)
      attr(vbs, "hasPredictions") = TRUE
      
      val = mean(misclassificationPenalties(data, vbs))
    } 
  } else if(method == "par10") {
    if(choice == "sbs") {
      single = llama:::singleBest(llama.cv)
      single = list(predictions = single)
      attr(single, "hasPredictions") = TRUE
      
      val = mean(parscores(data, single))
    } else if(choice == "vbs") {
      vbs = llama:::vbs(llama.cv)
      vbs = list(predictions = vbs)
      attr(vbs, "hasPredictions") = TRUE
      
      val = mean(parscores(data, vbs))
    } 
  }
  
  return(val)
}

# compute percentage of closed gap
compute_gap =  function(model_val, vbs_val, sbs_val) {
  return(round(1 - (model_val - vbs_val) / (sbs_val - vbs_val), 2))
}

# wrapper for loading scenario
read_scenario = function(switch, path = NULL, scenario_name = NULL) {
  if(switch == "ASlib") {
    return(getCosealASScenario(scenario_name))
  } else if (switch == "Custom") {
    return(parseASScenario(path))
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


# build model with llama with scenario split into train/test
build_model = function(learner_name, data) {
  learner = makeImputeWrapper(learner = setHyperPars(makeLearner(learner_name)),
                classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                factor = imputeConstant("NA"), character = imputeConstant("NA")))
  model = regression(learner, data)
  return(model)
}


# wrapper for building/uploading model
# need assert that loaded model has predictions
create_model = function(type, learner_name, file_name, data) {
  if(type == "mlr/aslib") {
    model = build_model(type, learner_name, data)
  } else if(type == "Custom") {
    var_name = load(file_name) 
    model = get(var_name)
  }
  return(model)
}


# get model name
get_selector_name = function(type, learner_name, file_name) {
  return("name")
}
# helpers.R
# Damir Pulatov

library(llama)

# build data for scatter plot
build_data = function(ids, m1, m2) {
  data = data.frame(instance_id = ids, x = m1, y = m2)
  return(data)
}

# compute mean mcp or gap closed
compute_metric = function(data, choice, method) {
  if(method == "mcp") {
    if(choice == "sbs") {
      single = llama:::singleBest(data)
      single = list(predictions = single)
      attr(single, "hasPredictions") = TRUE
      
      val = mean(misclassificationPenalties(data, single))
    } else if(choice == "vbs") {
      vbs = llama:::vbs(data)
      vbs = list(predictions = vbs)
      attr(vbs, "hasPredictions") = TRUE
      
      val = mean(misclassificationPenalties(data, vbs))
    } 
  } else if(method == "par10") {
    if(choice == "sbs") {
      single = llama:::singleBest(data)
      single = list(predictions = single)
      attr(single, "hasPredictions") = TRUE
      
      val = mean(parscores(data, single))
    } else if(choice == "vbs") {
      vbs = llama:::vbs(data)
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
    scenario = getCosealASScenario(scenario_name)
    cat(scenario_name)
    return(scenario)
  } else if (switch == "Custom") {
    scenario = parseASScenario(path)
    return(scenario)
  }
  #return(scenario)
}


# wrapper for loading scenario
read_scenario1 = function(scenario_name) {
  scenario = getCosealASScenario(scenario_name)
  #cat(scenario_name)
  return(scenario)
}

read_data = function(scenario_name) {
  scenario = getCosealASScenario(scenario_name)
  llama.cv = convertToLlamaCVFolds(scenario)
  data = fixFeckingPresolve(scenario, llama.cv)
  cat("reading")
  return(data)
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
get_data = function(switch, path = NULL, scenario_name = NULL) {
  if(switch == "ASlib") {
    cat(scenario_name)
    scenario = getCosealASScenario(scenario_name)
    cat(scenario_name)
  } else if (switch == "Custom") {
    cat(path)
    scenario = parseASScenario(path)
    cat(path)
  }
  
  llama.cv = convertToLlamaCVFolds(scenario)
  data = fixFeckingPresolve(scenario, llama.cv)
  return(data)
}


# wrapper for building/uploading model
# need assert that loaded model has predictions
create_model = function(file_name) {
  var_name = load(file_name$datapath) 
  model = get(var_name)
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
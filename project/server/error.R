# error.R
# Damir Pulatov

errors1 = reactive({calculate_errors(load_scenario(), scenario_data(), selector1())})
errors2 = reactive({calculate_errors(load_scenario(), scenario_data(), selector2())})


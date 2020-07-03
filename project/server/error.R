# error.R
# Damir Pulatov

errors1 = reactive({calculate_errors(load_scenario(), scenario_data(), selector1())})
errors2 = reactive({calculate_errors(load_scenario(), scenario_data(), selector2())})
errors = reactive({ build_errors(errors1(), errors2()) })

output$errors = renderD3({
  r2d3(
    data = errors(),
    script = normalizePath("./server/barplot.js"),
    width = 500,
    height = 600
  )
})
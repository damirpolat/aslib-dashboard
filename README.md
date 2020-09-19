# ASlib Dashboard
Interactive web dashboard to help visualize the results of algorithm selection experiments.

Run app.R or build a Docker container.

# How to use
In __Input__ tab type ASlib scenario as it appears in [aslib_data](https://github.com/coseal/aslib_data) repository or 
select your own scenario. To upload a custom scenario, select _Custom_ from __Scenario source__. For the custom 
scenario, you need to specify a directory with all the files. 

For algorithm selectors, you can choose a learner from a list of installed [mlr](https://mlr.mlr-org.com/) learners or 
upload your own algorithm selection results. If you type an mlr learner, dashboard will build an algorithm selector behind the scenes with 10 fold cv, so it will take some time.
For custom selection results, select _Custom_ from __Selector source__ and 
upload .RData file with experimental results. 

Hit _Run!_ to start visualizing. 

The __Input__ tab will show scenario and algorithm summaries.

__Comparison__ tab shows an interactive scatter plot that compares the performances of two algorithm selectors.
You can also compare the performance of a selector to single best and virtual best solvers with the help of  
__x-axis__ and __y-axis__ radio buttons. 
__Select metric__ lets you specify a metric to compare selectors with (mcp or par10). 

__Consistency__ tab shows boxplots of scores for different algorithm selectors. 
The idea is to compare the spread of scores between two selectors. 
You can choose selectors as well as the score metrics in the same was as in __Comparison__ tab. 

__Errors__ tab shows RMSE ratios of two selectors subtracted by one. 
RMSE errors are computed with respect to true algorithm performance. 
__Ratio Type__ radio buttons let you select ratio type.

All plots are interactive, so feel free to touch, hover over points, zoom in/out and explore. 

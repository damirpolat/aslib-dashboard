// !preview r2d3 data=read.csv("data.csv") 
//
// r2d3: https://rstudio.github.io/r2d3
//
var axisLine = height / 2;

// create x scale
var xScale = d3.scaleBand()
        .domain(d3.range(data.length))
        .rangeRound([0, width])
        .paddingInner(0.05);

// create y scale
var yScale = d3.scaleLinear()
        .domain([d3.min(data, function(d) { return d.RMSE; }), 
                  d3.max(data, function(d) { return d.RMSE; })])
        .range([height, 0]);

// adding bars
svg.selectAll('rect')
  .data(data)
  .enter().append('rect') 
    .attr('width', xScale.bandwidth())
    .attr('height', function(d) {
      return Math.abs(yScale(d.RMSE) - yScale(0));
    })
    .attr('y', function(d) { 
      if(d.RMSE > 0) {
        return yScale(d.RMSE);
      } else {
        return yScale(0);
      }      
    })
    .attr('x', function(d, i) {
      return xScale(i);
    })
    .attr('fill', 'steelblue')
    .attr('opacity', 0.8);

// add axis
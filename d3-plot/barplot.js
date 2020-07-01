// !preview r2d3 data=c(0.3, 0.6, 0.8, 0.95, 0.40, 0.20)
//
// r2d3: https://rstudio.github.io/r2d3
//

var w = 600;
var h = 250;

var xScale = d3.scaleBand()
        .domain(d3.range(data.length))
        .rangeRound([0, w])
        .paddingInner(0.05);

var yScale = d3.scaleLinear()
        .domain([0, d3.max(data)])
        .range([0, h]);


svg.selectAll('rect')
  .data(data)
  .enter().append('rect') 
    .attr('width', xScale.bandwidth())
    .attr('height', function(d) {
      return yScale(d);
    })
    .attr('y', function(d) { 
      return h - yScale(d); 
    })
    .attr('x', function(d, i) {
      return xScale(i);
    })
    .attr('fill', 'steelblue');

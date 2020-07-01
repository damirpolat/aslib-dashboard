// !preview r2d3 data=read.csv("data.csv") 
//
// r2d3: https://rstudio.github.io/r2d3
//
var axisLine = height / 2;
var yPadding = 50;
var xPadding = 30;

// create x scale
var xScale = d3.scaleBand()
        .domain(d3.range(data.length))
        .rangeRound([xPadding, width - xPadding - 10])
        .paddingInner(0.05);

// create y scale
var yScale = d3.scaleLinear()
        .domain([d3.min(data, function(d) { return d.RMSE; }), 
                  d3.max(data, function(d) { return d.RMSE; })])
        .range([height - yPadding - 10, yPadding]);

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

// create axis
var xAxis = d3.axisBottom()
              .scale(xScale);
var yAxis = d3.axisLeft()
              .scale(yScale);
              
// draw axis
svg.append("g")
   .attr("class", "axis")
   .attr("transform", "translate(0," + (height - yPadding) + ")")
   .call(xAxis);
   
svg.append("g")
   .attr("class", "axis")
   .attr("transform", "translate(" + xPadding + ",0)")
   .call(yAxis);

// add a reference line
// fix line 
svg.append("g")
    .attr("class", "ref line")
    .append("line")
    .attr("y1", yScale(0))
    .attr("y2", yScale(0))
    .attr("x1", xScale(0))
    .attr("x2", width - yPadding + 5)
    .attr("stroke", "black");
// !preview r2d3 data=read.csv("data.csv") 
//
// r2d3: https://rstudio.github.io/r2d3
//
var axisLine = height / 2;
var yPadding = 100;
var xPadding = 30;
var opacity = 0.4;

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

// create div for tooltip
var body = d3.select('body')
	.selectAll('div')
	.enter()
	.append('div')
	.selectAll('p')
	.enter()
	.append('p')
	.text(function(d) {
	  return "solver: " + d.solver; 
	 })
	.attr('class', 'hidden')
	.style('position','absolute')
	.style('top', function (d) { return d.top; })
	.style('left', function (d) { return d.left; })
	.style('width', width + "px")
	.style('height', height + "px")
	.style('background-color', function (d) { return d.backgroundColor; });

		
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
    .attr('opacity', opacity)
    .on("mouseover", function(d) { // change opacity on hovering
      d3.select(this)
        .attr("opacity", 1);
      
      // create tooltip
      var xPosition = parseFloat(d3.select(this).attr("x")) + xScale.bandwidth() / 2;
      var yPosition = parseFloat(d3.select(this).attr("y")) + 14;
      
      svg.append("text")
         .attr("id", "tooltip")
         .attr("x", xPosition)
         .attr("y", yPosition)
         .attr("text-anchor", "middle")
         .attr("font-family", "sans-serif")
         .attr("font-size", "11px")
         .attr("fill", "black")
         .text(d.RMSE.toFixed(2));
    })
    .on("mouseout", function(d) {
      d3.select(this)
        .transition()
        .duration(250)
        .attr("opacity", opacity);
        
      svg.select("#tooltip")
        .remove();
    });

// create axis
var tickLabels = [];
for(var i = 0; i < data.length; i++) {
  tickLabels.push(data[i].solver);
}
  
var xAxis = d3.axisBottom()
              .scale(xScale)
              .tickFormat(function(d, i) {
                return tickLabels[i];
              });
var yAxis = d3.axisLeft()
              .scale(yScale);
              

// draw axis
svg.append("g")
   .attr("class", "x axis")
   .attr("transform", "translate(0," + (height - yPadding) + ")")
   .call(xAxis)
   .selectAll("text")
   .attr("transform", "rotate(45)")
   .style("text-anchor", "start")
   .attr("font-size", 6);
   
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
    .attr("x2", width - xPadding)
    .attr("stroke", "black");
    


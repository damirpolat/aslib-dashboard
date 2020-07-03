// !preview r2d3 data=read.csv("./data.csv")
//
// r2d3: https://rstudio.github.io/r2d3
//
var yPadding = 100;
var xPadding = 30;
var opacity = 0.5;

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

// create tooltip
d3.select("body")
      .append("div")
      .attr("id", "tooltip");

// create solver placeholder
d3.select("#tooltip")
      .append("p")
      .attr("id", "header");
      
// create value placeholder
d3.select("#tooltip")
      .append("p")
      .attr("id", "value");

// setup style for tooltip
d3.select("#tooltip")
  .style("position", "absolute")
  .style("line-height", "0.5em")
  .style("background-color", "white")
  .style("opacity", 0)
  .style("border", "solid")
  .style("border-width", "1px")
  .style("border-radius", "5px")
  .style("pointer-events", "none")
  .style("-webkit-box-shadow", "4px 4px 10px rgba(0, 0, 0, 0.4)")
  .style("-moz-box-shadow", "4px 4px 10px rgba(0, 0, 0, 0.4")
  .style("box-shadow", "4px 4px 10px rgba(0, 0, 0, 0.4)");


// style for errors
d3.select("#tooltip")
  .style("padding", "0.6em")
  .style("font-family", "sans-serif")
  .style("font-size", "0.6em")
  .style("text-anchor", "start");


		
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
      var xPosition = parseFloat(d3.select(this).attr("x")) + 2 * xScale.bandwidth();
      var yPosition = parseFloat(d3.select(this).attr("y") - 10);
      
      //Update the tooltip position and value
      d3.select("#tooltip")
        .style("left", xPosition + "px")
        .style("top", yPosition + "px")
        .style("opacity", 1)
        .style("width", (d.solver.length / 2 + 7)  + "em");
      d3.select("#value")
        .text("error = " + d.RMSE.toFixed(2)); 
      d3.select("#header")
        .text("solver = " + d.solver);
         

    })
    .on("mouseout", function(d) {
      d3.select(this)
        .transition()
        .duration(250)
        .attr("opacity", opacity);
        
      //Hide the tooltip
      d3.select("#tooltip").style("opacity", 0);
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
svg.append("g")
    .attr("class", "ref line")
    .append("line")
    .attr("y1", yScale(0))
    .attr("y2", yScale(0))
    .attr("x1", xScale(0))
    .attr("x2", width - xPadding)
    .attr("stroke", "black");
    
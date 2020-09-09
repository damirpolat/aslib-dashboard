# server.R
# Damir Pulatov

library(shiny)
library(mlr)
library(llama)
library(aslib)
library(scatterD3)
library(shinyFiles)
library(plyr)
library(dplyr)
library(plotly)
library(htmlwidgets)
library(tidyr)
source("./helpers.R")
set.seed(1L)


shinyServer(function(input, output) { 
  server.files = list.files(path = "./server", pattern = "*.R")
  server.files = paste0("server/", server.files)
  for (i in seq_along(server.files)) {
    source(server.files[i], local = TRUE)
  }
  
})
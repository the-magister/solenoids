### clear memory
rm(list=ls())
gc()

### required packages
packages = c('shiny','reshape2','ggplot2','ggthemes','dplyr','serial','tcltk')

### Install CRAN packages (if not already installed)
inst = packages %in% installed.packages()
if(length(packages[!inst]) > 0) install.packages(packages[!inst], dependencies=T)

### library
require(shiny)

### run it
runApp(".")



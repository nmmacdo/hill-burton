# Title: Explore / data visualization
# Project: Hill-Burton
# Author: Noah MacDonald
# Date Created: December 9, 2022
# Last Edited: December 14, 2022

# Loading required packages
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, ggplot2, lubridate, crosswalkr, fixest, modelsummary,
               readxl, haven, usmap)

# Setting working directory
setwd("C:/Users/noahm/OneDrive - Emory University/Grad/ideas/hill-burton")

# Loading data
# AHRF <- read_sas("data/raw/AHRF2021.sas7bdat")
usmap1 <- read.csv("data/final/county_plot_data.csv", 
                   colClasses = c(fips = "character"))
usmap2 <- read.csv("data/final/state_plot_data.csv", 
                   colClasses = c(fips = "character"))
usmap3 <- read.csv("data/final/state_funding_totals.csv", 
                   colClasses = c(fips = "character"))

# Working with usmap package: county-level
plot_usmap(regions = "counties", exclude = c("Alaska", "Hawaii"),
           data = usmap1, values = "hbfund") + 
  scale_fill_continuous(low = "White", high = "red", 
                        name = "Total USD") + 
  theme(legend.position = "right") + 
  labs(title = "Total Hill-Burton Funding as of 1969")
# State-level
plot_usmap(regions = "states", exclude = c("Alaska", "Hawaii"),
           data = usmap2, values = "hbfund_pc") + 
  scale_fill_continuous(low = "white", high = "blue", 
                        name = "$ per capita") + 
  theme(legend.position = "right") + 
  labs(title = " Per Capita Hill-Burton Funding as of 1969 (preliminary)")

plot_usmap(regions = "states", exclude = c("Alaska", "Hawaii"),
           data = usmap2, values = "pct_nw") + 
  scale_fill_continuous(low = "white", high = "blue", 
                        name = "% nonwhite") + 
  theme(legend.position = "right") + 
  labs(title = "Nonwhite Population Percentage")

plot_usmap(regions = "states", exclude = c("Alaska", "Hawaii"),
           data = usmap3, values = "hbfund") + 
  scale_fill_continuous(low = "white", high = "blue", 
                        name = "Total USD") + 
  theme(legend.position = "right") + 
  labs(title = "Total Hill-Burton Funding as of 1969")
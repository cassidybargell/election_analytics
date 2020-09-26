## Week Three - Figures
## 9/26/20

#### Set-up ####

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)

# Read in data
# FRED.org for resources
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
econ <- read_csv("data/econ.csv")
local_econ <- read_csv("data/local.csv")
rdpi <- read_csv("data/DSPIC96.csv") #FRED
unrate <- read_csv("data/UNRATE (1).csv") #FRED
inflate <- read_csv("data/FPCPITOTLZGUSA.csv") # FRED
poll <- read_csv("data/pollavg_1968-2016.csv")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)
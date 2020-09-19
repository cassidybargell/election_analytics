## Week Tw0 - Figures
## 9/21/20

#### Set-up ####

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)

# Read in data
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
econ <- read_csv("data/econ.csv")
local_econ <- read_csv("data/local.csv")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)
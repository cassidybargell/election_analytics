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
# rdpi <- read_csv("data/DSPIC96.csv") #FRED
# unrate <- read_csv("data/UNRATE (1).csv") #FRED
# inflate <- read_csv("data/FPCPITOTLZGUSA.csv") # FRED
poll <- read_csv("data/pollavg_1968-2016.csv")
poll_2020 <- read_csv("data/polls_2020.csv")
poll_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
poll_2020_fte <- read_csv("https://projects.fivethirtyeight.com/2020-general-data/presidential_poll_averages_2020.csv")
states <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA) %>%
  mutate(poll_lwr = NA) %>%
  mutate(poll_uppr = NA) %>%
  mutate(poll_fit = NA) %>%
  mutate(econ_lwr = NA) %>%
  mutate(econ_uppr = NA) %>%
  mutate(econ_fit = NA)

election_years <- data.frame(year = seq(from=1948, to=2020, by=4))

# Create local unemployment dataframe, use Q2 unemployment data
local <- local_econ %>%
  rename("state" = `State and area`) %>%
  rename("year" = `Year`) %>%
  filter(Month == "04" | Month == "05" | Month == "06") %>%
  group_by(state, year) %>%
  summarize(local_unemploy = mean(Unemployed_prce)) %>%
  ungroup() %>%
  right_join(election_years) %>%
  left_join(pvstate)

states_list <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)

# Join poll state and popular vote by state
state_pv_poll_rep <- poll_state %>%
  filter(party == "republican") %>%
  filter(weeks_left == 6) %>%
  group_by(year, candidate_name, state) %>%
  mutate(avg_pollyr = mean(avg_poll)) %>%
  left_join(pvstate) 

# linear model for republican vote share and poll averages
statepoll_lm_rep <- function(state){
  ok <- state_pv_poll_rep %>%
    filter(state == state)
  
  lm(R_pv2p ~ avg_poll, data = ok)
}

# test with Alabama
AL_lm_poll <- statepoll_lm_rep("Alabama")

# linear model for local unemployment rate
statelocal_lm_rep <- function(state){
  ok <- local %>%
    filter(state == state)
  
  # use republican vote share, leanred in section republicans are hurt more by
  # high unemployment than democrats are
 lm(R_pv2p ~ local_unemploy, data = ok)
}

# test with Alabama
AL_lm_econ <- statelocal_lm_rep("Alabama")

# find 2020 values for AL
ALecon <- local %>%
  filter(state == "Alabama") %>%
  filter(year == 2020) %>%
  select(local_unemploy) 

ALpoll <- poll_2020 %>%
  filter(state == "Alabama") %>%
  summarize(avg = mean(pct)) %>%
  rename(avg_poll = "avg")

# create weights for ensembles
days_left <- 40
pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))

# predict AL with weighted towards polls closer to election
AL <- pwt*predict(AL_lm_poll, ALpoll) + ewt*predict(AL_lm_econ, ALecon) # adjusted poll

# Need to make functions to then run through all states
predict_function <- function(s){
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)

  Spoll <- poll_2020 %>%
    filter(state == s) %>%
    summarize(avg = mean(pct)) %>%
    rename(avg_poll = "avg")

  days_left <- 40
  pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction <- pwt*predict(s_lm_poll, Spoll) + ewt*predict(s_lm_econ, Secon)
}

# Loop through all the states possible with standard state list, save to data frame
for (state in states_list){
state_prediction <- predict_function(state)
states$predictions[states$state == state] <- state_prediction
}

# Could go through other states/districts
NE_1 <- predict_function("NE-1")

#### Confidence Intervals 

CIpoll_function <- function(s){
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_2020 %>%
    filter(state == s) %>%
    summarize(avg = mean(pct)) %>%
    rename(avg_poll = "avg")

 poll_CI <- predict(s_lm_poll, Spoll, interval = "prediction", level = 0.95)
 #  unemploy_CI <- predict(s_lm_econ, Secon, interval = "prediction", level = 0.95)
}

CIecon_function <- function(s){
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_2020 %>%
    filter(state == s) %>%
    summarize(avg = mean(pct)) %>%
    rename(avg_poll = "avg")
  
  # poll_CI <- predict(s_lm_poll, Spoll, interval = "prediction", level = 0.95)
  unemploy_CI <- predict(s_lm_econ, Secon, interval = "prediction", level = 0.95)
}
# Loop through again
for (state in states_list){
  CIpoll_prediction <- CIpoll_function(state)
  CIecon_prediction <- CIecon_function(state)
  states$poll_fit[states$state == state] <- CIpoll_prediction[, 1]
  states$poll_lwr[states$state == state] <- CIpoll_prediction[, 2]
  states$poll_uppr[states$state == state] <- CIpoll_prediction[, 3]
  states$econ_fit[states$state == state] <- CIecon_prediction[, 1]
  states$econ_lwr[states$state == state] <- CIecon_prediction[, 2]
  states$econ_uppr[states$state == state] <- CIecon_prediction[, 3]
}

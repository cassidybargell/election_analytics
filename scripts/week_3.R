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
library(googlesheets4)
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
# poll <- read_csv("data/pollavg_1968-2016.csv")
poll_2020 <- read_csv("data/polls_2020.csv")
poll_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
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
# electoral college votes google sheet
gs4_deauth()
electoral_college <- read_sheet("https://docs.google.com/spreadsheets/d/1nOjlGrDkH_EpcqRzWQicLFjX0mo0ymrh8k6FaG0DRdk/edit?usp=sharing") %>%
  slice(1:51) %>%
  select(state, votes)

# useful for subsetting just election years
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

# create list of states to loop through eventually 
states_list <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)

# Join poll state and popular vote by state, use weeks left = 6 because that is closest data we have
state_pv_poll_rep <- poll_state %>%
  filter(party == "republican") %>%
  filter(weeks_left <= 6) %>%
  group_by(year, candidate_name, state) %>%
  mutate(avg_pollyr = mean(avg_poll)) %>%
  left_join(pvstate) 

# linear model for republican vote share and poll averages
statepoll_lm_rep <- function(s){
  ok <- state_pv_poll_rep %>%
    filter(state == s)
  
  lm(R_pv2p ~ avg_pollyr, data = ok)
}

# test with Alabama
# AL_lm_poll <- statepoll_lm_rep("Alabama")

# linear model for local unemployment rate
statelocal_lm_rep <- function(s){
  ok <- local %>%
    filter(state == s)
  
  # use republican vote share, leanred in section republicans are hurt more by
  # high unemployment than democrats are
 lm(R_pv2p ~ local_unemploy, data = ok)
}

# test with Alabama
# AL_lm_econ <- statelocal_lm_rep("Alabama")
# 
# # find 2020 values for AL
# ALecon <- local %>%
#   filter(state == "Alabama") %>%
#   filter(year == 2020) %>%
#   select(local_unemploy) 
# 
# ALpoll <- poll_2020 %>%
#   filter(state == "Alabama") %>%
#   summarize(avg = mean(pct)) %>%
#   rename(avg_poll = "avg")
# 
# # create weights for ensembles
days_left <- 40
pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
# 
# # predict AL with weighted towards polls closer to election
# AL <- pwt*predict(AL_lm_poll, ALpoll) + ewt*predict(AL_lm_econ, ALecon) # adjusted poll

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
    rename(avg_pollyr = "avg")

  days_left <- 40
  pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction <- pwt*predict(s_lm_poll, Spoll) + 
    ewt*predict(s_lm_econ, Secon)
}

# Loop through all the states possible with standard state list, save to data
# frame
for (s in states_list){
state_prediction <- predict_function(s)
states$predictions[states$state == s] <- state_prediction
}

# Could go through other states/districts, but polling information not complete
# NE_1 <- predict_function("NE-1")
# WY <- predict_function("Wyoming")

#### Confidence Intervals 

# create function to find just confidence intervals of polling model 
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
    rename(avg_pollyr = "avg")

 poll_CI <- predict(s_lm_poll, Spoll, interval = "prediction", level = 0.95)
}

# create function to find confidence intervals of just the economic data
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
    rename(avg_pollyr = "avg")

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


#### Visualizations 

# much easier to interpret win margin in colors
state_viz <- states %>%
  mutate(D_pv2p = (100 - predictions)) %>%
  mutate(win_margin = (D_pv2p-predictions)) %>%
  mutate(poll_d = (100 - poll_fit)) %>%
  mutate(poll_margin = (poll_d - poll_fit)) %>%
  mutate(econ_d = (100 - econ_fit)) %>%
  mutate(econ_margin = (econ_d - econ_fit))

# plot map of win margin predictions
plot_usmap(data = state_viz, regions = "states", values = "win_margin") + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red", 
    breaks = c(-60, -40, -20, 0, 20), 
    limits = c(-61, 20),
    name = "Win Margin") + 
  labs(title = "Predicted Win Margin of Two-Party Popular Vote Share",
       subtitle = "Weighted Ensemble of Week 6 Poll Averages (0.15) and Local Unemployment (0.85)",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/pollecon_weightedensemble_map.png")

# Plot to show errors - polling vs. popular vote share
ggplot(state_viz, aes(x = poll_fit, y = state, color = poll_fit)) + 
  geom_point() + 
  geom_errorbar(aes(xmin = poll_lwr, xmax = poll_uppr)) +
  scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "Election Outcome Prediction - State Polling Averages",
       subtitle = "Poll averages 6 weeks out from election date",
       caption = "Predicted using a linear model comparing historical polling averages and 
       two-party popular vote share.")

ggsave("figures/hist_polling_lm.png")

# Plot to show errors - local unemployment vs. popular vote share
ggplot(state_viz, aes(x = econ_fit, y = state, color = econ_fit)) + 
  geom_point() + 
  geom_errorbar(aes(xmin = econ_lwr, xmax = econ_uppr)) +
  scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "Election Outcome Prediction - Q2 State Unemployment Rates",
       subtitle = "Q2 historical unemployment rates",
       caption = "Predicted using a linear model comparing historical Q2 state unemployment rates 
       vs. two-party popular vote share.")

ggsave("figures/hist_unemploystate_lm.png")

#### Predict using electoral college votes

# find prediction with electoral college votes
ec <- states %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

# use poll fits
ec_poll <- states %>%
  left_join(electoral_college) %>%
  filter(! is.na(poll_fit)) %>%
  mutate(dem_win = ifelse(poll_fit < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(poll_fit >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

# use econ fits 
ec_econ <- states %>%
  left_join(electoral_college) %>%
  filter(! is.na(econ_fit)) %>%
  mutate(dem_win = ifelse(econ_fit < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(econ_fit >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

#### Switch weighting to more poll heavy 

# simple switch of weights 
predict_function_poll <- function(s){
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_2020 %>%
    filter(state == s) %>%
    summarize(avg = mean(pct)) %>%
    rename(avg_pollyr = "avg")
  
  days_left <- 40
  pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction <- ewt*predict(s_lm_poll, Spoll) + 
    pwt*predict(s_lm_econ, Secon)
}

# Loop through all the states possible with standard state list, save to data
# frame
for (s in states_list){
  state_prediction2 <- predict_function_poll(s)
  states$predictions_2[states$state == s] <- state_prediction2
}

# add new margin to state_viz
state_viz <- states %>%
  mutate(D_pv2p = (100 - predictions_2)) %>%
  mutate(win_margin2 = (D_pv2p-predictions))

# plot map of win margin predictions
plot_usmap(data = state_viz, regions = "states", values = "win_margin2") + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red", 
    breaks = c(-60, -40, -20, 0, 20), 
    limits = c(-61, 20),
    name = "Win Margin") + 
  labs(title = "Predicted Win Margin of Two-Party Popular Vote Share",
       subtitle = "Weighted Ensemble of Week 6 Poll Averages (0.85) and Local Unemployment (0.15)",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/pollecon_weightedensemble2_map.png")

ec2 <- states %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions_2)) %>%
  mutate(dem_win = ifelse(predictions_2 < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions_2 >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

#### Aggregate poll prediction 
# start, maybe finish later

# choose only necessary items from poll_2020 data for weighted average with fte_grade
agg_poll <- poll_2020 %>%
  filter(answer == "Biden" | answer == "Trump") %>%
  select(state, pct, fte_grade) %>%
  filter(! is.na(state)) %>%
  filter(! is.na(fte_grade))

# create predict function to loop through states
predict_fte_state <- function(s){

 s <- agg_poll %>%
   group_by(state, fte_grade) %>%
   summarize(avg = mean(pct)) %>%
   mutate(state = s) %>%
   gt()
}

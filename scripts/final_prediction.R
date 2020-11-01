## Week Eight - Final Prediction
## 11/1/20

#### Set-up ####
# Load necessary packages and data
library(tidyverse)
library(googlesheets4)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)
options(scipen = 999)
library(cowplot) 
library(scales)
library(geofacet)
library(maps)
library(statebins)
library(Metrics)
library(modelr)
library(dvmisc)

gs4_deauth()

states_map <- ggplot2::map_data("state")

map_theme = function() {
  theme(axis.title = element_blank()) +
    theme(axis.text = element_blank()) +
    theme(axis.ticks = element_blank()) + 
    theme(legend.title = element_blank()) +
    theme(panel.grid.major = element_blank())
  
}

states_list <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming")

# Read in data
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
approval <- read_csv("data/approval_gallup_1941-2020.csv")
covid_approval_fte <- read_csv("data/covid_approval_polls_adjusted.csv") # FTE
covid_approval_avg <- read_csv("data/covid_approval_toplines.csv") # FTE
covid_awards <- read_csv("data/covid_awards_bystate.csv") # https://taggs.hhs.gov/coronavirus
# poll_2020 <- read_csv("data/polls_2020.csv") %>%
  # rename(date = "end_date") %>% # for a join
  # mutate(date = as.Date(date, "%m/%d/%y"))
states <- read_csv("data/csvData.csv") %>%
  rename(state = "Code")
# https://data.hrsa.gov/data/reports/datagrid?gridName=COVID19FundingReport
vep <- read_csv("data/vep_1980-2016.csv")
poll_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
turnout <- read_csv("data/turnout_1980-2016.csv")
local_econ <- read_csv("data/local.csv")
gs4_deauth()
electoral_college <- read_sheet("https://docs.google.com/spreadsheets/d/1nOjlGrDkH_EpcqRzWQicLFjX0mo0ymrh8k6FaG0DRdk/edit?usp=sharing") %>%
  slice(1:51) %>%
  select(state, votes)
county_covid <- read_csv("data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv") %>%
  rename(fips = "FIPS County Code") %>%
  rename(state = "State") %>%
  rename(deaths = "Deaths involving COVID-19") %>%
  rename(county = "County name")
# pv_county <- read_csv("data/popvote_bycounty_2000-2016.csv")
state_covid <- read_csv("data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv") %>%
  mutate(date = as.Date(submission_date, "%m/%d/%y"))
census_data <- read_csv("data/nst-est2019-alldata.csv") %>%
  rename(State = "NAME") %>%
  rename(pop_2019 = "POPESTIMATE2019") %>%
  select(State, pop_2019) %>%
  left_join(states)
day7_covid_rates <- read_csv("data/new-united_states_covid19_cases_and_deaths_by_state.csv") %>%
  rename(rate = "Death Rate per 100K in Last 7 Days") %>%
  rename(state = "State/Territory")
all_time_covid_rates <- read_csv("data/united_states_covid19_cases_and_deaths_by_state (1).csv")
polls_10_29 <- read_csv("data/10_29_presidential_poll_averages_2020.csv")

county_covid$county = as.character(gsub("County", "", county_covid$county))
election_years <- data.frame(year = seq(from=1948, to=2020, by=4))

# Blank prediction tibble
states_predictions <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA) %>%
  mutate(lwr = NA) %>%
  mutate(uppr = NA) %>%
  mutate(econ_coef = NA) %>%
  mutate(demog_coef = NA) %>%
  mutate(polls_coef = NA) %>%
  mutate(covid_coef = NA) %>%
  mutate(econ_rmse = NA) %>%
  mutate(demog_rmse = NA) %>%
  mutate(covid_rmse = NA) %>%
  mutate(polls_rmse = NA) %>%
  mutate(weighted_rmse = NA)

### Combine data for later use
# Make each data frame for each part of weighted ensemble what I need it to be

# make data easier to join
pvstate2 <- pvstate %>%
  select(! total)

demog <- demog %>%
  full_join(states) %>%
  select(! state) %>%
  select(! Abbrev) %>%
  rename(state = "State")

# Historical demographics, add state names and popular vote share
hist_demog <- demog %>%
  right_join(pvstate2)

# Historical local unemployment
hist_econ <- local_econ %>%
  rename("state" = `State and area`) %>%
  rename("year" = `Year`) %>%
  filter(Month == "04" | Month == "05" | Month == "06") %>%
  group_by(state, year) %>%
  summarize(local_unemploy = mean(Unemployed_prce)) %>%
  ungroup() %>%
  right_join(election_years) %>%
  left_join(pvstate2)

# Historical poll support for republican less than 1 week out 
hist_poll <- poll_state %>%
  filter(party == "republican") %>%
  filter(weeks_left <= 1) %>%
  group_by(year, candidate_name, state) %>%
  mutate(avg_pollyr = mean(avg_poll)) %>%
  left_join(pvstate2) 

# This years COVID deaths and polls matched by date
covid_2020 <- polls_10_29 %>%
  rename(avg_poll = "pct_trend_adjusted") %>%
  rename(State = "state") %>%
  mutate(date = as.Date(modeldate, "%m/%d/%y")) %>%
  filter(candidate_name == "Donald Trump") %>%
  group_by(State, date) %>%
  left_join(states) %>%
  select(state, date, avg_poll) %>%
  right_join(state_covid) %>%
  select(avg_poll, state, tot_death, date) %>%
  filter(! is.na(avg_poll)) %>%
  left_join(census_data) %>%
  mutate(percap = (tot_death/pop_2019)) %>%
  group_by(state) %>%
  mutate(rate = (100000*((tot_death - lead(tot_death, n = 7))/ pop_2019))) %>%
  filter(! is.na(rate)) %>%
  filter(! grepl('Inf', rate)) %>%
  rename(two_abb = "state") %>%
  select(State, rate, date, avg_poll) %>%
  rename(state = "State")

#### Weighted Ensemble 
# Polling most heavily, demographics, state level economics
# and then covid weight least

## Glm models
poll_glm <- function(s){
  ok <- hist_poll %>%
    filter(state == s)
  
  glm(R_pv2p ~ avg_pollyr, data = ok)
}

econ_glm <- function(s){
  ok <- hist_econ %>%
    filter(state == s)
  glm(R_pv2p ~ local_unemploy, data = ok)
}

demog_glm <- function(s){
  ok <- hist_demog %>%
    filter(state == s)
  
  glm(R_pv2p ~ White, data = ok)
}

covid_glm <- function(s){
  ok <- covid_2020 %>%
    filter(state == s)
  
  glm(avg_poll ~ rate, data = ok)
}

# Test everything with Colorado to find mistakes 
co_demog <- demog_glm("Colorado")
co_poll <- poll_glm("Colorado")
co_econ <- econ_glm("Colorado")
co_covid <- covid_glm("Colorado")

COSecon <- hist_econ %>%
  filter(state == "Colorado") %>%
  filter(year == 2020) %>%
  select(local_unemploy)

COSpoll <- polls_10_29 %>%
  filter(modeldate == "10/29/2020") %>%
  filter(candidate_name == "Donald Trump") %>%
  filter(state == "Colorado") %>%
  rename(avg_pollyr = "pct_trend_adjusted")

COSdemog <- demog %>%
  filter(state == "Colorado") %>%
  filter(year == 2018) %>%
  select(state, year, White)

COScovid <- day7_covid_rates %>%
  filter(state == "Colorado")

CO_prediction <- 0.97*predict(co_poll, COSpoll) + 
  0.01*predict(co_econ, COSecon) + 0.01*predict(co_demog, COSdemog) + 
  0.01*predict(co_covid, COScovid)

# Create predict function with all the variables
predict_function <- function(s){
  s_glm_demog <- demog_glm(s)
  s_glm_poll <- poll_glm(s)
  s_glm_econ <- econ_glm(s)
  s_glm_covid <- covid_glm(s)
  
  Secon <- hist_econ %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- polls_10_29 %>%
    filter(modeldate == "10/29/2020") %>%
    filter(candidate_name == "Donald Trump") %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  Scovid <- day7_covid_rates %>%
    filter(state == s)
  
state_prediction <- 0.85*predict(s_glm_poll, Spoll) + 
    0.05*predict(s_glm_econ, Secon) + 0.05*predict(s_glm_demog, Sdemog) + 
    0.05*predict(s_glm_covid, Scovid)
}

# loop through all states
for (s in states_list){
  state_prediction <- predict_function(s)
  states_predictions$predictions[states_predictions$state == s] <- state_prediction
}

#### Create Confidence Intervals for final prediction
# function to pull a state standard error. Weight the same as original model 
CI_function_se <- function(s){
  s_glm_demog <- demog_glm(s)
  s_glm_poll <- poll_glm(s)
  s_glm_econ <- econ_glm(s)
  s_glm_covid <- covid_glm(s)

  Secon <- hist_econ %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- polls_10_29 %>%
    filter(modeldate == "10/29/2020") %>%
    filter(candidate_name == "Donald Trump") %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  Scovid <- day7_covid_rates %>%
    filter(state == s)
  
  prediction_CI_se <- 0.85*predict(s_glm_poll, Spoll, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$se.fit + 
    0.05*predict(s_glm_econ, Secon, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$se.fit + 
    0.05*predict(s_glm_demog, Sdemog, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$se.fit + 
    0.05*predict(s_glm_covid, Scovid, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$se.fit

}

# function to pull fit of each state (same as prediction I just found this
# method easier). Weight the same as the model
CI_function_fit <- function(s){
  s_glm_demog <- demog_glm(s)
  s_glm_poll <- poll_glm(s)
  s_glm_econ <- econ_glm(s)
  s_glm_covid <- covid_glm(s)
  
  Secon <- hist_econ %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- polls_10_29 %>%
    filter(modeldate == "10/29/2020") %>%
    filter(candidate_name == "Donald Trump") %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  Scovid <- day7_covid_rates %>%
    filter(state == s)
  
  prediction_CI_fit <- 0.85*predict(s_glm_poll, Spoll, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$fit + 
    0.05*predict(s_glm_econ, Secon, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$fit + 
    0.05*predict(s_glm_demog, Sdemog, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$fit + 
    0.05*predict(s_glm_covid, Scovid, interval = "prediction", level = 0.95, type = "link", se.fit = TRUE)$fit
  
}

# Loop through again, find upper and lower bounds.
for (s in states_list){
  CI_prediction_se <- CI_function_se(s)
  CI_prediction_fit <- CI_function_fit(s)
  
  critval <- 1.96 ## approx 95% CI
  
  states_predictions$lwr[states_predictions$state == s] <- CI_prediction_fit - (critval * CI_prediction_se)
  states_predictions$uppr[states_predictions$state == s] <- CI_prediction_fit + (critval * CI_prediction_se)
}

# join electoral college
pred_final <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win)) %>%
  mutate(winner = ifelse(dem_win > 0, "Democrat", "Republican")) %>%
  mutate(d_pred = (100 - predictions)) %>%
  mutate(win_margin = (d_pred - predictions))

#### RMSE

# Make rmse functions

# test with CO first
co_poll_mse <- get_mse(co_poll)

# polls
mse_function_poll <- function(s){
  s_glm_poll <- poll_glm(s)
s_poll_mse <- get_mse(s_glm_poll)
}

for (s in states_list){
  s_poll_mse <- mse_function_poll(s)
  states_predictions$polls_rmse[states_predictions$state == s] <- sqrt(s_poll_mse)
}

 
# econ
mse_function_econ <- function(s){
  s_glm_econ <- econ_glm(s)
  s_econ_mse <- get_mse(s_glm_econ)
}

for (s in states_list){
  s_econ_mse <- mse_function_econ(s)
  states_predictions$econ_rmse[states_predictions$state == s] <- sqrt(s_econ_mse)
}

# demog 
mse_function_demog <- function(s){
  s_glm_demog <- demog_glm(s)
  s_demog_mse <- get_mse(s_glm_demog)
}

for (s in states_list){
  s_demog_mse <- mse_function_demog(s)
  states_predictions$demog_rmse[states_predictions$state == s] <- sqrt(s_demog_mse)
}

# covid 
mse_function_covid <- function(s){
  s_glm_covid <- covid_glm(s)
  s_covid_mse <- get_mse(s_glm_covid)
}

for (s in states_list){
  s_covid_mse <- mse_function_covid(s)
  states_predictions$covid_rmse[states_predictions$state == s] <- sqrt(s_covid_mse)
}

# weight the rmse same to model 

for (s in states_list){
  s_weighted_mse <- states_predictions %>% filter(state == s) %>%
    mutate(weighted = (0.85*polls_rmse + 0.5*econ_rmse + 0.5*covid_rmse + 0.5*demog_rmse)) %>%
    select(weighted)
  states_predictions$weighted_rmse[states_predictions$state == s] <- s_weighted_mse
}


#### Visualizations

# Visualize state map wins 
ggplot(pred_final, aes(state = state, fill = win_margin)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red",
    name = "Win Margin") + 
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model",
       fill = "Projected Democrat Win Margin")

ggsave("figures/10_31_predictionmap.png")

# Same visualization without graded win margin
ggplot(pred_final, aes(state = state, fill = winner)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) + 
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model",
       fill = "Predicted Two-Party Popular Vote Winner")

ggsave("figures/10_31_predictionmap_winners.png")

# Visualize confidence intervals of final prediction
ggplot(pred_final, aes(x = predictions, y = state, color = winner)) + 
  geom_point() + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democratic", "Republican")) + 
  geom_errorbar(aes(xmin = lwr, xmax = uppr)) +
  # scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Predicted Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "Range of Predicted Republican Popular Vote Share %",
       subtitle = "Weighted Ensemble Model")

ggsave("figures/10_31_ci_predictions.png")


# visualize states with confidence intervals that include 50%, could swing in my
# model

potential_swing <- pred_final %>%
  mutate(swing = ifelse(lwr <  50 & uppr > 50, TRUE, FALSE)) %>%
  filter(swing == TRUE)

ggplot(potential_swing, aes(x = predictions, y = state, color = winner)) + 
  geom_point() + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democratic", "Republican")) + 
  geom_errorbar(aes(xmin = lwr, xmax = uppr)) +
  # scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Predicted Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "Range of Predicted Republican Popular Vote Share %",
       subtitle = "Weighted Ensemble Model")

ggsave("figures/10_31_swing.png")

# Upper bound of prediction interval 
pred_upper <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win_upper = ifelse(uppr < 50, votes, 0)) %>%
  mutate(rep_win_upper = ifelse(uppr >50, votes, 0)) %>%
  mutate(rep_ec_upper = sum(rep_win_upper)) %>%
  mutate(dem_ec_upper = sum(dem_win_upper)) %>%
  mutate(winner_upper = ifelse(dem_win_upper > 0, "Democrat", "Republican")) %>%
  mutate(d_pred_upper = (100 - uppr)) %>%
  mutate(win_margin_upper = (d_pred_upper - uppr))

# Plot upper win predictions
ggplot(pred_upper, aes(state = state, fill = win_margin_upper)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red",
    name = "Win Margin") + 
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model, Upper Bounds",
       fill = "Projected Democrat Win Margin")

ggsave("figures/10_31_predictionmap_uppr.png")

# Same without graded fill 
ggplot(pred_upper, aes(state = state, fill = winner_upper)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model, Upper Bounds",
       fill = "Projected Democrat Win Margin")

ggsave("figures/10_31_predictionmap_uppr_winner.png")

# Do the same for lower bound predictions
pred_lwr <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win_lwr = ifelse(lwr < 50, votes, 0)) %>%
  mutate(rep_win_lwr = ifelse(lwr >50, votes, 0)) %>%
  mutate(rep_ec_lwr = sum(rep_win_lwr)) %>%
  mutate(dem_ec_lwr = sum(dem_win_lwr)) %>%
  mutate(winner_lwr = ifelse(dem_win_lwr > 0, "Democrat", "Republican")) %>%
  mutate(d_pred_lwr = (100 - lwr)) %>%
  mutate(win_margin_lwr = (d_pred_lwr - lwr))

# Plot lwr win predictions
ggplot(pred_lwr, aes(state = state, fill = win_margin_lwr)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red",
    name = "Win Margin") + 
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model, Lower Bounds",
       fill = "Projected Democrat Win Margin")

ggsave("figures/10_31_predictionmap_lwr.png")

# Same without graded win margin
ggplot(pred_lwr, aes(state = state, fill = winner_lwr)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) + 
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted Ensemble Model, Lower Bounds", 
       fill = "Projected Winner")

ggsave("figures/10_31_predictionmap_lwr_winner.png")

# not use change in demographics because just want to represent white voter
# population, polling bias from 2016/idea of shy Trump supporter?




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
  mutate(uppr = NA)

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

CO_prediction <- 0.85*predict(co_poll, COSpoll) + 
  0.04*predict(co_econ, COSecon) + 0.1*predict(co_demog, COSdemog) + 
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
  
state_prediction <- 0.9*predict(s_glm_poll, Spoll) + 
    0.01*predict(s_glm_econ, Secon) + 0.07*predict(s_glm_demog, Sdemog) + 
    0.01*predict(s_glm_covid, Scovid)
}

# loop through all states
for (s in states_list){
  state_prediction <- predict_function(s)
  states_predictions$predictions[states_predictions$state == s] <- state_prediction
}

# join electoral college
pred <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

# not use change in demographics because just want to represent white voter
# population, polling bias from 2016/idea of shy Trump supporter?




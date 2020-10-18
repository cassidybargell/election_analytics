## Week Six - Ground Game
## 10/19/20

# create model that predicts voteshare based on demographics of a state 
# predict 2020 democratic vote share based on demographics through 2020? 
# add demographic predictions to the weighted ensemble you did however many weeks ago 
# talk about ground game in final blog post.

#### Set-up ####
# Load necessary packages
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
gs4_deauth()

states_map <- ggplot2::map_data("state")

map_theme = function() {
  theme(axis.title = element_blank()) +
    theme(axis.text = element_blank()) +
    theme(axis.ticks = element_blank()) + 
    theme(legend.title = element_blank()) +
    theme(panel.grid.major = element_blank())
}

# Read in data
fo_county <- read_sheet("https://docs.google.com/spreadsheets/d/1N8NIGmCaiXC3DC1GMW5vegRTHzc43juJEASJ84A-ebk/edit#gid=707282698")
fo_address <- read_csv("data/fieldoffice_2012-2016_byaddress.csv")
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
approval <- read_csv("data/approval_gallup_1941-2020.csv")
covid_approval_fte <- read_csv("data/covid_approval_polls_adjusted.csv") # FTE
covid_approval_avg <- read_csv("data/covid_approval_toplines.csv") # FTE
covid_awards <- read_csv("data/covid_awards_bystate.csv") # https://taggs.hhs.gov/coronavirus
poll_2020 <- read_csv("data/polls_2020.csv") %>%
  rename(date = "end_date") %>% # for a join
  mutate(date = as.Date(date, "%m/%d/%y"))
states <- read_csv("data/csvData.csv") %>%
  rename(state = "Code")
# https://data.hrsa.gov/data/reports/datagrid?gridName=COVID19FundingReport
county_grants <- read_csv("data/COVID19_Grant_Report.csv")
fed_grants <- read_csv("data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv") 
ad_creative <- read_csv("data/ad_creative_2000-2012.csv")
vep <- read_csv("data/vep_1980-2016.csv")
poll_state <- read_csv("data/pollavg_bystate_1968-2016.csv")
demog <- read_csv("data/demographic_1990-2018.csv")
fo_2012 <- read_csv("data/fieldoffice_2012_bycounty.csv")
fo_dems <- read_csv("data/fieldoffice_2004-2012_dems.csv")
turnout <- read_csv("data/turnout_1980-2016.csv")
local_econ <- read_csv("data/local.csv")
gs4_deauth()
electoral_college <- read_sheet("https://docs.google.com/spreadsheets/d/1nOjlGrDkH_EpcqRzWQicLFjX0mo0ymrh8k6FaG0DRdk/edit?usp=sharing") %>%
  slice(1:51) %>%
  select(state, votes)

states_predictions <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA)

#### Exploration initially 

# number of field offices vs number of contacts
fo_county %>%
  filter(state != "Nationwide") %>%
ggplot(aes(x = field.offices, y = contacts)) + geom_point() + 
  geom_smooth(method = lm)

# number of types of contacts
fo_county %>%
  filter(state == "Nationwide") %>%
  pivot_longer(cols = c(Phone, Mail, Door)) %>%
  ggplot(aes(x = name, y = value)) + geom_col()

#### Combine data 

# add state names
demog <- demog %>%
  full_join(states) %>%
  select(! state) %>%
  select(! Abbrev) %>%
  rename(state = "State")

# make data easier to join
pvstate2 <- pvstate %>%
  select(! total)

# join data, filter rows
demog_pv_plot <- demog %>%
  right_join(pvstate2) %>%
  pivot_longer(cols = c(Hispanic, Black, White, Asian, Indigenous, Female, Male, 
                        age20, age3045, age4565, age65), 
               names_to = "demographic", values_to = "demographic_pct") %>%
  # filter(! is.na(Hispanic)) %>%
  filter(state != "District of Columbia") %>%
  filter(year == 2016)
  # filter(state != "Hawaii"), when hawaii is not included, slope jumps up to 1

# create visualizations 

# age demographics
demog_pv_plot %>%
  filter(demographic == "age20" | demographic == "age3045" | demographic == "age4565" | 
           demographic == "age65") %>%
ggplot(aes(y = D_pv2p, x = demographic_pct, color = demographic)) + geom_point() + 
  # facet_wrap(~ demographic) + 
  geom_smooth(method = "lm")

# race/ethnicity demographics
demog_pv_plot %>%
  filter(demographic == "Asian" | demographic == "Black" | demographic == "White" | 
           demographic == "Hispanic" | demographic == "Indigenous") %>%
  ggplot(aes(y = D_pv2p, x = demographic_pct, color = demographic)) + geom_point() + 
  facet_wrap(~ demographic) + 
  geom_smooth(method = "lm")

# sex demographics
demog_pv_plot %>%
  filter(demographic == "Female" | demographic == "Male") %>%
  ggplot(aes(y = D_pv2p, x = demographic_pct, color = demographic)) + geom_point() + 
  facet_wrap(~ demographic) + 
  geom_smooth(method = "lm")

# make new joined data for linear models 
demog_pv <- demog %>%
  right_join(pvstate2) %>%
  # pivot_longer(cols = c(Hispanic, Black, White, Asian, Indigenous, Female, Male, 
                       # age20, age3045, age4565, age65), 
               # names_to = "demographic", values_to = "demographic_pct") %>%
  filter(state != "District of Columbia") %>%
  filter(year == 2016)

# linear models 
# if no t values given, t values > 2
lm_asian_demog <- lm(D_pv2p ~ Asian, data = demog_pv) 
# intercept: 44.2625, coefficient: 0.5426 p-value: 0.0009966
lm_black_demog <- lm(D_pv2p ~ Black, data = demog_pv) 
# intercept: 46.54419, coefficient: 0.04952 (t = 0.29) p-value: 0.7728
lm_hispanic_demog <- lm(D_pv2p ~ Hispanic, data = demog_pv) 
# intercept: 42.9130, coefficient: 0.3997 p-value: 0.01228
lm_white_demog <- lm(D_pv2p ~ White, data = demog_pv) 
# intercept: 71.12649, coefficient: -0.33253 p-value: 0.0006607
lm_female_demog <- lm(D_pv2p ~ Female, data = demog_pv) 
# intercept: -137.475 (tvalue = -1.727), coefficient: 3.623 p-value: 0.02469
lm_male_demog <- lm(D_pv2p ~ Male, data = demog_pv) 
# intercept 91.1 (t < 2), coefficient -1.8, p-value 0.055
lm_age20_demog <- lm(D_pv2p ~ age20, data = demog_pv) 
# intercept: 91.7202 coefficient: -1.7722 (tvalue = -1.97) p-value: 0.05507
lm_age3045_demog <- lm(D_pv2p ~ age3045, data = demog_pv) 
# neither t value close  p-value: 0.1049
lm_age4565_demog <- lm(D_pv2p ~ age4565, data = demog_pv)
# neither t value close
lm_age65_demog <- lm(D_pv2p ~ age65, data = demog_pv)
# t values not close enough 

## strongest predictors seem to be Asian, Hispanic, White, and 20-30 year old demographics. 

# see changes in pct of white people in states from 2016-2018
demog2 <- demog %>%
  filter(year == 2016 | year == 2018) %>%
  select(year, White, state) %>%
  pivot_wider(names_from = year, values_from = White) %>%
  mutate(white_chg = `2018` - `2016`)

ggplot(demog, aes(x = year, y = White, color = state)) + geom_line()

# use predict function to predict new values for each state based on 2018 white data 

# visualize turnout 
turnout %>%
  filter(state != "United States") %>%
  mutate(turn_pct = turnout/VEP) %>%
  ggplot(aes(x = year, y = turn_pct)) + geom_line() + 
  facet_wrap(~ state)

# change in turnout from 2012-2016
turnout_chg_16 <- turnout %>%
  filter(state != "United States") %>%
  filter(year == 2016 | year == 2012) %>%
  mutate(turn_pct = turnout/VEP) %>%
  select(year, state, turn_pct) %>%
  pivot_wider(names_from = year, values_from = turn_pct) %>%
  mutate(turn_16_chg = `2016` - `2012`) %>%
 #  pivot_longer(cols = c(`2016`, `2012`), names_to = "turnout_pct")
  left_join(demog) %>%
  select(year, state, turn_16_chg, White) %>%
  filter(year == 2016)

# pct of White people vs. change in 2016 turnout
ggplot(turnout_chg_16, aes(x = White, y = turn_16_chg, color = White)) + geom_point() + 
  geom_smooth(method = "lm")

# linear model for above 
lm_white_change <- lm(White ~ turn_16_chg, data = turnout_chg_16)

#### Try to make model like the state polling week 

election_years <- data.frame(year = seq(from=1948, to=2020, by=4))

demog3 <- demog %>%
  right_join(pvstate2) %>%
  # pivot_longer(cols = c(Hispanic, Black, White, Asian, Indigenous, Female, Male, 
  # age20, age3045, age4565, age65), 
  # names_to = "demographic", values_to = "demographic_pct") %>%
  filter(state != "District of Columbia") 

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
states_list <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming")

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

# linear model for local unemployment rate
statelocal_lm_rep <- function(s){
  ok <- local %>%
    filter(state == s)
  
  # use republican vote share, leanred in section republicans are hurt more by
  # high unemployment than democrats are
  lm(R_pv2p ~ local_unemploy, data = ok)
}


statedemog_lm <- function(s){
  ok <- demog3 %>%
    filter(state == s)
  
  lm(R_pv2p ~ White, data = ok)
}

predict_function <- function(s){
  s_lm_demog <- statedemog_lm(s)
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
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  # days_left <- 40
  # pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction <- 0.75*predict(s_lm_poll, Spoll) + 
    0.05*predict(s_lm_econ, Secon) + 0.2*predict(s_lm_demog, Sdemog)
}

for (s in states_list){
  state_prediction <- predict_function(s)
  states_predictions$predictions[states_predictions$state == s] <- state_prediction
}

pred <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

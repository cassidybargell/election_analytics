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

# most updated polls
poll_state_10_18 <- read_csv("data/presidential_poll_averages_2020 (2).csv") %>%
  filter(modeldate == "10/18/2020") %>%
  filter(candidate_name == "Donald Trump") %>%
  select(state, pct_trend_adjusted)

states_predictions <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA)

states_predictions2 <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA)

states_predictions3 <- read_csv("data/csvData.csv") %>%
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
  filter(year == 2016) %>%
  left_join(pvstate) 
  

# pct of White people vs. change in 2016 turnout
ggplot(turnout_chg_16, aes(x = White, y = turn_16_chg, color = R_pv2p)) + geom_point() + 
  geom_smooth(method = "lm")

ggplot(turnout_chg_16, aes(x = turn_16_chg, y = R_pv2p, color = White)) + geom_point() + 
  geom_smooth(method = "lm")

ggplot(turnout_chg_16, aes(x = White, y = R_pv2p, color = turn_16_chg)) + geom_point() + 
  geom_smooth(method = "lm") + theme_minimal() + 
  labs(title = "Percentage White Population vs. Republican Two-Party Vote Share",
       subtitle = "2016 Presidential Election",
       x = "Percentage White Population",
       y = "Republican Two-Party Vote Share",
       color = "% Change in Voter Turnout 
       Compared to 2012") 

ggsave("figures/10_18_white_vs_rep.png")

# linear model for above 
lm_white_change <- lm(White ~ R_pv2p, data = turnout_chg_16)

#### Try to make model like the state polling week 

election_years <- data.frame(year = seq(from=1948, to=2020, by=4))

# demographics join, remove District of Columbia
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

# Join poll state and popular vote by state, use weeks left = 3 because that is closest data we have
state_pv_poll_rep <- poll_state %>%
  filter(party == "republican") %>%
  filter(weeks_left <= 3) %>%
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
  
  # use republican vote share, learned in section republicans are hurt more by
  # high unemployment than democrats are
  lm(R_pv2p ~ local_unemploy, data = ok)
}

# linear model for White demographic and Republican vote share
statedemog_lm <- function(s){
  ok <- demog3 %>%
    filter(state == s)
  
  lm(R_pv2p ~ White, data = ok)
}

# create predict function that uses all three linear models and then a prediction for each state
# want to weight based off of R squared values but not fully sure how to yet 
predict_function <- function(s){
  s_lm_demog <- statedemog_lm(s)
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_state_10_18 %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  # days_left <- 40
  # pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction <- 0.85*predict(s_lm_poll, Spoll) + 
    0.05*predict(s_lm_econ, Secon) + 0.1*predict(s_lm_demog, Sdemog)
  
}

# loop through all states
for (s in states_list){
  state_prediction <- predict_function(s)
  states_predictions$predictions[states_predictions$state == s] <- state_prediction
  
}

# model electoral college votes based on vote share predictions 
# want to weight based off of R squared values but not fully sure how to yet 
pred <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

#### Prediction Visualization 

# much easier to interpret win margin in colors
state_viz <- states_predictions %>%
  mutate(D_pv2p = (100 - predictions)) %>%
  mutate(win_margin = (D_pv2p-predictions)) %>%
  mutate(rep_win = ifelse(win_margin <= 0, TRUE, FALSE))

# plot on map
plot_usmap(data = state_viz, regions = "states", values = "win_margin") + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red", 
    breaks = c(-60, -40, -20, 0, 20, 40), 
    limits = c(-61, 50),
    name = "Win Margin") + 
  labs(title = "Predicted Win Margin of Two-Party Popular Vote Share",
       subtitle = "Weighted ensemble modeled using 
       3-weeks out poll averages (0.85), white population (.1),
       and Q2 local unemployment (0.05)",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/10_18_weighted_ensemble.png")

# plot with state bins
ggplot(state_viz, aes(state = state, fill = rep_win)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Weighted ensemble modeled using 3-weeks out poll averages (0.85), 
       white population (.1), and Q2 local unemployment (0.05)",
       fill = "") + 
  guides(fill=FALSE)

ggsave("figures/10_18_weighted_ensemble_statebins.png")

#### Sensitivity analysis, mostly polling data

predict_function2 <- function(s){
  s_lm_demog <- statedemog_lm(s)
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_state_10_18 %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  state_prediction2 <- 0.9*predict(s_lm_poll, Spoll) + 
    0*predict(s_lm_econ, Secon) + 0.1*predict(s_lm_demog, Sdemog)
  
}

# loop through all states
for (s in states_list){
  state_prediction2 <- predict_function2(s)
  states_predictions2$predictions[states_predictions2$state == s] <- state_prediction2
}

pred2 <- states_predictions2 %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

# much easier to interpret win margin in colors
state_viz2 <- states_predictions2 %>%
  mutate(D_pv2p = (100 - predictions)) %>%
  mutate(win_margin = (D_pv2p-predictions)) %>%
  mutate(rep_win = ifelse(win_margin <= 0, TRUE, FALSE))

# only change is florida flips republican
ggplot(state_viz2, aes(state = state, fill = rep_win)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Modelled using historical polling accuracy 3-weeks out from 
       election day (.85) and white population proportion (0.15)",
       fill = "") + 
  guides(fill=FALSE)

plot_usmap(data = state_viz2, regions = "states", values = "win_margin") + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red", 
    breaks = c(-60, -40, -20, 0, 20, 40), 
    limits = c(-61, 50),
    name = "Win Margin") + 
  labs(title = "Predicted Win Margin of Two-Party Popular Vote Share",
       subtitle = "Weighted ensemble using historical polling accuracy 3-weeks out from 
       election day (0.9) and white population proportion (0.1)",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/10_18_polling_statebins.png")

#### Sensitivity analysis, mostly demographic data

predict_function3 <- function(s){
  s_lm_demog <- statedemog_lm(s)
  s_lm_poll <- statepoll_lm_rep(s)
  s_lm_econ <- statelocal_lm_rep(s)
  
  Secon <- local %>%
    filter(state == s) %>%
    filter(year == 2020) %>%
    select(local_unemploy)
  
  Spoll <- poll_state_10_18 %>%
    filter(state == s) %>%
    rename(avg_pollyr = "pct_trend_adjusted")
  
  Sdemog <- demog %>%
    filter(state == s) %>%
    filter(year == 2018) %>%
    select(state, year, White)
  
  # days_left <- 40
  # pwt <- 1/sqrt(days_left); ewt <- 1-(1/sqrt(days_left))
  state_prediction3 <- 0.1*predict(s_lm_poll, Spoll) + 
    0*predict(s_lm_econ, Secon) + 0.9*predict(s_lm_demog, Sdemog)
  
}

# loop through all states
for (s in states_list){
  state_prediction3 <- predict_function3(s)
  states_predictions3$predictions[states_predictions3$state == s] <- state_prediction3
}

pred3 <- states_predictions3 %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win))

# much easier to interpret win margin in colors
state_viz3 <- states_predictions3 %>%
  mutate(D_pv2p = (100 - predictions)) %>%
  mutate(win_margin = (D_pv2p-predictions)) %>%
  mutate(rep_win = ifelse(win_margin <= 0, TRUE, FALSE))

# only change is florida flips republican
ggplot(state_viz3, aes(state = state, fill = rep_win)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Modelled using historical polling accuracy 3-weeks out from 
       election day (.15) and white population proportion (0.85)",
       fill = "") + 
  guides(fill=FALSE)

plot_usmap(data = state_viz3, regions = "states", values = "win_margin") + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red", 
    breaks = c(-60, -40, -20, 0, 20, 40), 
    limits = c(-61, 50),
    name = "Win Margin") + 
  labs(title = "Predicted Win Margin of Two-Party Popular Vote Share",
       subtitle = "Weighted ensemble using historical polling accuracy 3-weeks out from 
       election day (0.1) and white population proportion (0.9)",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/10_18_demographic_statebins.png")

#### Compare pred2 and pred3 (sensitivity analysis)

# find differences in popular vote outcome. 
pred4 <- pred3 %>%
  rename(predictions1 = "predictions") %>%
  full_join(pred2) %>%
  select(state, predictions1, predictions) %>%
  mutate(diff = (predictions1 - predictions))



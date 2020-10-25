## Week Seven - Shocks
## 10/26/20

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

states_list <- c("Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri", "Montana", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York", "North Carolina", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "South Carolina", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "Wisconsin")


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
county_covid <- read_csv("data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv") %>%
  rename(fips = "FIPS County Code") %>%
  rename(state = "State") %>%
  rename(deaths = "Deaths involving COVID-19") %>%
  rename(county = "County name")
poll_state_10_18 <- read_csv("data/presidential_poll_averages_2020 (2).csv") %>%
  filter(modeldate == "10/18/2020") %>%
  rename(State = state) %>%
  left_join(states)
pv_county <- read_csv("data/popvote_bycounty_2000-2016.csv")
state_covid <- read_csv("data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv") %>%
  mutate(date = as.Date(submission_date, "%m/%d/%y"))
census_data <- read_csv("data/nst-est2019-alldata.csv") %>%
  rename(State = "NAME") %>%
  rename(pop_2019 = "POPESTIMATE2019") %>%
  select(State, pop_2019) %>%
  left_join(states)
day7_covid_rates <- read_csv("data/7day-united_states_covid19_cases_and_deaths_by_state.csv") %>%
  rename(rate = "Death Rate per 100K in Last 7 Days") %>%
  rename(state = "State/Territory")
all_time_covid_rates <- read_csv("data/united_states_covid19_cases_and_deaths_by_state (1).csv")

county_covid$county = as.character(gsub("County", "", county_covid$county))

my_line_theme <- theme_bw() + 
  theme(panel.border = element_blank(),
    plot.title   = element_text(size = 15, hjust = 0.5), 
    axis.text.x  = element_text(angle = 45, hjust = 1),
    axis.text    = element_text(size = 12),
    strip.text   = element_text(size = 18),
    axis.line    = element_line(colour = "black"),
    legend.position = "top",
    legend.text = element_text(size = 12))


#### Descriptive Statistic 
## Breakout room

# Just plot county level data
plot_usmap(data = county_covid, regions = "county", values = "deaths") + 
  theme_void()

# county_covid_pv <- county_covid %>%
  # select(state, fips, deaths) %>%
  # full_join(pv_county) %>%
           #   select(D_win_margin, fips, state))

#### States Polls vs. COVID Deaths

# Combine polling averages from 2020, total population, and total covid deaths
polls_2020 <- poll_2020 %>%
  filter(candidate_name == "Donald Trump") %>%
  group_by(state, date) %>%
  mutate(avg_poll = mean(pct)) %>%
  filter(! is.na(state)) %>%
  rename(State = state) %>%
  left_join(states) %>%
  rename(no = State) %>%
  select(state, date, avg_poll) %>%
  right_join(state_covid) %>%
  select(avg_poll, state, tot_death, date) %>%
  filter(! is.na(avg_poll)) %>%
  left_join(census_data) %>%
  mutate(percap = (tot_death/pop_2019))

# for data without covid deaths equal to 0
polls_2020_no0 <- polls_2020 %>%
  filter(tot_death != 0)

# plot deaths vs. avg polling 
ggplot(polls_2020, aes(x = tot_death, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme

# plot deaths per capita vs. avg polling
ggplot(polls_2020, aes(x = percap, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme

# repeat plot deaths vs. avg polling after at least one death had occured in the state
ggplot(polls_2020_no0, aes(x = tot_death, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme

# repeat plot deaths per capita vs. avg polling after at least one death had
# occured in the state
ggplot(polls_2020_no0, aes(x = percap, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme

# these plots make good sense knowing the more urban places are usually more
# democratic and have more deaths

#### Use most recent polls and covid deaths to plot a map

pv_state <- pvstate %>%
  filter(year == 2016) %>%
  mutate(winner = ifelse(D_pv2p > R_pv2p, "Democrat", "Republican")) %>%
  rename(State = state)

most_recent_covid <- state_covid %>%
  filter(date == "2020-10-18") %>%
  select(date, tot_death, state) %>%
  left_join(census_data) %>%
  mutate(percap = (tot_death/pop_2019)) %>%
  right_join(poll_state_10_18) %>%
  filter(candidate_name == "Donald Trump") %>%
  filter(! is.na(tot_death)) %>%
  left_join(pv_state) %>%
  mutate(per100000 = (percap * 100000))

# plot most recent covid deaths data and most recent poll aggregate

ggplot(most_recent_covid, aes(x = per100000, y = pct_estimate, label = state)) + 
  geom_text(size = 1.8, aes(color = winner)) + geom_smooth(method = "lm") + my_line_theme + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democrat win", "Republican win")) +
  labs(x = "Total COVID Deaths Per 100,000 as of 10-20-2020",
       y = "Poll Averages on 10-18-2020", 
       legend = "2016 two-party popular vote win", 
       title = "COVID Deaths Per 100,000 vs. Poll Averages")

# stratify based on party (2016 popular vote winner)

rep_recent_covid <- most_recent_covid %>%
  filter(winner == "Republican")

ggplot(rep_recent_covid, aes(x = percap, y = pct_estimate, label = state)) + 
  geom_text(size = 1.8, aes(color = winner)) + geom_smooth(method = "lm") + my_line_theme + 
  scale_color_manual(values = c("red", "blue"), name = "", 
                     labels = c("", "")) +
  labs(x = "Total COVID Deaths Per Capita as of 10-20-2020",
       y = "Poll Averages on 10-18-2020", 
       legend = "2016 two-party popular vote win", 
       title = "COVID Deaths Per Capita vs. Poll Averages")
  
dem_recent_covid <- most_recent_covid %>%
  filter(winner == "Democrat")

ggplot(dem_recent_covid, aes(x = percap, y = pct_estimate, label = state)) + 
  geom_text(size = 1.8, aes(color = winner)) + geom_smooth(method = "lm") + my_line_theme + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("", "")) +
  labs(x = "Total COVID Deaths Per Capita as of 10-20-2020",
       y = "Poll Averages on 10-18-2020", 
       legend = "2016 two-party popular vote win", 
       title = "COVID Deaths Per Capita vs. Poll Averages")

# run linear model while controlling for 2016 winner, don't really know what to
# do with this
lm1 <- lm(pct_estimate ~ per100000 * winner, data = most_recent_covid)
glm1 <- glm(pct_estimate ~ per100000 * winner, data = most_recent_covid)


#### Plot most recent approval averages vs. covid deaths maybe 
# want to make a bubble map of the U.S. 

# US <- map_data("world") %>% filter(region=="US")
# cities <- world.cities %>% filter(country.etc=="USA")

#### Try to make state level predictions based on COVID rates

# polls to join with 
p2020 <- poll_2020 %>%
  filter(candidate_name == "Donald Trump") %>%
  group_by(state, date) %>%
  mutate(avg_poll = mean(pct)) %>%
  filter(! is.na(state)) %>%
  rename(State = state) %>%
  select(State, avg_poll, date)

# place to store predictions
states_predictions <- read_csv("data/csvData.csv") %>%
  rename(state = "State") %>%
  select(state) %>%
  mutate(predictions = NA)

# use Colorado first
co <- state_covid %>%
  left_join(states) %>%
  filter(State == "Colorado") %>%
  arrange(desc(date)) %>%
  mutate(rate = ((tot_death - lead(tot_death, n = 7))/ lead(tot_death, n = 7))) %>%
  filter(! is.na(rate)) %>%
  filter(! grepl('Inf', rate)) %>%
  left_join(p2020) %>%
  filter(! is.na(avg_poll))

lm_co <- lm(avg_poll ~ rate, data = co)

ggplot(co, aes(x = rate, y = avg_poll)) + geom_point() + geom_smooth(method = "lm")


SCO <- day7_covid_rates %>%
  filter(state == "Colorado")

coPred <- predict(lm_co, SCO)

# Something going wrong with D.C. 

dc <- state_covid %>%
  left_join(states) %>%
  filter(State == "District of Columbia") %>%
  arrange(desc(date)) %>%
  mutate(rate = ((tot_death - lead(tot_death, n = 7))/ lead(tot_death, n = 7))) %>%
  filter(! is.na(rate)) %>%
  filter(! grepl('Inf', rate)) %>%
  left_join(p2020) %>%
  filter(! is.na(avg_poll))

lm_co <- lm(avg_poll ~ rate, data = co)

ggplot(co, aes(x = rate, y = avg_poll)) + geom_point() + geom_smooth(method = "lm")


SCO <- day7_covid_rates %>%
  filter(state == "Colorado")

coPred <- predict(lm_co, SCO)

# Make function
statecovid_lm <- function(s){

  ok <- state_covid %>%
    left_join(states) %>%
    filter(State == s) %>%
    arrange(desc(date)) %>%
    mutate(rate = ((tot_death - lead(tot_death, n = 7))/ lead(tot_death, n = 7))) %>%
    filter(! is.na(rate)) %>%
    filter(! grepl('Inf', rate)) %>%
    left_join(p2020) %>%
    filter(! is.na(avg_poll))
  
  lm(avg_poll ~ rate, data = ok)
}

# Make predict function with most recent 7 day covid death rates 
predict_function <- function(s){
  s_lm_covid <- statecovid_lm(s)
  
  Scovid <- day7_covid_rates %>%
    filter(state == s)

  state_prediction <- predict(s_lm_covid, Scovid)
}

# loop through all the states
for (s in states_list){
  state_prediction <- predict_function(s)
  states_predictions$predictions[states_predictions$state == s] <- state_prediction
  
}



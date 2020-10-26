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
    plot.subtitle = element_text(size = 12, hjust = 0.5),
    axis.text.x  = element_text(angle = 45, hjust = 1),
    axis.text    = element_text(size = 12),
    strip.text   = element_text(size = 18),
    axis.line    = element_line(colour = "black"),
    legend.position = "right",
    legend.text = element_text(size = 12))

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

lm_percap <- lm(avg_poll ~ percap, data = polls_2020)

# repeat plot deaths vs. avg polling after at least one death had occured in the state
ggplot(polls_2020_no0, aes(x = tot_death, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme

# repeat plot deaths per capita vs. avg polling after at least one death had
# occured in the state
ggplot(polls_2020_no0, aes(x = percap, y = avg_poll, color = date)) + geom_point() + 
  geom_smooth(method = "lm") + my_line_theme + 
  labs(title = "Per Capita Deaths vs. Aggregate Poll Averages",
       subtitle = "Poll Support for Republican Candidate",
       color = "",
       x = "Per Capita Deaths by State",
       y = "State Poll Aggregate") 

ggsave("figures/10-26-20_pollvpercap.png")

lm_percap_no0 <- lm(avg_poll ~ percap, data = polls_2020_no0)

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
       title = "COVID Deaths Per 100,000 vs. Poll Averages", 
       subtitle = "Colored by popular vote winner in 2016") + 
  theme(legend.position = "none")

ggsave("figures/10-26-2020_recent_regression.png")

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
lm1 <- lm(pct_estimate ~ per100000 * winner, data = most_recent_covid)


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
  mutate(predictions = NA) %>%
  mutate(lwr = NA) %>%
  mutate(uppr = NA) %>%
  mutate(rsq = NA) 

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

# Look at state that produces an extreme prediction (Louisiana) 

la <- state_covid %>%
  left_join(states) %>%
  filter(State == "Louisiana") %>%
  arrange(desc(date)) %>%
  mutate(rate = ((tot_death - lead(tot_death, n = 7))/ lead(tot_death, n = 7))) %>%
  filter(! is.na(rate)) %>%
  filter(! grepl('Inf', rate)) %>%
  left_join(p2020) %>%
  filter(! is.na(avg_poll))

lm_la <- lm(avg_poll ~ rate, data = la)

ggplot(la, aes(x = rate, y = avg_poll)) + geom_point() + geom_smooth(method = "lm")


SLA <- day7_covid_rates %>%
  filter(state == "Louisiana")

laPred <- predict(lm_la, SLA)

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

# join electoral college
pred <- states_predictions %>%
  left_join(electoral_college) %>%
  filter(! is.na(predictions)) %>%
  mutate(dem_win = ifelse(predictions < 50, votes, 0)) %>%
  mutate(rep_win = ifelse(predictions >50, votes, 0)) %>%
  mutate(rep_ec = sum(rep_win)) %>%
  mutate(dem_ec = sum(dem_win)) %>%
  mutate(d_pred = (100 - predictions)) %>%
  mutate(win_margin = (d_pred - predictions)) %>%
  mutate(winner = ifelse(d_pred > 50, "Democrat", "Republican"))

# visualize this
ggplot(pred, aes(state = state, fill = win_margin)) + 
  geom_statebins() + 
  theme_statebins() +
  scale_fill_gradient2(
    high = "blue",
    mid = "white",
    low = "red",
    name = "Win Margin") + 
  # scale_gradient_manual(values=c("#619CFF", "#F8766D")) +
  labs(title = "2020 Presidential Election Prediction Map",
       subtitle = "Modelled Using Relationship Between State Polling Averages
       and 7-day COVID-19 Case Rate",
       fill = "Projected Democrat Win Margin")

ggsave("figures/10-26-20_prediction_map.png")

#### Add confidence intervals and rsq

CIcovid_function <- function(s){
  
  s_lm_covid <- statecovid_lm(s)
  
  Scovid <- day7_covid_rates %>%
    filter(state == s)
  
  covid_CI <- predict(s_lm_covid, Scovid, interval = "prediction", level = 0.95)
}



# Loop through again
for (s in states_list){
  CIcovid_prediction <- CIcovid_function(s)
  
  states_predictions$lwr[states_predictions$state == s] <- CIcovid_prediction[, 2]
  states_predictions$uppr[states_predictions$state == s] <- CIcovid_prediction[, 3]
}

# Add rsquared values to the table 
covidrsq_lm <- function(s){
  
  ok <- state_covid %>%
    left_join(states) %>%
    filter(State == s) %>%
    arrange(desc(date)) %>%
    mutate(rate = ((tot_death - lead(tot_death, n = 7))/ lead(tot_death, n = 7))) %>%
    filter(! is.na(rate)) %>%
    filter(! grepl('Inf', rate)) %>%
    left_join(p2020) %>%
    filter(! is.na(avg_poll))
  
  s <- lm(avg_poll ~ rate, data = ok)
  rs <- (summary(s)$r.squared)
}

# loop through all states and save to states list - polls
for (s in states_list){
  covidrsq <- covidrsq_lm(s)
  states_predictions$rsq[states_predictions$state == s] <- covidrsq
}

#### Try to visualize ranges
ggplot(states_predictions, aes(x = predictions, y = state, color = predictions)) + 
  geom_point() + 
  geom_errorbar(aes(xmin = lwr, xmax = uppr)) +
  scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "",
       subtitle = "",
       caption = "")

# Filter out states with ridiculous margins
states_predictions2 <- states_predictions %>%
  filter(state != "Louisiana")

ggplot(states_predictions2, aes(x = predictions, y = state, color = predictions)) + 
  geom_point() + 
  geom_errorbar(aes(xmin = lwr, xmax = uppr)) +
  scale_color_gradient(low = "blue", high = "red") + 
  theme_minimal() + 
  theme(axis.text.y = element_text(size = 7),
        legend.position = "none") + 
  ylab("") + 
  xlab("Republican Vote Share %") + 
  geom_vline(xintercept = 50, lty = 2) +
  labs(title = "Range of Predicted Republican Popular Vote Share %",
       subtitle = "Modelled using Relationship Between State Polling Averages
       and 7-day COVID-19 Case Rate",
       caption = "LA ommitted - range went above 100%")

ggsave("figures/10-26-20_prediction_ranges.png")

#### COVID Rates spiking? 

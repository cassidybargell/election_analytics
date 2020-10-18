## Week Six - Ground Game
## 10/19/20

# create model that predicts voteshare based on demographics of a state 
# predict 2020 demographics based on demographics through 2020? 
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






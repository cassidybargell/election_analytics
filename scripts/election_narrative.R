## Election Narrative
## 12/10/20

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
library(haven)
library(tidycensus)

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

#### Read in Data
my_predictions <- readRDS("data/post-election/my_predictions.RDS")
poll_avg_1948_2020 <- read_csv("data/post-election/pollavg_1948-2020.csv")
pop_vote_actual <- read_csv("data/post-election/popvote_bystate_1948-2020.csv")
polls_10_29 <- read_csv("data/10_29_presidential_poll_averages_2020.csv")
nationscape <- read_dta("data/post-election/nationscape.dta")
states <- read_csv("data/csvData.csv") %>%
  rename(state = "Code")
state_covid <- read_csv("data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv") %>%
  mutate(date = as.Date(submission_date, "%m/%d/%y"))
day7_covid_rates <- read_csv("data/new-united_states_covid19_cases_and_deaths_by_state.csv") %>%
  rename(rate = "Death Rate per 100K in Last 7 Days") %>%
  rename(state = "State/Territory")
all_time_covid_rates <- read_csv("data/united_states_covid19_cases_and_deaths_by_state (1).csv")
county_covid <- read_csv("data/Provisional_COVID-19_Death_Counts_in_the_United_States_by_County.csv") %>%
  rename(fips = "FIPS County Code") %>%
  rename(state = "State") %>%
  rename(deaths = "Deaths involving COVID-19") %>%
  rename(county = "County name")
pop_vote_county_2020 <- read_csv("data/post-election/popvote_bycounty_2020.csv")
pop_vote_county_historical <- read_csv("data/post-election/popvote_bycounty_2000-2016.csv")
x <- data("fips_codes")

# Explore Latino Voting Block with Nationscape data

# two by two table, is the proportion of Latinos voting for Trump different than
# from non-latinos according to nationscape survey
test_dat <- nationscape %>%
  select(extra_race_latino_you, vote_2020_lean) %>%
  filter(vote_2020_lean != 888) %>%
  count(extra_race_latino_you, vote_2020_lean) %>%
  pivot_wider(names_from = extra_race_latino_you, values_from = n) %>%
  rename(yes_latino = "1") %>%
  rename(no_latino = "2") %>%
  mutate(vote_2020_lean = ifelse(vote_2020_lean == 1, "Trump", "Biden"))

t <- as.table(rbind(c(42,102), c(306, 519)))

# expect them not to be different if the Lation block as a whole votes in a
# certain way differently compared to the rest of the nation
test <- fisher.test(t)

# fail to reject the null, cannot conclude the two proportions are different

# vizualize this, not that useful
latino_you <- nationscape %>% filter(extra_race_latino_you == 1)
not_latino_you <- nationscape %>% filter(extra_race_latino_you == 2) 
ggplot(latino_you, aes(x = vote_2020_lean)) + geom_histogram()
ggplot(not_latino_you, aes(x = vote_2020_lean)) + geom_histogram()

#### Explore idea that coronavirus had an impact on the election

# pull corona, vote and ideology variables
# vote_2020: 1 = Trump, 2 = Biden
corona <- nationscape %>%
  select(extra_corona_concern, extra_sick_you, extra_sick_family, 
         extra_sick_other, extra_sick_work, extra_trump_corona,
         vote_2020_lean, pid3, pid7, ideo5, state, vote_2020)

# visualize party identification vs. coronavirus concern
# pid3: 1 = Dem, 2 = Rep
corona %>%
  filter(pid3 == 1 | pid3 == 2) %>% 
  ggplot(aes(x = extra_corona_concern,  y = pid3)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# independent identification vs coronavirus concern 
corona %>%
  filter(pid3 == 3) %>%
  ggplot(aes(x = extra_corona_concern, y = pid3)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# visualize vote_2020 answer vs. coronavirus concern
corona %>%
  filter(vote_2020 != 999) %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  ggplot(aes(x = extra_corona_concern,  y = vote_2020)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# visualize Trump coronavirus handling and coronavirus concern
corona %>%
  filter(extra_trump_corona != 999) %>% 
  ggplot(aes(x = extra_corona_concern, y = extra_trump_corona)) + geom_jitter(alpha = 0.5) + 
  geom_smooth(method = "glm")

# fewest somewhat disapprove, signal of partisanship? 
corona %>%
  filter(extra_trump_corona != 999) %>% 
  ggplot(aes(x = extra_trump_corona)) + geom_histogram()

## Visualize based on states for the Nationscape survey 

# make a proportion using average coronavirus concern for each state
corona_concern_prop <- corona %>%
  group_by(state) %>%
  filter(! is.na(extra_corona_concern)) %>%
  summarize(extra_corona_concern_prop = mean(extra_corona_concern)) %>%
  left_join(states)

# plot states with coronavirus concern
ggplot(corona_concern_prop, aes(state = state, fill = extra_corona_concern_prop)) + 
  geom_statebins() + 
  theme_statebins()

# How well does partisanship and voting for Trump align?
corona %>%
  filter(pid3 == 1 | pid3 == 2) %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  ggplot(aes(pid3, vote_2020)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

corona %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  ggplot(aes(pid7, vote_2020)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# coronavirus death rates vs. county popular vote outcomes 

all_corona_vote <- county_covid %>%
  left_join(pop_vote_county_2020)
  
  
  
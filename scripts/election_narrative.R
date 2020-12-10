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
library(readxl)

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
# all covid data as of 10/21/20
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
pop_vote_county_2020 <- read_csv("data/post-election/popvote_bycounty_2020.csv") %>%
  rename(fips = "FIPS") %>%
  filter(! is.na(fips)) %>%
  filter(fips != "fips") %>%
  mutate(fips = as.double(fips))
pop_vote_county_historical <- read_csv("data/post-election/popvote_bycounty_2000-2016.csv")
fips <- read_csv("data/post-election/ZIP-COUNTY-FIPS_2018-03.csv")
census_data <- read_csv("data/nst-est2019-alldata.csv") %>%
  rename(State = "NAME") %>%
  rename(pop_2019 = "POPESTIMATE2019") %>%
  select(State, pop_2019) %>%
  left_join(states)
county_pop <- read_xls("data/post-election/PopulationEstimates.xls") %>%
  rename(state = "...2") %>%
  rename(county = "...3") %>%
  rename(pop = "...20") %>%
  select(county, pop, state)

#### Explore Latino Voting Block with Nationscape data

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
         vote_2020_lean, pid3, pid7, ideo5, state, vote_2020, vote_2016)

# visualize party identification vs. coronavirus concern
# pid3: 1 = Dem, 2 = Rep
corona %>%
  filter(pid3 == 1 | pid3 == 2) %>% 
  mutate(pid3 = ifelse(pid3 == 1, "Democrat", "Republican")) %>%
  mutate(extra_corona_concern = ifelse(extra_corona_concern == 1, "Very Concerned", 
                                       ifelse(extra_corona_concern == 2, "Somewhat Concerned", 
                                       ifelse(extra_corona_concern == 3, "Not Very Concerned", "Not At All Concerned")))) %>%
  filter(! is.na(extra_corona_concern)) %>%
  ggplot(aes(x = extra_corona_concern,  y = pid3)) + geom_jitter(alpha = 0.5) + 
  # geom_smooth(method = "lm") +
  theme_minimal() + 
  labs(title = "Partisanship vs. Concern About COVID-19",
       subtitle = "June Nationscape Survey",
       y = "Self Identified Partisanship",
       x = "Concern",
       caption = "'How concerned are you about coronavirus here in the United States?'")

ggsave("figures/narrative/partisan_concern.png")

# independent identification vs coronavirus concern 
corona %>%
  filter(pid3 == 3) %>%
  ggplot(aes(x = extra_corona_concern, y = pid3)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# visualize vote_2020 answer vs. coronavirus concern
corona %>%
  filter(vote_2020 != 999) %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  mutate(extra_corona_concern = ifelse(extra_corona_concern == 1, "Very Concerned", 
                                       ifelse(extra_corona_concern == 2, "Somewhat Concerned", 
                                              ifelse(extra_corona_concern == 3, "Not Very Concerned", "Not At All Concerned")))) %>%
  mutate(vote_2020 = ifelse(vote_2020 == 1, "Donald Trump", "Biden")) %>%
  filter(! is.na(extra_corona_concern)) %>%
  ggplot(aes(x = extra_corona_concern,  y = vote_2020)) + geom_jitter(alpha = 0.5) +
  theme_minimal() + 
  labs(title = "Anticipated Vote vs. Concern About COVID-19",
       subtitle = "June Nationscape Survey",
       y = "'If the election for president were going to be held now...
        who would you vote for?'",
       x = "Concern",
       caption = "'How concerned are you about coronavirus here in the United States?'")

ggsave("figures/narrative/vote-2020_concern.png")

# switchers between 2016 and 2020 concern about coronavirus 

switchers <- corona %>%
  filter(vote_2016 == 1) %>%
  mutate(switcher = ifelse(vote_2016 == 1 & vote_2020 == 2, T, F)) %>%
  filter(vote_2020 != 999) %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  mutate(extra_corona_concern = ifelse(extra_corona_concern == 1, "Very Concerned", 
                                 ifelse(extra_corona_concern == 2, "Somewhat Concerned", 
                                 ifelse(extra_corona_concern == 3, "Not Very Concerned", "Not At All Concerned")))) %>%
  mutate(vote_2020 = ifelse(vote_2020 == 1, "Donald Trump", "Biden")) %>%
  filter(! is.na(extra_corona_concern))

ggplot(switchers, aes(x = extra_corona_concern, y = switcher)) + 
  geom_jitter(alpha = 0.5) + 
  theme_minimal() + 
  labs(title = "Voters for Trump in 2016 and Biden in 2020",
       subtitle = "Coronavirus Concern",
       caption = "'How concerned are you about coronavirus here in the United States?'",
       y = "Voted for Trump in 2016 and Biden in 2020",
       x = "Indicated COVID-19 Concern")

ggsave("figures/narrative/switchers.png")

# switchers approval of coronavirus handling
switchers2 <- switchers %>%
  filter(extra_trump_corona != 999) %>%
  mutate(extra_trump_corona = ifelse(extra_trump_corona == 1, "Strongly Approve", 
                                       ifelse(extra_trump_corona == 2, "Somewhat Approve", 
                                              ifelse(extra_trump_corona== 3, "Somewhat Disapprove", "Strongly Disapprove"))))

switchers2$extra_trump_corona <- factor(switchers2$extra_trump_corona,levels = c("Strongly Approve", "Somewhat Approve", "Somewhat Disapprove", "Strongly Disapprove"))

  ggplot(switchers2, aes(x = extra_trump_corona, y = switcher)) + 
  geom_jitter(alpha = 0.5) + 
  theme_minimal() + 
  labs(title = "Voters for Trump in 2016 and Biden in 2020",
       subtitle = "Coronavirus Handling Approval",
       caption = "'Do you approve or disapprove of Donald Trump’s 
       handling of the coronavirus outbreak?'",
       y = "Voted for Trump in 2016 and Biden in 2020",
       x = "Indicated COVID-19 Handling Approval")
  
  ggsave("figures/narrative/switcher_approve.png")

# visualize Trump coronavirus handling and coronavirus concern
dem_concern <- corona %>%
  filter(extra_trump_corona != 999) %>% 
  filter(vote_2020 == 2) %>%
  mutate(extra_corona_concern = ifelse(extra_corona_concern == 1, "Very Concerned", 
                                       ifelse(extra_corona_concern == 2, "Somewhat Concerned", 
                                              ifelse(extra_corona_concern == 3, "Not Very Concerned", "Not At All Concerned")))) %>%
  mutate(extra_trump_corona = ifelse(extra_trump_corona == 1, "Strongly Approve", 
                                     ifelse(extra_trump_corona == 2, "Somewhat Approve", 
                                            ifelse(extra_trump_corona== 3, "Somewhat Disapprove", "Strongly Disapprove")))) %>%
  filter(! is.na(extra_corona_concern))

dem_concern$extra_trump_corona <- factor(dem_concern$extra_trump_corona,levels = c("Strongly Approve", "Somewhat Approve", "Somewhat Disapprove", "Strongly Disapprove"))

  ggplot(dem_concern, aes(x = extra_corona_concern, y = extra_trump_corona)) + geom_jitter(alpha = 0.5) +
    theme_minimal() + 
    labs(title = "Biden Voters COVID-19 Concern & Approval",
         subtitle = "Among individuals who reported they would vote for Biden.",
         caption = "June Nationscape Survey",
         y = "'Do you approve or disapprove of Donald Trump’s 
         handling of the coronavirus outbreak?'",
         x = "'How concerned are you about coronavirus here in the United States?'")
  
  ggsave("figures/narrative/dem_approval.png")

# Do same visualization for people who indicated they would vote for Trump in 2020
rep_approval_concern <- corona %>%
  filter(extra_trump_corona != 999) %>% 
  filter(vote_2020 == 1) %>%
  filter(! is.na(extra_corona_concern)) %>%
  mutate(extra_corona_concern = ifelse(extra_corona_concern == 1, "Very Concerned", 
                                       ifelse(extra_corona_concern == 2, "Somewhat Concerned", 
                                              ifelse(extra_corona_concern == 3, "Not Very Concerned", "Not At All Concerned")))) %>%
  mutate(extra_trump_corona = ifelse(extra_trump_corona == 1, "Strongly Approve", 
                                       ifelse(extra_trump_corona == 2, "Somewhat Approve", 
                                              ifelse(extra_trump_corona == 3, "Somewhat Disapprove", "Strongly Disapprove"))))

rep_approval_concern$extra_trump_corona <- factor(rep_approval_concern$extra_trump_corona,levels = c("Strongly Approve", "Somewhat Approve", "Somewhat Disapprove", "Strongly Disapprove"))
  
  ggplot(rep_approval_concern, aes(x = extra_corona_concern, y = extra_trump_corona)) + geom_jitter(alpha = 0.5) +
    theme_minimal() + 
    labs(title = "Trump Voters COVID-19 Concern & Approval",
         subtitle = "Among individuals who reported they would vote for Trump.",
         caption = "June Nationscape Survey",
         y = "'Do you approve or disapprove of Donald Trump’s 
         handling of the coronavirus outbreak?'",
         x = "'How concerned are you about coronavirus here in the United States?'")
  
ggsave("figures/narrative/concern_approval.png")

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

# How well does partisanship and voting for Trump align? very well.
corona %>%
  filter(pid3 == 1 | pid3 == 2) %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  ggplot(aes(pid3, vote_2020)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

corona %>%
  filter(vote_2020 == 1 | vote_2020 == 2) %>%
  ggplot(aes(pid7, vote_2020)) + geom_jitter(alpha = 0.5) + geom_smooth(method = "glm")

# coronavirus death rates vs. county popular vote outcomes 

# join corona county deaths with popular vote
all_corona_vote <- county_covid %>%
  left_join(pop_vote_county_2020) %>%
  rename(trump = "Donald J. Trump") %>%
  rename(total = "Total Vote") %>%
  mutate(trump = as.double(trump)) %>%
  mutate(total = as.double(total)) %>%
  mutate(trump_pct = ((trump / total) * 100)) %>%
  left_join(county_pop) %>%
  filter(! is.na(pop)) %>%
  mutate(pop = as.double(pop)) %>%
  mutate(per_cap = (deaths / pop)) 

# visualize if there is any relationship between COVID deaths and vote share
all_corona_vote %>%
  mutate(log_deaths = log(deaths)) %>%
  ggplot(aes(x = log_deaths, y = trump_pct)) + geom_point(alpha = 0.5) + geom_smooth(method = "glm")
  
all_corona_vote %>%
  mutate(log_percap = log(per_cap)) %>%
  ggplot(aes(x = log_percap, y = trump_pct)) + geom_point(alpha = 0.5) + geom_smooth(method = "glm")

#### Compare to historical trends

# create tibble with current and historical vote shares as well as COVID deaths
all_county <- all_corona_vote %>%
  mutate(year = 2020) %>%
  rename(state_abb = "state") %>%
  rename(biden = "Joseph R. Biden Jr.") %>%
  mutate(biden = as.double(biden)) %>%
  mutate(biden_pct = ((biden / total) * 100)) %>%
  mutate(D_win_margin = (biden_pct - trump_pct)) %>%
  select(year, state_abb, fips, D_win_margin, per_cap, deaths, trump_pct) %>%
  full_join(pop_vote_county_historical) %>%
  select(! state & ! county)

# created column for change in democratic vote share, negative value in
# change_in_D indicates Trump performed better than 2016
all_county2 <- all_county %>%
  group_by(fips) %>%
  arrange(desc(year)) %>%
  mutate(change_in_D = (D_win_margin - lead(D_win_margin, n = 1))) %>%
  filter(year == 2020) %>%
  mutate(log_percap = log(per_cap)) %>%
  mutate(log_deaths = log(deaths)) %>%
  mutate(trump_win = ifelse(D_win_margin >= 0, F, T))

# test with county to make sure it's working the way I want it to 
baldwin <-  all_county %>%
  filter(fips == 1003) %>%
  group_by(fips) %>%
  arrange(desc(year)) %>%
  mutate(change_in_D = (D_win_margin - lead(D_win_margin, n = 1))) %>%
  distinct()

# Plot log deaths and log_percapita death rate vs. change in democratic vote
# share from 2016 to 2020

# Starr county, Maverick County, Webb County, Hidalgo County, Miami Dade

# model change in Democratic win margin vs. log deaths or log deaths per capita
ggplot(all_county2, aes(x = log_percap, y = change_in_D, alpha = 0.1)) + 
  geom_point(aes(color = trump_win)) + 
  geom_smooth(method = "glm") + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("", "")) + 
  theme_minimal() + 
  labs(title = "County COVID-19 Per Capita Deaths vs. Change in Democratic Win Margin", 
       subtitle = "Change in Democratic Win Margin from 2016-2020 in 1,172 U.S. Counties", 
       x = "Log Per Capita Deaths - 10/21/20",
       y = "Change In Democratic Win Margin") + theme(legend.position = "none")

ggsave("figures/narrative/percap_change.png")

ggplot(all_county2, aes(x = log_deaths, y = change_in_D, alpha = 0.1)) + 
  geom_point(aes(color = trump_win)) + 
  geom_smooth(method = "glm") + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("", "")) + 
  theme_minimal() + 
  labs(title = "County COVID-19 Deaths vs. Change in Democratic Win Margin", 
       subtitle = "Change in Democratic Win Margin from 2016-2020 in 1,172 U.S. Counties", 
       x = "Log Total Deaths - (10/21/20)",
       y = "Change In Democratic Win Margin") + theme(legend.position = "none")

ggsave("figures/narrative/total_change.png")

# linear models
change_lm_percap <- lm(change_in_D ~ log_percap, data = all_county2)

change_lm_percap_trumppct <- lm(change_in_D ~ log_percap + trump_pct, data = all_county2)

# change in democratic win margin vs. log deaths
ggplot(all_county2, aes(x = log_deaths, y = trump_pct, alpha = 0.1)) + 
  geom_point(aes(color = trump_win)) + 
  geom_smooth(method = "glm") + 
  geom_smooth(method = "glm") + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("", "")) + 
  theme_minimal() + 
  labs(title = "County COVID-19 Deaths vs. Trump Popular Vote Share", 
       subtitle = "For 1,172 U.S. Counties", 
       x = "Log Total Deaths - (10/21/20)",
       y = "Trump Popular Vote %") + theme(legend.position = "none")

ggsave("figures/narrative/deaths_trumppct.png")

#trump pct vs. log deaths
ggplot(all_county2, aes(x = log_percap, y = trump_pct, alpha = 0.1)) + 
  geom_point(aes(color = trump_win)) + 
  geom_smooth(method = "glm") + 
  geom_smooth(method = "glm") + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("", "")) + 
  theme_minimal() + 
  labs(title = "County COVID-19 Per Capita Deaths vs. Trump Popular Vote Share", 
       subtitle = "For 1,172 U.S. Counties", 
       x = "Log Per Capita Deaths - 10/21/20",
       y ="Trump Popular Vote %") + theme(legend.position = "none")

ggsave("figures/narrative/percap_trumppct.png")

# linear models
pct_lm_percap <- lm(trump_pct ~ log_percap, data = all_county2)

pct_lm_percap_trumppct <- lm(trump_pct ~ log_percap + change_in_D, data = all_county2)
  
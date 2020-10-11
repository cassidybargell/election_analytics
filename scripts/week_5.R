## Week Five - Air War
## 10/12/20

#### Set-up ####
# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)
options(scipen = 999)
library(cowplot) 
library(scales)
library(geofacet) 

# Read in data
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
approval <- read_csv("data/approval_gallup_1941-2020.csv")
covid_approval_fte <- read_csv("data/covid_approval_polls_adjusted.csv") # FTE
covid_approval_avg <- read_csv("data/covid_approval_toplines.csv") # FTE
covid_awards <- read_csv("data/covid_awards_bystate.csv") # https://taggs.hhs.gov/coronavirus
poll_2020 <- read_csv("data/polls_2020.csv") %>%
  rename(date = "end_date") %>% # for a join
  mutate(date = as.Date(date, "%m/%d/%y"))
states <- read_csv("data/csvData.csv") 
# https://data.hrsa.gov/data/reports/datagrid?gridName=COVID19FundingReport
county_grants <- read_csv("data/COVID19_Grant_Report.csv")
fed_grants <- read_csv("data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("data/ad_campaigns_2000-2012.csv") 
ad_creative <- read_csv("data/ad_creative_2000-2012.csv")
vep <- read_csv("data/vep_1980-2016.csv")
poll_state <- read_csv("data/pollavg_bystate_1968-2016.csv")

states_map <- usmap::us_map()
unique(states_map$abbr)

poll_pvstate_vep_df <- poll_state %>%
  right_join(vep) %>%
  right_join(pvstate)

#### Explore past presidential campaign trends in section 
ggplot(ad_creative, aes(x = ad_purpose, fill = party)) + geom_bar(position = "dodge") +
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democratic", "Republican")) + 
  facet_grid(~ cycle) + 
  theme(axis.text.x  = element_text(angle = 45, hjust = 1))


ggplot(ad_creative, aes(x = ad_tone, fill = party)) + geom_bar(position = "dodge") +
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "", 
                    labels = c("Democratic", "Republican")) + 
  facet_grid(~ cycle) + 
  theme(axis.text.x  = element_text(angle = 45, hjust = 1))


ads <- ad_creative %>%
  group_by(ad_issue, cycle, party) %>%
  summarize(n = n()) 

#### Trying the binomial distribution thing, through states

state_forecast <- list()
state_forecast_outputs <- data.frame()

# make poll avg for each state 
polls_20 <- poll_2020 %>%
  right_join(pvstate) %>%
  filter(! is.na(state)) %>%
  group_by(state) %>%
  summarize(avg = mean(pct)) %>%
  rename(avg_poll = "avg") %>%
  mutate(avg_poll = ifelse(is.na(avg_poll), 0, avg_poll)) %>%
  select(state, avg_poll)

# create glm for each state, loop through all states
for (s in unique(poll_pvstate_vep_df$state)) {
  VEP_T_2020 <- as.integer(vep$VEP[vep$state == s & vep$year == 2016])
  state_forecast[[s]]$dat_D <- poll_pvstate_vep_df %>% filter(state== s, party=="democrat")
  state_forecast[[s]]$mod_D <- glm(cbind(D, VEP-D) ~ avg_poll, 
                                   state_forecast[[s]]$dat_D, family = binomial)
  
  state_forecast[[s]]$dat_R <- poll_pvstate_vep_df %>% filter(state== s, party=="democrat") 
  state_forecast[[s]]$mod_R <- glm(cbind(R, VEP-R) ~ avg_poll, 
                                   state_forecast[[s]]$dat_R, family = binomial)
  
  state_forecast[[s]]$prob_Rvote_s_2020 <- predict(state_forecast[[s]]$mod_R, polls_20 %>% filter(state == s) %>%
                                                     select(avg_poll),
                                                   type="response")[[1]]
  state_forecast[[s]]$prob_Dvote_s_2020 <- predict(state_forecast[[s]]$mod_D, polls_20 %>% filter(state == s) %>%
                                                     select(avg_poll), 
                                                   type="response")[[1]]
  state_forecast[[s]]$sim_Rvotes_s_2020 <- rbinom(n = 10000, size = VEP_T_2020, prob = state_forecast[[s]]$prob_Rvote_s_2020)
  state_forecast[[s]]$sim_Dvotes_s_2020 <- rbinom(n = 10000, size = VEP_T_2020, prob = state_forecast[[s]]$prob_Dvote_s_2020)
  state_forecast[[s]]$sim_elxns_s_2020 <- 
    ((state_forecast[[s]]$sim_Dvotes_s_2020-state_forecast[[s]]$sim_Rvotes_s_2020)/(state_forecast[[s]]$sim_Dvotes_s_2020+state_forecast[[s]]$sim_Rvotes_s_2020))*100
}

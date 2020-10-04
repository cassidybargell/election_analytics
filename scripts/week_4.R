## Week Four - Incumbency
## 10/5/20

#### Set-up ####

#### Ideas: Compare approval ratings when Donald Trump and Obama were in office
#### over time. Evaluate the strength of the incumbency advantage for Trump if
#### Biden has also served in a previous admin.
# https://www-washingtonpost-com.ezp-prod1.hul.harvard.edu/politics/2020/05/19/49-50-governors-have-better-coronavirus-numbers-than-trump/ics/2020/05/19/49-50-governors-have-better-coronavirus-numbers-than-trump/

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)
options(scipen = 999)

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

states_map <- usmap::us_map()
unique(states_map$abbr)

# Only want state data
state_covid_awards <- covid_awards %>%
  right_join(states) %>%
  rename(state = "State")

state_covid_awards$total = gsub(",", "", state_covid_awards$Total)
state_covid_awards$total = as.numeric(gsub("\\$", "", state_covid_awards$total))

#### Figure 1 

# Trump approval rating through time 
# Might use unsure as the upper end of the error bar

# Load lineplot theme
my_line_theme <- theme_bw() + 
  theme(panel.border = element_blank(),
        plot.title   = element_text(size = 15, hjust = 0.5), 
        axis.text.x  = element_text(angle = 45, hjust = 1),
        axis.text    = element_text(size = 12),
        strip.text   = element_text(size = 18),
        axis.line    = element_line(colour = "black"),
        legend.position = "top",
        legend.text = element_text(size = 12),
        plot.subtitle = element_text(size = 13, hjust = 0.5))

# Filter for two most recent presidencies
approval_DT_BO <- approval %>%
  filter(president == "Donald Trump" | president == "Barack Obama") %>%
  mutate(ymax_DT = (approve + unsure_NA)) 

# plot through time
approval_DT_BO %>%
  ggplot(aes(x = poll_enddate, y = approve, color = president)) + geom_line() + 
  scale_y_continuous(limits = c(0, 100)) + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Barack Obama", "Donald Trump")) + 
  # geom_errorbar(aes(ymin = approve, ymax = ymax_DT)) + 
  my_line_theme + 
  labs(title = "Approval Ratings Through Time", 
       subtitle = "Gallup Poll, 2008-2020") + 
  xlab("Poll End-Date") + 
  ylab("Approval (%)")

ggsave("figures/approval_through_time.png")

#### Line graph of Approval Rating for Trump's COVID Response

# set up for ggplot 
approval_DT <- approval %>%
  filter(president == "Donald Trump") %>%
  rename(date = "poll_enddate")

covid_approval_avg <- covid_approval_avg %>%
  mutate(date = as.Date(modeldate, "%m/%d/%y")) %>%
  filter(party == "all")

covid_approval <- covid_approval_avg %>%
  full_join(approval_DT, by = c()) %>%
  drop_na()

# Plot Trump general approval as well as COVID-19 Response Approval
ggplot(covid_approval, aes(x = date)) +
  geom_line(aes(y = approve_estimate, color = "COVID-19 Response"), linetype = 2) + 
  geom_line(aes(y = approve, color = "General")) + 
  my_line_theme +
  scale_color_manual(values = c("steelblue", "darkred")) +
  labs(title = "Trump Average General Approval and COVID-19 Response Approval",
       subtitle = "2020",
    color=" ",
    y = "Approval (%)",
    x = "Date") 

ggsave("figures/trump_2020_approvals.png")

#### Visualize COVID-19 Spending 
# Compare average polling outcome by state and find states with close margin,
# look at federal spending there. Possibly look at partisan leanings (paper from
# class) and determine which states more spending might actually work for.

# plot states by federal covid-19 relief spending
plot_usmap(data = state_covid_awards, regions = "states", values = "total") + 
  theme_void() +
  scale_fill_gradient2(
    high = "darkgreen",
    low = "white",
    name = "Federal COVID-19 Awards") + 
  labs(title = "COVID-19 Relief Awards",
       subtitle = "Totals from the Dept. of Health and Human Services",
       caption = "https://taggs.hhs.gov/coronavirus") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/state_covid_relief.png")

#### State Polls and Federal COVID-19 Aid 
# arbitrarily chose 48-52 poll averages as close, more competitiv

covid_awards$state <- covid_awards$State

# Look at states with close polls and high spending
combine <- covid_awards %>%
  left_join(poll_2020) %>%
  filter(date >= "2020-01-01") %>%
  filter(candidate_name == "Donald Trump") %>%
  group_by(state) %>%
  filter(pct >= 48) %>%
  filter(pct <= 52) %>%
  filter(state != "Alabama" & state != "Iowa" & state != "Michigan" & 
           state != "Minnesota" & state != "Tennessee")

combine$total = gsub(",", "", combine$Total)
combine$total = as.numeric(gsub("\\$", "", combine$total))

# facet wrap states with pct 
ggplot(combine, aes(x = date, color = total)) +
  geom_line(aes(y = pct)) + 
  facet_wrap(facets = state ~ .) + 
  theme_minimal() + 
  scale_color_gradient2(
    high = "darkgreen",
    low = "white",
    name = "Federal COVID-19 Awards") + 
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) + 
  labs(title = "States and Federal COVID-19 Awards")

ggsave("figures/states_vs_federalspend.png")

#### Try to make a prediction, super super simple weighted ensemble. 

# Approval ratings not stratified by state, hard to predict electoral college
# outcome due to this

gallup <- popvote %>%
  left_join(approval) %>% 
  filter(incumbent == T) %>%
  group_by(year) %>%
  mutate(avg = mean(approve))

lm_gallup <- lm(pv ~ avg, data = gallup) 
  
covid <- covid_approval_avg %>%
  summarize(avg = mean(approve_estimate))

gallup_p <- approval_DT %>%
  summarize(avg = mean(approve))

prediction1 <- 0.5 * (covid$avg) + 0.5 * predict(lm_gallup, gallup_p)
prediction2 <- 0.75 * (covid$avg) + 0.25 * predict(lm_gallup, gallup_p) 
prediction3 <- 0.75 * predict(lm_gallup, gallup_p) + 0.25 * (covid$avg)
prediction4 <- 0.85 * (covid$avg) + 0.15 * predict(lm_gallup, gallup_p)
prediction5 <- 0.85 * predict(lm_gallup, gallup_p) + 0.15 * (covid$avg)

#### Things I wanted to maybe attempt but didnt have time for ####

## Improve last weeks weighted ensemble, replace unemployment with federal
## spending for COVID relief, weight very small, use approval of job instead
## of polling info

# dummy variable: 1 if historically close polling_avg and high spending for
# COVID-19 relief (top 15 states), 0 if neither of those. Randomly choosing and
# then will weight

# DT_2020 <- poll_2020 %>%
# filter(fte_grade == "A" | fte_grade == "A+" | fte_grade == "A-" | fte_grade == "A/B" | 
# fte_grade == "B+" | fte_grade == "B" | fte_grade == "B-") %>%
# group_by(state) %>%
# summarize(avg = mean(pct))




  
  



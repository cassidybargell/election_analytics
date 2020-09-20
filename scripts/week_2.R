## Week Two - Figures
## 9/21/20

#### Set-up #### Plot quarters and find best model Trump quarters in 2020 are
#extrapolation that we have so far, predict using a Trump old quarter/yearly
#average Other economic sources - real disposable income, etc.
#https://fred.stlouisfed.org/series/DSPIC96

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)

# Read in data
# FRED.org for resources
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
econ <- read_csv("data/econ.csv")
local_econ <- read_csv("data/local.csv")
rdpi <- read_csv("data/DSPIC96.csv") #FRED
unrate <- read_csv("data/UNRATE (1).csv") #FRED
inflate <- read_csv("data/FPCPITOTLZGUSA.csv") # FRED

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)

# Join econ and popvote, keep all quarters including 2020
dat <- econ %>% 
  filter(year >= 1948) %>%
  slice(1:290) %>% # want to keep all quarters not just 1 and/or 2
  full_join(popvote %>% filter(incumbent_party == TRUE) %>%
               select(year, winner, pv2p)) %>%
  mutate(winner = ifelse(year == 2020 | 
                           year == 2019 |
                           year == 2018 |
                           year == 2017, "?", winner)) %>% 
  # easy way to keep all of trump year econ data 
  filter(! is.na(winner)) %>%
  mutate(winner = ifelse(winner == "?", NA, winner))

# Create tibble with differences for RDI
changes <- dat %>%
  mutate(rdi_rate = ((RDI - lag(RDI, n = 1))/ lag(RDI, n = 1))) %>%
  filter(year != 2017 & year != 2018 & year != 2019 )

# Create tibble with inflation rates and pv2p
inflate_popvote <- inflate %>%
  mutate(date = as.character(DATE)) %>%
  mutate(year = substr(date, 1, 4)) %>%
  mutate(year = as.double(year)) %>%
  rename(inflation_rate = "FPCPITOTLZGUSA") %>%
  select(year, inflation_rate) %>%
  right_join(popvote) %>%
  filter(incumbent_party == TRUE)

# Create real disposable personal income averages by year, make a rate column
rdpi1 <- rdpi %>% 
  mutate(date = as.character(DATE)) %>%
  mutate(date = substr(date, 1, 4)) %>%
  group_by(date) %>%
  summarize(yr_rdpi = mean(DSPIC96)) %>%
  mutate(year = as.double(date)) %>%
  select(year, yr_rdpi) %>%
  mutate(rdpi_rate = (100 * (yr_rdpi - lag(yr_rdpi, n = 1))/lag(yr_rdpi, n = 1)))

# Join with popvote percentage for potential later use
rdpi_popvote <- popvote %>%
  left_join(rdpi1) %>%
  filter(incumbent_party == TRUE)

# Do the same for unemployment rate, same FRED source
unrate <- unrate %>%
  mutate(date = as.character(DATE)) %>%
  mutate(quarter = substr(date, 6, 7)) %>%
  filter(quarter == "04") %>%
  mutate(year = substr(date, 1, 4)) %>%
  rename(unrate = "UNRATE") %>%
  mutate(year = as.double(year)) %>%
  select(year, unrate)

# Join with popvote percentage for potential later use
unrate_popvote <- popvote %>%
  left_join(unrate) %>%
  filter(incumbent_party == TRUE)

#### Figure 1 - GDP Quarterly Growth vs. Incumbent party share
# Plot scatterplot for all quarters
# Plot all on same figure with facet_wrap
dat %>%
  slice(1:72) %>%
  filter(quarter != 4) %>%
  ggplot(aes(x=GDP_growth_qt, y=pv2p, label = year)) + 
  facet_wrap(facets = quarter ~ .) +
  geom_text(size = 1.8) +
  geom_smooth(method="lm", se = FALSE, formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Quarterly GDP growth") +
  ylab("Incumbent party's two-party popular vote share") +
  labs(title = "Incumbent Party Vote Share vs. Quarterly GDP Growth") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme_bw()

ggsave("figures/gdp_v_pv2p.png")

# Fit models for each quarter and yearly GDP

q1 <- dat %>%
  slice(1:72) %>%
  filter(quarter == 1) 
q2 <- dat %>%
  slice(1:72) %>%
  filter(quarter == 2)
q3 <- dat %>%
  slice(1:72) %>%
  filter(quarter == 3)
q4 <- dat %>%
  slice(1:72) %>%
  filter(quarter == 4)
yr <- dat %>% 
  slice(1:72)

# Use Q2 for best fit aswell as it is the most recent quarter with information
# available
lm_q1 <- lm(pv2p ~ GDP_growth_qt, data = q1)
summary(lm_q1)
# Q1 t value for slope is <2 = 1.102
lm_q2 <- lm(pv2p ~ GDP_growth_qt, data = q2)
summary(lm_q2)
summary(lm_q2)$r.squared
# Q2 t value for slope is >2 = 2.783, Rsquared = 0.261
lm_q3 <- lm(pv2p ~ GDP_growth_qt, data = q3)
summary(lm_q3)
# Q3 t value for slop >2 = 2.116
lm_q4 <- lm(pv2p ~ GDP_growth_qt, data = q4)
summary(lm_q4)
# Q4 t value 0.241
lm_yr <- lm(pv2p ~ GDP_growth_yr, data = yr)
summary(lm_yr)
# Yr t value 4.747

# MSE - in-sample testing
mse_q1 <- sqrt(mean((lm_q1$model$pv2p - lm_q1$fitted.values)^2))

mse_q2 <- sqrt(mean((lm_q2$model$pv2p - lm_q2$fitted.values)^2))

mse_q3 <- sqrt(mean((lm_q3$model$pv2p - lm_q3$fitted.values)^2))

mse_q4 <- sqrt(mean((lm_q4$model$pv2p - lm_q4$fitted.values)^2))

mse_yr <- sqrt(mean((lm_yr$model$pv2p - lm_yr$fitted.values)^2))

# Cross-validation - out-of-sample testing
outsamp_errors <- sapply(1:1000, function(i){
  years_outsamp <- sample(q2$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_qt,
                    
                    q2[!(q2$year %in% years_outsamp),])
  
  outsamp_pred <- predict(outsamp_mod,
                          
                          newdata = q2[q2$year %in% years_outsamp,])
  outsamp_true <- q2$pv2p[q2$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})

mean_outsample_q2 <- mean(abs(outsamp_errors))

outsamp_errors_yr <- sapply(1:1000, function(i){
  years_outsamp <- sample(yr$year, 8)
  outsamp_mod <- lm(pv2p ~ GDP_growth_yr,
                    
                    yr[!(yr$year %in% years_outsamp),])
  
  outsamp_pred <- predict(outsamp_mod,
                          
                          newdata = yr[yr$year %in% years_outsamp,])
  outsamp_true <- yr$pv2p[yr$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})
mean_outsample_yr <- mean(abs(outsamp_errors_yr))

# Q2 GDP Predict for 2020
GDP_newq2 <- econ %>%
  subset(year == 2020 & quarter == 2) %>%
  select(GDP_growth_qt)

q2GDP_predict <- predict(lm_q2, GDP_newq2)

# Use 2019 Q4 as a precorona measure of GDP
GDP_precorona <- econ %>%
  subset(year == 2019 & quarter == 4) %>%
  select(GDP_growth_qt)

precoronaGDP_predict <- predict(lm_q2, GDP_precorona)

# Use avg of 2017-2019 yearly gdp as newX for linear model of yearly gdp for
# trump, this also excludes first two quarters of data from when corona started.
GDP_trump <- econ %>%
  filter(year == 2017 |
           year == 2018 |
           year == 2019) %>%
  select(GDP_growth_qt) %>% 
  summarize(GDP_growth_qt = mean(GDP_growth_qt))

# Prediction using quarter model with a newX that is an average of all of
# Trump's previous quarters before corona.
trumpGDPqt_predict <- predict(lm_q2, GDP_trump)

GDP_trump_yr <- econ %>%
  filter(year == 2017 |
           year == 2018 |
           year == 2019) %>%
  select(GDP_growth_yr) %>% 
  summarize(GDP_growth_yr = mean(GDP_growth_yr))

# Prediction using 2017-2019 year GDP average as a newX for estimate of before
# coronavirus.
trumpGDPyr_predict <- predict(lm_yr, GDP_trump_yr)

#### Visualizing other economic factors
econ %>%
  subset(quarter == 2 & !is.na(GDP_growth_qt)) %>%
  ggplot(aes(x=year, y=GDP_growth_qt,
             fill = (GDP_growth_qt > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("GDP Growth (Second Quarter)") +
  ggtitle("The percentage decrease in G.D.P. is by far the biggest on record.") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

econ %>%
  subset(quarter == 2 & !is.na(inflation)) %>%
  ggplot(aes(x=year, y=inflation,
             fill = (inflation > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("Inflation (Second Quarter)") +
  ggtitle("Historical Second Quarter Inflation Rates") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

econ %>%
  subset(quarter == 2 & !is.na(unemployment)) %>%
  ggplot(aes(x=year, y=unemployment,
             fill = (unemployment > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("Unemployment Rates (Second Quarter)") +
  ggtitle("Historical Quarter 2 Unemployment Rates") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

econ %>%
  subset(quarter == 2 & !is.na(RDI_growth)) %>%
  ggplot(aes(x=year, y=RDI_growth,
             fill = (RDI_growth > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("RDI Growth (Second Quarter)") +
  ggtitle("Historical Quarter 2 RDI Growth Rates") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

#### Real Disposable Personal Income 

# Units are 2012 Billions of Chained 2012 Dollars, Seasonally Adjusted Annual Rate
rdpi_popvote %>%
  subset(!is.na(rdpi_rate)) %>%
  ggplot(aes(x=year, y=rdpi_rate,
             fill = (yr_rdpi > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("RDPI") +
  ggtitle("Historical Real Disposable Personal Income Growth") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

rdpi_popvote %>%
  ggplot(aes(x=rdpi_rate, y=pv2p, label = year)) +
  geom_text(size = 1.8) +
  geom_smooth(method="lm", se = FALSE, formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Quarterly GDP growth") +
  ylab("Incumbent party's two-party popular vote share") +
  labs(title = "Incumbent Party Vote Share vs. Change in Real Disposable Income") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme_bw()

ggsave("figures/rdpi_lm.png")

# Build linear model
rdpi2 <- rdpi_popvote %>%
  filter(! is.na(rdpi_rate)) %>%
  filter(! is.na(pv2p))

lm_rdpi <- lm(pv2p ~ rdpi_rate, data = rdpi2)
summary(lm_rdpi)
# t value of 4.036 for slope

# RDPI Predict for 2020
inflate_new <- rdpi_popvote %>%
  filter(year == 2020) %>%
  select(rdpi_rate)

rdpi_predict <- predict(lm_rdpi, rdpi2)

# out-of-sample cross-validation
outsamp_errors_rdpi <- sapply(1:1000, function(i){
  years_outsamp <- sample(rdpi2$year, 8)
  outsamp_mod <- lm(pv2p ~ rdpi_rate,
                    
                    rdpi2[!(rdpi2$year %in% years_outsamp),])
  
  outsamp_pred <- predict(outsamp_mod,
                          
                          newdata = rdpi2[rdpi2$year %in% years_outsamp,])
  outsamp_true <- rdpi2$pv2p[rdpi2$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})
mean_outsample_rdpi <- mean(abs(outsamp_errors_rdpi))

#### Inflation Plot and Prediction

inflate_popvote %>%
  select(year, inflation_rate) %>%
  filter(!is.na(inflation_rate)) %>%
  ggplot(aes(x=year, y=inflation_rate,
             fill = (inflation_rate > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("Inflation Rate (%)") +
  ggtitle("Historical Quarter 2 Inflation Rates") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))
# Plot relationship
inflate_popvote %>%
  filter(! is.na(inflation_rate)) %>%
  ggplot(aes(x=inflation_rate, y=pv2p, label = year)) +
  geom_text(size = 1.8) +
  geom_smooth(method="lm", se = FALSE, formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) + 
  xlab("Inflation Rate (%)") +
  ylab("Incumbent party's two-party popular vote share") +
  labs(title = "Incumbent Party Vote Share vs. Inflation Rate") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme_bw()

ggsave("figures/inflate_lm.png")

# Build linear model
yr_inflate <- inflate_popvote %>%
  filter(! is.na(inflation_rate)) %>%
  filter(! is.na(pv2p))

lm_inflate <- lm(pv2p ~ inflation_rate, data = yr_inflate)
summary(lm_inflate)
# t value of -1.045 for slope

# Inflation Predict for 2020 using 2019, as its the most recent data I have for
# inflation rate
inflate_new <- inflate%>%
  mutate(date = as.character(DATE)) %>%
  mutate(year = substr(date, 1, 4)) %>%
  mutate(year = as.double(year)) %>%
  rename(inflation_rate = "FPCPITOTLZGUSA") %>%
  filter(year == 2019)

inflate_predict <- predict(lm_inflate, inflate_new)

# out-of-sample cross-validation
outsamp_errors_inflate <- sapply(1:1000, function(i){
  years_outsamp <- sample(yr_inflate$year, 8)
  outsamp_mod <- lm(pv2p ~ inflation_rate,
                    
                    yr_inflate[!(yr_inflate$year %in% years_outsamp),])
  
  outsamp_pred <- predict(outsamp_mod,
                          
                          newdata = yr_inflate[yr_inflate$year %in% years_outsamp,])
  outsamp_true <- yr_inflate$pv2p[yr_inflate$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})
mean_outsample_inflate <- mean(abs(outsamp_errors_inflate))

#### Unemployment Plot and Prediction

unrate_popvote %>%
  ggplot(aes(x=year, y=unrate,
             fill = (unrate > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("Unemployment Rate Change from  Growth (Second Quarter)") +
  ggtitle("Historical Quarter 2 Unemployment Rates") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))

# Plot relationship
unrate_popvote %>%
  ggplot(aes(x=unrate, y=pv2p, label = year)) +
  geom_text(size = 3) +
  geom_smooth(method="lm", se = FALSE, formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) + 
  xlab("Quarter 2 Estimated Unemployment Rate") +
  ylab("Incumbent party's two-party popular vote share") +
  labs(title = "Incumbent Party Vote Share vs. Unemployment Rate") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme_bw()

ggsave("figures/unemployment_lm.png")

# Build linear model

q2_unemploy <- unrate_popvote %>%
  filter(! is.na(unrate)) %>%
  filter(! is.na(pv2p))

lm_unemploy <- lm(pv2p ~ unrate, data = q2_unemploy)
summary(lm_unemploy)
# t value of 0.027 for slope

# Cross validation out-of-sample test
# Around same mean outsample error in comparison to yearly GDP model
outsamp_errors_unemploy <- sapply(1:1000, function(i){
  years_outsamp <- sample(q2_unemploy$year, 8)
  outsamp_mod <- lm(pv2p ~ unrate,
                    
                    q2_unemploy[!(q2_unemploy$year %in% years_outsamp),])
  
  outsamp_pred <- predict(outsamp_mod,
                          
                          newdata = q2_unemploy[q2_unemploy$year %in% years_outsamp,])
  outsamp_true <- q2_unemploy$pv2p[q2_unemploy$year %in% years_outsamp]
  mean(outsamp_pred - outsamp_true)
})
mean_outsample_unemploy <- mean(abs(outsamp_errors_unemploy))


# Q2 Unemployment Predict for 2020
unemploy_new <- unrate %>%
  subset(year == 2020) %>%
  select(unrate)

unemploy_predict <- predict(lm_unemploy, unemploy_new)

#### Local Plot 

# Using quarter 2 manually again. Positive win_margin is democrat win, negative
# is republican
local <- local_econ %>%
  rename("state" = `State and area`) %>%
  rename("year" = `Year`) %>%
  filter(Month == "04" | Month == "05" | Month == "06") %>%
  group_by(state, year) %>%
  summarize(local_unemploy = mean(Unemployed_prce)) %>%
  ungroup() %>%
  right_join(pvstate) %>%
 #  mutate(win_margin = (D_pv2p - R_pv2p)) %>%
  filter(! is.na(local_unemploy))

# https://www.npr.org/2020/09/16/912004173/2020-electoral-map-ratings-landscape-tightens-some-but-biden-is-still-ahead
# Use this for swing states to include 

# Not a helpful plot at all, will probably just facet_wrap some swing states
local %>%
  filter(state == "Arizona" |
           state == "Texas" | 
           state == "New Hampshire" |
           state == "Wisconsin" | 
           state == "Florida" | 
           state == "Minnesota" | 
           state == "Michigan" | 
           state == "Pennsylvania" |
           state == "North Carolina" | 
           state == "Georgia" |
           state == "Ohio") %>%
  ggplot(aes(x=local_unemploy, y=R_pv2p, label = year)) + 
  facet_wrap(facets = state ~ .) +
  geom_text(size = 1.8) +
  geom_smooth(method="lm", se = FALSE, formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0, lty=2) +
  xlab("Unemployment Percentage") +
  ylab("Republican Two-party Vote Share") +
  labs(title = "State Unemployment Rate vs. Republican Two-Party Vote Share", 
       subtitle = "Quarter 2 Historical Unemployment Rates") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme_bw()

ggsave("figures/swing_lm.png")

# Build prediction and linear model function 

state_lm <- function(s){
  ok <- local %>%
    filter(state == s)
  
  s <- lm(R_pv2p ~ local_unemploy, data = ok)
  print(summary(s)$r.squared)
}

# Look at R.squared value for each, only will use those with an R.squared value
# >= 0.1. Those states are WI, PA, OH, MI, GA
AZ_lm <- state_lm("Arizona")
TX_lm <- state_lm("Texas")
NH_lm <- state_lm("New Hampshire") 
WI_lm <- state_lm("Wisconsin") 
FL_lm <- state_lm("Florida") 
MN_lm <- state_lm("Minnesota") 
MI_lm <- state_lm("Michigan") 
PA_lm <- state_lm("Pennsylvania") 
NC_lm <- state_lm("North Carolina") 
GA_lm <- state_lm("Georgia")
OH_lm <- state_lm("Ohio")

lm_state <- function(s){
  ok <- local %>%
    filter(state == s)
  
  s <- lm(R_pv2p ~ local_unemploy, data = ok)
}

WI <- lm_state("Wisconsin") 
MI <- lm_state("Michigan") 
PA <- lm_state("Pennsylvania") 
GA <- lm_state("Georgia")
OH <- lm_state("Ohio")

state_new <- local_econ %>%
  rename("state"= `State and area`) %>%
  filter(Month == "04" | Month == "05" | Month == "06") %>%
  filter(state == "Wisconsin" | 
           state == "Michigan" |
           state == "Pennsylvania" |
           state == "Georgia" |
           state == "Ohio") %>%
  filter(Year == 2020) %>%
  select(state, Year, Unemployed_prce) %>%
  group_by(state) %>%
  summarize(local_unemploy = mean(Unemployed_prce))

# predict win margin with these linear models in these states, make tibble
state_predictions <- state_new %>%
mutate(WI_predict =  predict(WI, state_new %>%
                        filter(state == "Wisconsin"))) %>%
mutate(MI_predict = predict(MI, state_new %>%
                              filter(state == "Michigan"))) %>%
  mutate(PA_predict = predict(PA, state_new %>%
                                filter(state == "Pennsylvania"))) %>%
  mutate(GA_predict = predict(GA, state_new %>%
                                filter(state == "Georgia"))) %>%
  mutate(OH_predict = predict(OH, state_new %>%
                                filter(state == "Ohio"))) %>%
  select(ends_with("predict")) %>%
  head(1)
  
# These electoral college votes add up to 64 electoral college votes for Trump,
# and 16 for Biden in these swing states. Again r.squared value of only >0.1, so
# not very convincing results.
  
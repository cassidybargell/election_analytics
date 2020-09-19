## Week Tw0 - Figures
## 9/21/20

#### Set-up ####
# Plot quarters and find best model 
# Show why can't use Trump quarters that we have so far
# Predict using a Trump good quarter? 
# Other economic sources - real disposable income, 
# etc. https://fred.stlouisfed.org/series/DSPIC96

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)
library(ggrepel)
library(skimr)
library(gt)

# Read in data
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")
econ <- read_csv("data/econ.csv")
local_econ <- read_csv("data/local.csv")
rdpi <- read_csv("data/DSPIC96.csv")

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

# Create real disposable personal income averages by year
rdpi1 <- rdpi %>% 
  mutate(date = as.character(DATE)) %>%
  mutate(date = substr(date, 1, 4)) %>%
  group_by(date) %>%
  summarize(yr_rdpi = mean(DSPIC96)) %>%
  mutate(year = as.double(date)) %>%
  select(year, yr_rdpi)

rdpi_popvote <- popvote %>%
  left_join(rdpi1)

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

#### Compare other economic predictors
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

#### Local Level Plot



#### Good News Quarters vs. Q2 for Trump 
# Explain why can't use Q2 for Trump, so plot 

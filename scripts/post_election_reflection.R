## Post Election Reflection
## 11/23/20

# Missed Florida, Ohio, and North Carolina

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

#### Look at accuracy of model difference is predicted - actual; a negative
# value means trump vote share was higher than predicted, a postive difference
# means trump vote share was lower than predicted
accuracy <- pop_vote_actual %>%
  filter(year == "2020") %>%
  right_join(my_predictions) %>%
  mutate(real_Rpv2p = 100 * R_pv2p) %>%
  mutate(rmse_diff = rmse_predictions - real_Rpv2p) %>%
  mutate(choice_diff = predictions - real_Rpv2p) %>%
  mutate(trump_win = ifelse(real_Rpv2p > 50, T, F))

#### Visualize simple accuracy differences
## RMSE model
ggplot(accuracy, aes(x = rmse_diff, fill = trump_win)) + 
  geom_histogram(bins = 20) + 
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "State Winner", 
                     labels = c("Biden", "Trump")) + 
  geom_text(x = -8.256, y = 1.4, label = "NY", size = 4) + 
  labs(title = "Difference Between Actual and Predicted Vote Share",
       subtitle = "RMSE Weighted Model",
       x = "Trump Predicted - Trump Actual",
       y = "Frequency")

# visualize split by red/blue states
ggplot(accuracy, aes(x = rmse_diff, fill = trump_win)) + 
  facet_wrap(~ trump_win) + 
  geom_histogram(bins = 20) + 
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "State Winner", 
                    labels = c("Biden", "Trump")) +
  labs(title = "Difference Between Actual and Predicted Vote Share",
       subtitle = "RMSE Weighted Model",
       x = "Trump Predicted - Trump Actual",
       y = "Frequency")


## Choice Weights Model
ggplot(accuracy, aes(x = choice_diff, fill = trump_win)) + 
  geom_histogram(bins = 20) + 
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "State Winner", 
                    labels = c("Biden", "Trump")) + 
  geom_text(x = -7.1, y = 1.4, label = "NY", size = 4) + 
  labs(title = "Difference Between Actual and Predicted Vote Share",
       subtitle = "Choice Weighted Model",
       x = "Trump Predicted - Trump Actual",
       y = "Frequency")

# split by red/blue states
ggplot(accuracy, aes(x = choice_diff, fill = trump_win)) + 
  facet_wrap(~ trump_win) + 
  geom_histogram(bins = 20) + 
  theme_minimal() + 
  scale_fill_manual(values = c("blue", "red"), name = "State Winner", 
                    labels = c("Biden", "Trump")) + 
  labs(title = "Difference Between Actual and Predicted Vote Share",
       subtitle = "Choice Weighted Model",
       x = "Trump Predicted - Trump Actual",
       y = "Frequency")

#### Get RMSE for predicted vs. actual

# have to filter for D.C. because didnt have a predicted value for the district
# using RMSE method
accuracy_dc <- accuracy %>%
  filter(state != "District of Columbia")
rmse1 <- Metrics::rmse(accuracy_dc$real_Rpv2p, accuracy_dc$rmse_predictions)

# rmse for choice weights
rmse2 <- Metrics::rmse(accuracy$real_Rpv2p, accuracy$predictions)

# find rmse for split states red and blue using RMSE model
accuracy_dc_red <- accuracy_dc %>%
  filter(trump_win == T)

rmse1_red <- Metrics::rmse(accuracy_dc_red$real_Rpv2p, accuracy_dc_red$rmse_predictions)

accuracy_dc_blue <- accuracy_dc %>%
  filter(trump_win == F)

rmse1_blue <- Metrics::rmse(accuracy_dc_blue$real_Rpv2p, accuracy_dc_blue$rmse_predictions)

# repeat above for choice in weights model

accuracy_red <- accuracy %>%
  filter(trump_win == T)

rmse2_red <- Metrics::rmse(accuracy_red$real_Rpv2p, accuracy_red$predictions)

accuracy_blue <- accuracy %>%
  filter(trump_win == F)

rmse2_blue <- Metrics::rmse(accuracy_blue$real_Rpv2p, accuracy_blue$predictions)

# rmse higher for red states than it is blue states in both cases, missing blue
# states by more?

#### Find average error in differences?


#### Polling 
# Look at just 2020 first, then can go back and consider other years maybe. 
# Over fitting with the COVID model? possibly. 

# poll data I used, find difference between final poll pct adjusted and real
# popular vote share. Negative means that the real vote share was higher than
# predicted, positive means predicted was higher than actual
poll_pop <- polls_10_29 %>%
  filter(modeldate == "10/29/2020") %>%
  filter(candidate_name == "Donald Trump") %>%
  left_join(pop_vote_actual) %>%
  filter(year == "2020") %>%
  mutate(real_Rpv2p = 100 * R_pv2p) %>%
  mutate(poll_diff = pct_trend_adjusted - real_Rpv2p) %>%
  mutate(trump_win = ifelse(real_Rpv2p > 50, T, F))

# visualize this
ggplot(poll_pop, aes(x = pct_trend_adjusted, y = real_Rpv2p, color = trump_win)) + geom_point() + 
  geom_abline(intercept = 0, slope = 1) + 
  theme_minimal() + 
  labs(title = "Incumbent Poll Average vs. Actual Vote Share",
       subtitle = "Poll Average Trend Adjusted from 10-29-20",
       x = "Poll % for Trump",
       y = "Actual % for Trump") + 
  scale_color_manual(values = c("blue", "red"), name = "State Winner", 
                    labels = c("Biden", "Trump")) 

#### Visualize predictions vs. actual 
ggplot(accuracy, aes(x = rmse_predictions, y = real_Rpv2p, color = trump_win)) + geom_point() + 
  geom_abline(intercept = 0, slope = 1) + 
  theme_minimal() + 
  scale_x_continuous(limits = c(20, 80), breaks = c(40, 60)) + 
  scale_y_continuous(limits = c(20, 80), breaks = c(40, 60)) + 
  scale_color_manual(values = c("blue", "red"), name = "State Winner", 
                     labels = c("Biden", "Trump")) + 
  labs(title = "Predicted vs. Actual Vote Share",
       subtitle = "RMSE Weighted Predictions",
       x = "Predicted Popular Vote % for Trump",
       y = "Actual Popular Vote % for Trump") + 
  geom_vline(xintercept = 50, linetype = 2)


#### Closer look at the three states I missed
three <- accuracy %>%
  filter(state == "Ohio" | state == "North Carolina" | state == "Florida") %>%
  select(rmse_predictions, rmse_diff, predictions, choice_diff)

# which model; rmse or choice weighted was better
compare <- accuracy %>%
  mutate(rmse_closer = ifelse((abs(rmse_diff) < abs(choice_diff)), T, F)) %>%
  filter(state != "District of Columbia")

compare %>%
  count(rmse_closer)

compare.labs <- c("Choice Better", "RMSE Better")
names(compare.labs) <- c("FALSE", "TRUE")

# see if one model or the other was more accurate with a certain type of state
ggplot(compare, aes(state = state, fill = trump_win)) + 
  geom_statebins() + 
  theme_statebins() + 
  facet_wrap(~ rmse_closer, 
             labeller = labeller(rmse_closer = compare.labs)) +
  scale_fill_manual(values=c("#619CFF", "#F8766D")) + 
  labs(title = "Compare Accuracy Between RMSE and Choice Models",
       fill = "Trump Win")


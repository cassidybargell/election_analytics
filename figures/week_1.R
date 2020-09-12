## Week One - Figures
## 9/14/20

# Idea: gganimate swing? state changes in two party vote over the years. 

#### Set-up ####

# Load necessary packages
library(tidyverse)
library(usmap)
library(ggplot2)

# Read in data
popvote <- read_csv("data/popvote_1948-2016.csv")
pvstate <- read_csv("data/popvote_bystate_1948-2016.csv")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)

#### Plot 1 - two party vote share difference through years, like the line graph
#### but showing decreasing differences through time, elections getting closer
#### in popular vote

# My line plot theme snippet, copied from section
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

ggplot(popvote, aes(x = year, y = pv2p, colour = party)) +
  geom_line(stat = "identity") +
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democratic", "Republican")) +
  xlab("") + ## no need to label an obvious axis
  ylab("Popular Vote %") +
  labs(title = "Presidential Popular Vote (1948-2016)",
          subtitle = "Two-Party Vote Share") + 
  scale_x_continuous(breaks = seq(from = 1948, to = 2016, by = 4)) +
  my_line_theme + 
  theme(plot.subtitle = element_text(size = 13, hjust = 0.5))

ggsave("figures/pv2p_histline.png", height = 4, width = 8)

# Pivot data wider to have column with just the difference between two-party
# vote share. Negative values are Republican loss, positive values are
# Democratic loss, win indicates winner of popular vote.
pv2p_diff_df <- popvote %>%
  select(year, party, pv2p) %>%
  pivot_wider(names_from = party, values_from = pv2p) %>%
  mutate(diff = (democrat - republican)) %>%
  mutate(win = case_when(diff > 0 ~ "democrat",
                         TRUE ~ "republican"))

# Plot different in two-party popular vote share 
ggplot(pv2p_diff_df, aes(x = year, y = diff)) + 
  geom_line() + 
  geom_point(aes(color = win)) + 
  scale_color_manual(values = c("blue", "red"), name = "", 
                     labels = c("Democratic win", "Republican win")) +
  xlab("") + 
  ylab("Difference in Popular Vote %") +
  labs(title = "Difference in Presidential Popular Vote (1948-2016)",
       subtitle = "Two-Party Vote Share") + 
  scale_x_continuous(breaks = seq(from = 1948, to = 2016, by = 4)) +
  geom_hline(yintercept = 0, linetype = "dashed", size = .3) + 
  my_line_theme  
  
ggsave("figures/pv2p_diff_histline.png", height = 4, width = 8)

#### Plot 2 - States map with percentages of popular vote share -- purple quote.
#### labels = TRUE

#### Plot 3 - Swing states decide because of electoral college. Do swing state
#### extension option gganimate showing swing states over time? predict same as
#### 2020 except for states you designated as "swing"

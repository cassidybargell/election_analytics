## Week One - Figures
## 9/14/20

#### Set-up ####

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
ec <- read_csv("data/ec_1952-2020.csv")

# Create states map
states_map <- usmap::us_map()
unique(states_map$abbr)

#### Plot 1 - two party vote share difference through years, like the line graph
#### but showing decreasing differences through time, elections getting closer
#### in popular vote

# My line plot theme snippet, copied from section with subtitle addition
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

# lineplot from section, slightly altered
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
  theme(plot.subtitle = element_text(size = 13, hjust = 0.5),
        panel.background = element_blank()) 

ggsave("figures/pv2p_histline_blank.png", height = 4, width = 8)

# Pivot data wider to have column with just the difference between two-party
# vote share. Negative values are Republican win, positive values are
# Democratic win, win indicates winner of popular vote.
pv2p_diff_df <- popvote %>%
  select(year, party, pv2p) %>%
  pivot_wider(names_from = party, values_from = pv2p) %>%
  mutate(diff = (democrat - republican)) %>%
  mutate(win = case_when(diff > 0 ~ "democrat",
                         TRUE ~ "republican"))

# Plot differences in two-party popular vote share 
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

#### Plot 2 - States map with percentages of popular vote share

# mutate to add win margin, positive is democratic win, negative republican win
pv_margins_map <- pvstate %>%
  filter(year >= 2000) %>%
  mutate(win_margin = (D_pv2p-R_pv2p))

# filter for just most recent presidential election
pv_margins_map_16 <- pvstate %>%
  filter(year == 2016) %>%
  mutate(win_margin = (D_pv2p-R_pv2p))

# Plot 2016 win margin map, adjust scale limits to include color for Wyoming.
# Chose a purple mid scale as I feel like the white implies emptiness.
plot_usmap(data = pv_margins_map_16, regions = "states", values = "win_margin") +
  scale_fill_gradient2(
    high = "blue", 
    mid = scales::muted("purple"),
    low = "red", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-52,50),
    name = "Win margin"
  ) +
  theme_void() + 
  labs(title = "2016 Presidential Popular Vote Share Win Margin",
       subtitle = "2-party popular vote share",
       caption = "Win margin is difference between Democratic and Republican 
                  two-party popular vote share in each state.") + 
  theme(plot.title = element_text(size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 12, hjust = 0.5))

ggsave("figures/win_margin16.png")

# grid map of win_margins from 1980-2016 elections
plot_usmap(
  data = pv_margins_map,
  regions = "states",
  values = "win_margin",
  color = "white"
) +
  facet_wrap(facets = year ~ .) + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue", 
    mid = scales::muted("purple"),
    low = "red", 
    breaks = c(-50,-25,0,25,50), 
    limits = c(-55,60),
    name = "win margin")

#### Plot actual winners, mostly code from section 

# add winners to state popular vote data, use 2000 and higher because that is
# what I have done so far for swing state data
pv_map_grid <- pvstate %>%
  filter(year >= 1980) %>%
  mutate(winner = ifelse(R > D, "Republican", "Democrat"))
  
# Plot with facet wrap by year to show historical trends
plot_usmap(data = pv_map_grid, regions = "states", 
           values = "winner", color = "white") +
  facet_wrap(facets = year ~.) + 
  scale_fill_manual(values = c("blue", "red"), name = "PV winner") +
  theme_void() +
  theme(strip.text = element_text(size = 12),
        aspect.ratio=1) + 
  labs(title = "Presidential Popular Vote Winner from 1980-2016") + 
  theme(plot.title = element_text(size = 12, hjust = 0.5, vjust = 5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, vjust = 5))

ggsave("figures/historical_pv_win.png")

#### Extension 3 - Swing states over time

# Create 'swing' value, which is D_pv2p(y) - D_pv2p(y-4). Positive value is
# swing democratic from previous election, negative value is swing republican
# from previous election.
D_swingstate_margin <- pvstate %>%
  filter(year >= 1980) %>%
  select(state, year, D_pv2p) %>%
  pivot_wider(names_from = year, values_from = D_pv2p) %>%
  mutate(`2016` = (`2016` - `2012`),
         `2012` = (`2012` - `2008`),
         `2008` = (`2008` - `2004`),
         `2004` = (`2004` - `2000`),
         `2000` = (`2000` - `1996`)) %>%
  select(state, `2000`, `2004`, `2008`, `2012`, `2016`) %>%
  pivot_longer(cols = c(`2000`, `2004`, `2008`, `2012`, `2016`),
               names_to = "year",
               values_to = "swing")

# Summary of data about swing values from 2000-2016. Two standard deviations
# away from the mean is -10.52 and 8.24
swing_skim <- skim(D_swingstate_margin) %>%
  yank("numeric") %>%
  select(skim_variable, mean, sd, p0, p25, p50, p75, p100, hist) %>%
  gt() %>%
  fmt_number(columns = vars(mean, sd, p0, p25, p50, p75, p100), 
             decimals = 3) %>%
  cols_label(skim_variable = "variable") %>%
  tab_source_note("values rounded to 3 decimal places")

# save skim data as an image
swing_skim %>% gtsave("figures/gt_swing.png")

# grid map for 2000-2016 showing swing in popular vote from previous election
plot_usmap(
  data = D_swingstate_margin,
  regions = "states",
  values = "swing",
  color = "black"
) +
  facet_wrap(facets = year ~ .) + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue", 
    mid = "white", 
    # mid = scales::muted("purple"),
    low = "red", 
    breaks = c(-10,0,10,20), 
    limits = c(-15,20),
    name = "Swing") + 
  labs(title = "Swing Margins between Presidential Elections from 2000-2016",
       subtitle = "Two-party popular vote share",
       caption = "Swing is the difference in 2-party popular vote share 
       from the previous election.") + 
  theme(plot.title = element_text(size = 12, hjust = 0.5, vjust = 5),
        plot.subtitle = element_text(size = 10, hjust = 0.5, vjust = 5))

ggsave("figures/historical_swing.png")

# states with popular vote margin between 48-52 in 2016
small_margin_pv2p <- pv_margins_map %>%
  filter(win_margin >= -2 & win_margin <= 2) 

# Edit D_swing state_margin year column type to left_join with small margin state
# win data frame
D_swingstate_margin$year <- as.double(D_swingstate_margin$year)

# Left join to keep only states in which 2 party pop vote share was between
# 48-52, but add margin. Could have done this with a mutate but oh well. 
small_margin_pv2p16 <- small_margin_pv2p %>%
  left_join(D_swingstate_margin) %>%
  filter(year == 2016) %>%
  select(state, swing)

# Plot map showing swing margin for states in which two party popular vote share
# was won with less than a 2% margin. Annotate for states Clinton won despite
# swing right in 2016 election compared to 2012 election.
plot_usmap(
  data = small_margin_pv2p16,
  regions = "states",
  include = c("MI", "FL", "NH", "PA", "WI", "MN"),
  values = "swing",
  color = "grey",
  labels = TRUE,
  label_color = "black"
) + 
  theme_void() +
  scale_fill_gradient2(
    high = "blue", 
    mid = "white", 
    # mid = scales::muted("purple"),
    low = "red", 
    breaks = c(-5,0,5), 
    limits = c(-5,5),
    name = "Swing") + 
  labs(title = "2016 States Won by a Margin <2%",
       subtitle = "Swing in comparison to 2012 Presidential Election",
       caption = "Swing is the difference in 2-party popular vote share 
       from the previous election (2012).") + 
  theme(plot.title = element_text(size = 15, hjust = 0.5),
        plot.subtitle = element_text(size = 13, hjust = 0.5)) + 
  geom_text(x = 2150000, y = 100000, label = "NH - Clinton win", size = 2.5, 
            color = "blue", fontface = "plain") + 
  geom_text(x = 420000, y = -240000, label = "MN - Clinton win", size = 2.5, 
            color = "blue", fontface = "plain")

ggsave("figures/swing_state_margins16.png")

# Look at states that are typically closely contested. Define swing states.
# https://www-washingtonpost-com.ezp-prod1.hul.harvard.edu/graphics/politics/2016-election/swing-state-margins/


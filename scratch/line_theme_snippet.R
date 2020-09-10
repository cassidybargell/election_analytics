library(tidyverse)
library(ggplot2)
library(usmap)

popvote_df <- read_csv("data/popvote_1948-2016.csv")

my_line_theme <- theme_bw() + 
  theme(panel.border = element_blank(),
    plot.title   = element_text(size = 15, hjust = 0.5), 
    axis.text.x  = element_text(angle = 45, hjust = 1),
    axis.text    = element_text(size = 12),
    strip.text   = element_text(size = 18),
    axis.line    = element_line(colour = "black"),
    legend.position = "top",
    legend.text = element_text(size = 12))

ggplot(popvote_df, aes(x = year, y = pv2p, colour = party)) +
  geom_line(stat = "identity") +
  scale_color_manual(values = c("blue", "red"), name = "") +
  xlab("") + ## no need to label an obvious axis
  ylab("popular vote %") +
  ggtitle("Presidential Vote Share (1948-2016)") + 
  scale_x_continuous(breaks = seq(from = 1948, to = 2016, by = 4)) + 
  my_line_theme

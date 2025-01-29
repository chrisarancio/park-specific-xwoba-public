library(dplyr)

data <- read.csv("raw-data/statcast2024.csv")

filtered_df <- data %>%
  filter(description == "hit_into_play")

selected_df <- filtered_df %>% 
  select(game_date, batter, home_team, events, launch_speed, launch_angle)
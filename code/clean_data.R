library(dplyr)
library(tidyr)

data <- read.csv("raw-data/statcast2024.csv")

## add a column for batted balls 'ball_in_play'
## add a column for total bases
df <- data %>%
  mutate(ball_in_play = case_when(
    description == "hit_into_play" ~ 1,
    TRUE ~ 0
  )) %>%
  mutate(total_bases = case_when(
    events == 'single' ~ 1,
    events == 'double' ~ 2,
    events == 'triple' ~ 3,
    events == 'home_run' ~ 4,
    TRUE ~ 0
  ))

## get only batted balls for training
df_bip <- df %>%
  filter(description == "hit_into_play") %>%
  drop_na(launch_speed, launch_angle, ball_in_play) %>%
  select(game_date, batter, home_team, events, launch_speed, launch_angle, 
         woba_value, ball_in_play, total_bases)
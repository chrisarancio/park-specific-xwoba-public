library(dplyr)
library(tidyr)
library(glue)

park <- "BOS"

data_filename <- glue("./data/new_parks/raw_data/{park}_statcast_all.rds")
data <- readRDS(data_filename)
data <- as_tibble(data)

# Make sure that we are only considering data within the regular season
data <- data |>
  filter(game_type == "R") |>
  filter(home_team == park)

## add a column for batted balls 'ball_in_play'
## add a column for total bases
df <- data |>
  filter(events != "")

df <- df |>
  mutate(total_bases = case_when(
    events == 'single' ~ 1,
    events == 'double' ~ 2,
    events == 'triple' ~ 3,
    events == 'home_run' ~ 4,
    TRUE ~ 0
  ))

#Creating a woba column with the values for the 2024 season
df <- df |>
  mutate(woba = case_when(
    events == 'walk' ~ 0.689,
    events == 'hit_by_pitch' ~ 0.720,
    events == 'single' ~ 0.882,
    events == 'double' ~ 1.254,
    events == 'triple' ~ 1.590,
    events == 'home_run' ~ 2.050,
    TRUE ~ 0))

#Saving the cleaned data before we remove all of the events where launch_speed > 0
#Makes sure that the walk and strikeout data is included in final xwOBA calculation
final_df_file = glue("./data/new_parks/clean_data/{park}_statcast_cleaned_all_events.rds")
saveRDS(df, final_df_file)

#Select only the columns we need
df_bip <- df |>
  filter(launch_speed > 0) |>
  select(game_date, batter, player_name, home_team, events, launch_speed, launch_angle, 
         woba, description, events, total_bases) |>
  drop_na()

bip_file = glue("./data/new_parks/clean_data/{park}_statcast_cleaned.rds")
saveRDS(df_bip, bip_file)

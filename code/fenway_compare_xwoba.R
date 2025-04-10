library(dplyr)
library(ggplot2)

#----------- COMPARING TO OFFICIAL MLB VALUES
# Per Baseball Savant: "* Qualifiers: 2.1 PA per team game for batters, 1.25 PA per team game for pitchers."
# URL: https://baseballsavant.mlb.com/leaderboard/expected_statistics 
parks <- list.files("./data/parks/xwoba", full.names = TRUE)
official_xwOBA_values <- readRDS("./data/mlb_xwoba_2024_with_teams.rds")
knn_xwOBA_values <- readRDS("./data/knn_xwoba_vs_mlb.rds")

knn_xwOBA_values <- knn_xwOBA_values |>
  rename(knn_xwOBA = xwOBA) |>
  select(player_id, knn_xwOBA)

parks_and_mlb_xwoba <- official_xwOBA_values |>
  rename(player_id = `xMLBAMID`, official_xwOBA = xwOBA, player_name = PlayerName) |>
  inner_join(knn_xwOBA_values, join_by(`player_id` == `player_id`))

park_data <- readRDS("./data/fenway_xwoba.rds")
parks_and_mlb_xwoba <- parks_and_mlb_xwoba |>
  inner_join(park_data, join_by(`player_id` == `batter`))


#saveRDS(parks_and_mlb_xwoba, "./data/parks_and_mlb_xwoba.rds")

## new (n = 46185)
new_BOS_xwoba_pitch <- readRDS("./data/new_parks/xwoba/BOS_xwoba_pitch.rds") |> 
  drop_na(launch_speed, launch_angle, xwOBACON)
ggplot(new_BOS_xwoba_pitch, aes(x = launch_speed, y = launch_angle, fill = xwOBACON)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 1)

## old 
old_BOS_xwoba_pitch <- readRDS("./data/old_parks/BOS_xwoba_pitch.rds") |> 
  drop_na(launch_speed, launch_angle, xwOBACON)
ggplot(old_BOS_xwoba_pitch, aes(x = launch_speed, y = launch_angle, fill = xwOBACON)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 1)

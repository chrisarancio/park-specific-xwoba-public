library(dplyr)

#----------- COMPARING TO OFFICIAL MLB VALUES
# Per Baseball Savant: "* Qualifiers: 2.1 PA per team game for batters, 1.25 PA per team game for pitchers."
# URL: https://baseballsavant.mlb.com/leaderboard/expected_statistics 
parks <- list.files("./data/parks/xwoba", full.names = TRUE)
official_xwOBA_values <- readRDS("./data/mlb_xwoba_2024.rds")
knn_xwOBA_values <- readRDS("./data/knn_xwoba_vs_mlb.rds")

knn_xwOBA_values <- knn_xwOBA_values |>
  rename(knn_xwOBA = xwOBA) |>
  select(player_id, knn_xwOBA)

parks_and_mlb_xwoba <- official_xwOBA_values |>
  rename(player_id = `xMLBAMID`, official_xwOBA = xwOBA, player_name = PlayerName) |>
  inner_join(knn_xwOBA_values, join_by(`player_id` == `player_id`))

for (park in parks) {
  park_data <- readRDS(park)
  parks_and_mlb_xwoba <- parks_and_mlb_xwoba |>
    inner_join(park_data, join_by(`player_id` == `batter`))
}

saveRDS(parks_and_mlb_xwoba, "./data/parks_and_mlb_xwoba.rds")
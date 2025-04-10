library(dplyr)
library(ggplot2)

#----------- COMPARING TO OFFICIAL MLB VALUES
# Per Baseball Savant: "* Qualifiers: 2.1 PA per team game for batters, 1.25 PA per team game for pitchers."
# URL: https://baseballsavant.mlb.com/leaderboard/expected_statistics 
parks <- c("BOS", "BAL", "COL", "HOU", "LAD", "NYM", "NYY", "PHI", "SEA", "SF")
official_xwOBA_values <- readRDS("./data/mlb_xwoba_2024_with_teams.rds")
knn_xwOBA_values <- readRDS("./data/knn_xwoba_vs_mlb.rds")

knn_xwOBA_values <- knn_xwOBA_values |>
  rename(knn_xwOBA = xwOBA) |>
  select(player_id, knn_xwOBA)

parks_and_mlb_xwoba <- official_xwOBA_values |>
  rename(player_id = `xMLBAMID`, official_xwOBA = xwOBA, player_name = PlayerName) |>
  inner_join(knn_xwOBA_values, join_by(`player_id` == `player_id`))

home_diff_df <- data.frame()

for (park in parks) {
  ## create dataframe of all park xwobas for batters
  park_file <- glue("./data/new_parks/xwoba/{park}_xwoba_batter.rds")
  park_data <- readRDS(park_file)
  parks_and_mlb_xwoba <- parks_and_mlb_xwoba |>
    inner_join(park_data, join_by(`player_id` == `batter`))
  
  ## calculate difference between official xwoba and player's home park xwoba
  home_park_xwoba <- paste0(park, "_xwOBA")
  filtered <- parks_and_mlb_xwoba |>
    filter(team_name == park) |>
    select(player_id, team_name, player_name, official_xwOBA, all_of(home_park_xwoba)) |>
    rename(home_xwOBA = all_of(home_park_xwoba)) 
  
  filtered$home_diff <- filtered$home_xwOBA - filtered$official_xwOBA
  home_diff_df <- bind_rows(home_diff_df, filtered)
}

saveRDS(parks_and_mlb_xwoba, "./data/new_parks/new_parks_and_mlb_xwoba.rds")

home_diff_df <- home_diff_df |>
  mutate(
    value_color = ifelse(home_diff > 0, "Positive", "Negative")
  )

# median_official_xwOBA <- median(home_diff_df$official_xwOBA)
# median_home_xwOBA <- median(home_diff_df$home_xwOBA)
# 
# ggplot(home_diff_df, aes(x = official_xwOBA, y = home_xwOBA)) +
#   geom_point(aes(color = value_color)) +
#   geom_vline(xintercept = median_official_xwOBA, linetype = "dashed", color = "black") +
#   geom_hline(yintercept = median_home_xwOBA, linetype = "dashed", color = "black") +
#   geom_abline(slope = 1, intercept = 0, linetype = "solid", color = "blue") +
#   theme(legend.position = "none") +
#   labs(
#     title = "Official xwOBA vs Home xwOBA",
#     x = "Official xwOBA",
#     y = "Home xwOBA"  
#     )



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

for (park in parks) {
  park_data <- readRDS(park)
  parks_and_mlb_xwoba <- parks_and_mlb_xwoba |>
    inner_join(park_data, join_by(`player_id` == `batter`))
}

#saveRDS(parks_and_mlb_xwoba, "./data/parks_and_mlb_xwoba.rds")

parks <- c("BOS", "BAL", "COL", "HOU", "LAD", "NYM", "NYY", "PHI", "SEA", "SF")

home_diff_df <- data.frame()
for (park in parks) {
  home_park_xwoba <- paste0(park, "_xwOBA")
  filtered <- parks_and_mlb_xwoba |>
    filter(team_name == park) |>
    select(player_id, team_name, player_name, official_xwOBA, all_of(home_park_xwoba)) |>
    rename(home_xwOBA = all_of(home_park_xwoba)) 
  
  filtered$home_diff <- filtered$home_xwOBA - filtered$official_xwOBA
  home_diff_df <- bind_rows(home_diff_df, filtered)
}

home_diff_df <- home_diff_df |>
  mutate(
    value_color = ifelse(home_diff > 0, "Positive", "Negative")
  )

median_official_xwOBA <- median(home_diff_df$official_xwOBA)
median_home_xwOBA <- median(home_diff_df$home_xwOBA)

# Create the scatter plot
ggplot(home_diff_df, aes(x = official_xwOBA, y = home_xwOBA)) +
  geom_point(aes(color = value_color)) +
  geom_vline(xintercept = median_official_xwOBA, linetype = "dashed", color = "black") +
  geom_hline(yintercept = median_home_xwOBA, linetype = "dashed", color = "black") +
  geom_abline(slope = 1, intercept = 0, linetype = "solid", color = "blue") +
  theme(legend.position = "none") +
  labs(
    title = "Official xwOBA vs Home xwOBA",
    x = "Official xwOBA",
    y = "Home xwOBA"  
    )



library(dplyr)
library(glue)
library(tidyr)
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
  
  ## calculate difference between official xwoba and all parks 
  park_column <- paste0(park, "_xwOBA")
  diff_column <- paste0(park, "_diff")
  parks_and_mlb_xwoba[[diff_column]] <- parks_and_mlb_xwoba[[park_column]] - parks_and_mlb_xwoba$official_xwOBA
  
}

# saveRDS(parks_and_mlb_xwoba, "./data/new_parks/new_parks_and_mlb_xwoba.rds")


#----------- COMPARING MLB XWOBA TO PARK XWOBAS AND GRAPHS
home_diff_df <- home_diff_df |>
  mutate(
    value_color = ifelse(home_diff > 0, "Positive", "Negative")
  )

# convert to long df for graphing simplicity
player_df <- parks_and_mlb_xwoba |>
  pivot_longer(cols = ends_with("_diff"), names_to = "park", values_to = "diff") |>
  mutate(park = sub("_diff$", "", park)) |>
  select(player_id, player_name, park, diff)

# calculate average xwOBA increase/decrease per park
park_avg_df <- parks_and_mlb_xwoba |>
  select(ends_with("_diff")) |>
  summarize(across(everything(), \(x) mean(x, na.rm = TRUE))) |>
  pivot_longer(cols = everything(), names_to = "park", values_to = "avg_diff") |>
  mutate(park = sub("_diff$", "", park))

# select one player to test (this will eventually be in shiny)
player <- player_df |> filter(player_id == 660271)

# first plot just for player differences at each park
ggplot(player, aes(x = park, y = diff, fill = diff > 0)) +
  geom_bar(stat = "identity") +
  scale_fill_manual(values = c("red", "blue"), 
                    labels = c("Negative", "Positive")) + 
  labs(title = paste("Park xwOBA Differences for", player$player_name[1]),
       x = "Park",
       y = "Park xwOBA vs MLB xwOBA") +
  theme_minimal() +
  theme(legend.position = "none")

# combine park averages and player data
combined_df <- bind_rows(
  player |> mutate(type = "Player", value = diff),
  park_avg_df |> mutate(type = "Average", value = avg_diff)
)

# second chart that includes the avg park increase/decrease of xwOBA
ggplot(combined_df, aes(x = park, y = value, fill = type)) +
  geom_bar(stat = "identity", position = position_dodge(), alpha = 0.8) +
  scale_fill_manual(name = NULL, values = c("Player" = "blue", "Average" = "gray")) +
  labs(title = paste("Park Differential for", combined_df$player_name[1]),
       x = "Park",
       y = "Park xwOBA vs MLB xwOBA Difference") +
  theme_minimal() +
  theme(legend.position = "bottom")

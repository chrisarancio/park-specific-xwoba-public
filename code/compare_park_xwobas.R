library(dplyr)
library(glue)
library(tidyr)
library(ggplot2)

#----------- COMPARING TO OFFICIAL MLB VALUES
# Per Baseball Savant: "* Qualifiers: 2.1 PA per team game for batters, 1.25 PA per team game for pitchers."
# URL: https://baseballsavant.mlb.com/leaderboard/expected_statistics 
parks <- c("BOS", "BAL", "COL", "HOU", "LAD", "NYM", "NYY", "PHI", "SEA", "SF")
official_xwOBA_values <- readRDS("./data/mlb_xwoba_2015_2024.rds")
knn_xwOBA_values <- readRDS("./data/knn_xwoba_vs_mlb.rds")

knn_xwOBA_values <- knn_xwOBA_values |>
  rename(knn_xwOBA = xwOBA) |>
  select(player_id, knn_xwOBA)

parks_and_mlb_xwoba <- official_xwOBA_values |>
  rename(player_id = `batter`) |>
  inner_join(knn_xwOBA_values, join_by(`player_id` == `player_id`))


for (park in parks) {
  ## create dataframe of all park xwobas for batters
  park_file <- glue("./data/new_parks/xwoba/{park}_xwoba_batter.rds")
  park_data <- readRDS(park_file)
  parks_and_mlb_xwoba <- parks_and_mlb_xwoba |>
    inner_join(park_data, join_by(`player_id` == `batter`))
  
  for (year in c(2015:2019, 2021:2024)) {
    ## calculate difference between official xwoba and all parks 
    park_column <- paste0(park, "_xwOBA_", year)
    mlb_column <- paste0("MLB_xwOBA_", year)
    diff_column <- paste0(park, "_diff_", year)
    parks_and_mlb_xwoba[[diff_column]] <- parks_and_mlb_xwoba[[park_column]] - parks_and_mlb_xwoba[[mlb_column]]
  }
}

# saveRDS(parks_and_mlb_xwoba, "./data/new_parks/new_parks_and_mlb_xwoba.rds")


#----------- COMPARING MLB XWOBA TO PARK XWOBAS AND GRAPHS

# convert to long df for graphing simplicity
player_df <- parks_and_mlb_xwoba |>
  pivot_longer(cols = contains("_diff_"), names_to = "column_name", values_to = "diff") |>
  mutate(
    park = sub("_diff_.*$", "", column_name),
    year = as.numeric(sub(".*_diff_", "", column_name))
  ) |>
  select(player_id, player_name, park, year, diff)

# calculate average xwOBA increase/decrease at each park for each season
park_avg_df <- parks_and_mlb_xwoba |>
  select(contains("_diff_")) |>
  summarize(across(everything(), \(x) mean(x, na.rm = TRUE))) |>
  pivot_longer(cols = everything(), names_to = "column_name", values_to = "avg_diff") |>
  mutate(
    parts = strsplit(column_name, "_diff_"),
    park = sapply(parts, `[`, 1),
    year = as.numeric(sapply(parts, `[`, 2))
  ) |>
  select(-column_name, -parts)

# combine park averages and player data
combined_df <- bind_rows(
  player_df |> mutate(type = "Player", value = diff),
  park_avg_df |> mutate(type = "Average", value = avg_diff)
) |>
  select(player_id, player_name, park, year, type, value) |>
  filter(!is.na(value))

# select one player and year to graph (this will eventually be in shiny)
player <- combined_df |> filter(year == 2022, player_id == 547180 | is.na(player_id))

# second chart that includes the avg park increase/decrease of xwOBA
ggplot(player, aes(x = park, y = value, fill = type)) +
  geom_bar(stat = "identity", position = position_dodge(), alpha = 0.8) +
  scale_fill_manual(name = NULL, values = c("Player" = "blue", "Average" = "gray")) +
  labs(title = paste("Park Differential for", player$year[1], player$player_name[1]),
       x = "Park",
       y = "Park xwOBA vs MLB xwOBA Difference") +
  theme_minimal() +
  theme(legend.position = "bottom")

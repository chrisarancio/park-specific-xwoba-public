library(baseballr)
library(dplyr)

# get data from FanGraphs using baseballr function
fg_data <- fg_batter_leaders(startseason = 2024, endseason = 2024)

# grab season player name and xwOBA columns -- 1454 players
cleaned_fg_data <- fg_data |>
  select(xMLBAMID, PlayerName, xwOBA)

saveRDS(cleaned_fg_data, "./data/mlb_xwoba_2024.rds")
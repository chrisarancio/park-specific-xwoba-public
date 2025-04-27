library(baseballr)
library(dplyr)
library(tidyr)

# get data from FanGraphs using baseballr function
df <- data.frame()
for (year in 2015:2024) {
  fg_data <- fg_batter_leaders(startseason = year, endseason = year)
  
  cleaned_fg_data <- fg_data |>
    filter(PA > 300) |>
    select(season = Season, 
           batter = xMLBAMID, 
           team_name, 
           player_name = PlayerName, 
           MLB_xwOBA = xwOBA)
  
  df <- bind_rows(df, cleaned_fg_data)
}

wide_df <- df |>
  pivot_wider(
    id_cols = c(batter, player_name),
    names_from = season,
    values_from = MLB_xwOBA,
    names_prefix = "MLB_xwOBA_"
  )
  
saveRDS(wide_df, "./data/mlb_xwoba_2015_2024.rds")





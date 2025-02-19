library(dplyr)
library(ggplot2)

# get knn xwoba and MLB official xwoba
knn_xwoba <- readRDS("./data/final_df.rds")
mlb_xwoba <- readRDS("./data/mlb_xwoba_2024.rds")

# group the data by each player at each ballpark
grouped_player_park <- knn_xwoba |>
  group_by(batter, home_team) |>
  summarize(player_name = first(player_name),
            pitches = n(),
            xwOBA = mean(xwOBA), 
            woba = mean(woba), 
            .groups = "keep")

# inner join with the MLB official xwoba data
park_specific_xwOBA <- grouped_player_park |>
  inner_join(xwOBA_data, by = c("batter" = "xMLBAMID")) |>
  select(batter_id = batter, 
         player_name, 
         park = home_team,
         park_pitches = pitches,
         park_xwOBA = xwOBA.x, 
         park_wOBA = woba, 
         mlb_xwOBA = xwOBA.y)

# sort first by park, then by xwOBA at that park descending to see best at each park
park_specific_xwOBA_sorted <- joined |>
  arrange(park, desc(park_xwOBA))

# ---------------------------------------------
# some sample size issues with just one season
summary(park_specific_xwOBA$park_pitches)
ggplot(park_specific_xwOBA, aes(x = park_pitches)) +
  geom_histogram(bins = 14, fill = "blue", color = "black") +
  labs(title = "Park-Specific xwOBA Sample Size Distribution", x = "pitches", y = "count")
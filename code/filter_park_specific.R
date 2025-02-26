library(dplyr)
library(glue)

# get knn xwoba and MLB official xwoba
statcast2024_cleaned <- readRDS("./data/statcast2024_cleaned.rds")

# start with just a few parks, either interesting park or big market team
parks <- c("BOS", "BAL", "COL", "HOU", "LAD", "NYM", "NYY", "PHI", "SEA", "SF")

filterPark <- function(knn_xwoba, park) {
  park_filtered_statcast <- statcast2024_cleaned %>% filter(home_team == park)
  filename <- glue("./data/parks/data/{park}_statcast2024_cleaned.rds")
  saveRDS(park_filtered_statcast, filename)
}

for (park in parks) {
  filterPark(knn_xwoba, park)
}
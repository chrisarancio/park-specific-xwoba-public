library(baseballr)
library(tidyverse)

stadium_id <- 3
all_res <- statcast_search("2015-04-13", "2015-04-14", player_type = 'batter', stadium = stadium_id)
next_date <- as.Date("2015-04-15")
while (next_date <= "2024-09-30") {
  if(weekly){
    next_res <- statcast_search(next_date, next_date+7, player_type = 'batter', stadium = stadium_id)
  } else {
    next_res <- statcast_search(next_date, next_date, player_type = 'batter', stadium = stadium_id)
  }
  if (nrow(next_res) > 0) {
    all_res <- all_res |> bind_rows(next_res)
  }
  if(next_date + 7 >= "2024-09-30"){
    cat("Downloading data for", as.character(next_date), "\n")
    next_date <- next_date + 1
    weekly = FALSE
  } else {
    cat("Downloading data for", as.character(next_date), as.character(next_date+7), "\n")
    next_date <- next_date + 7
  }
  Sys.sleep(rexp(3))
}

# Check that all dates downloaded successfully; filter out spring training
table(all_res$game_type)
all_res <- all_res |>
  filter(game_type != "S")

# saveRDS(all_res, "./Data/fenway_statcast_all.rds")

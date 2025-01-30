library(baseballr)
library(tidyverse)

all_res <- statcast_search("2024-03-28", "2024-03-29", player_type = 'batter') # Regular season from March 28th - Sept 30th
weekly = TRUE
next_date <- as.Date("2024-03-30")
while (next_date <= "2024-09-30") {
  if(weekly) {
    next_res <- statcast_search(next_date, next_date+6, player_type = 'batter')
  } else {
    next_res <- statcast_search(next_date, next_date, player_type = 'batter')
  }
  if (nrow(next_res) > 0) {
    all_res <- all_res |> bind_rows(next_res)
  }
  if(next_date + 6 >= as.Date("2024-09-30")) {
    cat("Downloading data for", as.character(next_date), "\n")
    next_date <- next_date + 1
    weekly = FALSE
  } else {
    cat("Downloading data for", as.character(next_date), as.character(next_date+6), "\n")
    next_date <- next_date + 6
  }
  Sys.sleep(rexp(3))
}

# Check that all dates downloaded successfully; filter out spring training
table(all_res$game_type)
all_res <- all_res |>
  filter(game_type != "S") %>%
  distinct()

saveRDS(all_res, "raw-data/statcast2024.rds")

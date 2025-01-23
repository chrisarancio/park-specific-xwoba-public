library(baseballr)
library(tidyverse)

all_res <- statcast_search("2024-03-20", "2024-03-21") # Seoul series
next_date <- as.Date("2024-03-28")
while (next_date <= "2024-10-30") {
  cat("Downloading data for", as.character(next_date), "\n")
  next_res <- statcast_search(next_date, next_date)
  if (nrow(next_res) > 0) {
    all_res <- all_res |> bind_rows(next_res)
  }
  next_date <- next_date + 1
  Sys.sleep(rexp(3))
}

# Check that all dates downloaded successfully; filter out spring training
table(all_res$game_type)
all_res <- all_res |>
  filter(game_type != "S")

saveRDS(all_res, "./Data/statcast2024.rds")

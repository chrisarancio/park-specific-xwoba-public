library(tidyverse)
library(tidymodels)
library(kknn)
library(dplyr)
library(yardstick)
library(ggplot2)
library(glue)

#-----
parks <- c("BOS", "BAL", "COL", "HOU", "LAD", "NYM", "NYY", "PHI", "SEA", "SF")
#-----

for (park in parks) {
  #-----IMPORTING CLEANED DATA
  cleaned_data_park <- glue("./data/new_parks/clean_data/{park}_statcast_cleaned.rds")
  cleaned_data <- readRDS(cleaned_data_park)
  cleaned_data <- cleaned_data |>
    select(launch_speed,launch_angle,total_bases) |>
    mutate(total_bases = factor(total_bases))
  
  park_knn_model_file <- glue("./data/new_parks/knn_models/{park}_knn_model.rds")
  knn_model_xwoba_saved <- readRDS(park_knn_model_file)
  
  woba_coeffs <- read.csv("./data/woba.csv")
  
  prob_file <- glue("./data/new_parks/prob/{park}_total_bases_prob.rds")
  cleaned_data_predictions_prob <- readRDS(prob_file)
  
  park_cleaned_all_events <- glue("./data/new_parks/clean_data/{park}_statcast_cleaned_all_events.rds")
  final_df <- readRDS(park_cleaned_all_events)
  #-----
  
  for (year in 2015:2024) {
    #-------CALCULATING xwOBACON----------
    #Weights for 0,1,2,3,4 total bases for 2024 season
    woba_year_row <- woba_coeffs |>
      filter(Season == year)
    
    woba_year_weights <- c(0, woba_year_row$w1B, woba_year_row$w2B, woba_year_row$w3B, woba_year_row$wHR)
    
    total_bases_probs <- cleaned_data_predictions_prob[c('.pred_0','.pred_1','.pred_2','.pred_3','.pred_4')]
    
    calculate_xwOBACON <- function(x) {
      return(sum(x * woba_year_weights))
    }
    
    xwOBACON <- total_bases_probs |>
      mutate(xwOBACON = apply(X = total_bases_probs, MARGIN = 1, FUN = calculate_xwOBACON))
    #-------
    
    #----------CALCULATING xwOBA
    
    xwOBACON_w_LA_and_LS <- cbind(xwOBACON, cleaned_data$launch_angle, cleaned_data$launch_speed)
    
    xwOBACON <- xwOBACON_w_LA_and_LS |>
      select(`cleaned_data$launch_speed`, `cleaned_data$launch_angle`, xwOBACON) |>
      distinct()
    
    wBB <- woba_year_row$wBB[1]
    wHBP <- woba_year_row$wHBP[1]
    
    xwobacon_column_name <- glue(park, "_xwOBACON_", year)
    xwoba_column_name <- glue(park, "_xwOBA_", year)
    final_df <- final_df |>
      left_join(xwOBACON, by = c("launch_speed" = "cleaned_data$launch_speed",
                                 "launch_angle" = "cleaned_data$launch_angle")) |>
      mutate(!!sym(xwoba_column_name) := case_when(
        events == 'walk' ~ wBB,
        events == 'hit_by_pitch' ~ wHBP,
        events == 'strikeout' ~ 0,
        events == 'strikeout_double_play' ~ 0,
        TRUE ~ xwOBACON)) |>
      rename(!!sym(xwobacon_column_name) := xwOBACON)
  }
  park_xwoba_pitch_file <- glue("./data/new_parks/xwoba/{park}_xwoba_pitch.rds")
  saveRDS(final_df, park_xwoba_pitch_file)
  
  grouped_by_batter <- final_df |>
    group_by(batter) |>
    summarize(across(where(is.numeric), ~ mean(.x, na.rm = TRUE))) |>
    select(batter, starts_with(park))
  
  park_xwoba_batter_file <- glue("./data/new_parks/xwoba/{park}_xwoba_batter.rds")
  saveRDS(grouped_by_batter, park_xwoba_batter_file)
}


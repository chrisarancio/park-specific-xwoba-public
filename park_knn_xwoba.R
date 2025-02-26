#library(tidyverse)

library(tidymodels)
library(kknn)
library(dplyr)
library(yardstick)
library(ggplot2)

#-----CHANGE THE BALLPARK HERE 
park <- "BOS"
#-----

#-----IMPORTING CLEANED DATA
cleaned_data_park <- glue("./data/parks/data/{park}_statcast2024_cleaned.rds")
cleaned_data <- readRDS(cleaned_data_park)
cleaned_data <- cleaned_data |>
  select(launch_speed,launch_angle,total_bases) |>
  mutate(total_bases = as.factor(total_bases))
#-----

#-----DEFINING KNN WORKFLOW WITH TIDYMODELS
# Model spec
knn_spec <- nearest_neighbor() |>
  set_mode("classification") |>
  set_engine(engine = "kknn") |>
  set_args(neighbors = tune())

#Variable spec
variable_recipe <- recipe(total_bases ~ launch_speed + launch_angle, data = cleaned_data) |>
  step_normalize(all_numeric_predictors())

#Workflow spec (model + recipe)
knn_workflow <- workflow() |>
  add_recipe(variable_recipe) |>
  add_model(knn_spec)
#------

#-----TUNING K-PARAMETER WITH CROSS-VALIDATION
# Using knn_workflow each time, build 20 knn models using a range of K tuning parameters from 1 to 40.
# Evaluate each model using 2-fold cross validation based on roc_auc metric
set.seed(253)
knn_models <- knn_workflow |>
  tune_grid(
    grid = grid_regular(neighbors(range = c(1,200)), levels = 20),
    resamples = vfold_cv(cleaned_data, v = 2),
    metrics = metric_set(accuracy)
  )

# Comparing knn models and choosing which one to use
knn_models |>
  collect_metrics()

# Plotting the different models
knn_models |>
  autoplot()

# Finding the best k
best_k <- knn_models |>
  select_best(metric = "accuracy")
best_k

# Getting accuracy for the model with the best k-value
knn_models |>
  collect_metrics() |>
  filter(neighbors == best_k$neighbors)

#------FINALIZE AND SAVE FITTED MODEL
final_knn <- knn_workflow |>
  finalize_workflow(parameters = best_k) |>
  fit(data = cleaned_data)

park_knn_model_file <- glue("./data/parks/knn/{park}_knn_model.rds")
saveRDS(final_knn, park_knn_model_file)
knn_model_xwoba_saved <- readRDS(park_knn_model_file)
#------

#------PREDICT TOTAL BASES PROBABILITIES USING FITTED MODEL
cleaned_data_predictions_prob <- knn_model_xwoba_saved |>
  predict(new_data = cleaned_data, type = "prob")

#------TESTING ACCURACY---------
comparison <- cbind(cleaned_data$total_bases, cleaned_data_predictions_prob)
comparison_best_results <- comparison |>
  mutate(best_prediction = case_when(
    .pred_0 == pmax(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4) ~ 0,
    .pred_1 == pmax(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4) ~ 1,
    .pred_2 == pmax(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4) ~ 2,
    .pred_3 == pmax(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4) ~ 3,
    .pred_4 == pmax(.pred_0, .pred_1, .pred_2, .pred_3, .pred_4) ~ 4
  ))

test_accuracy <- comparison_best_results |>
  mutate(match = case_when(
    `cleaned_data$total_bases` == best_prediction ~ 1,
    TRUE ~ 0
  ))

amount_correctly_predicted <- test_accuracy |>
  count(match == 1)
amount_correctly_predicted_percentage <- (amount_correctly_predicted$n[2] / (amount_correctly_predicted$n[1] + amount_correctly_predicted$n[2])) * 100
#------------

#-------CALCULATING xwOBACON----------
#Weights for 0,1,2,3,4 total bases for 2024 season
woba_2024_weights <- c(0, 0.882, 1.254, 1.590, 2.050)
total_bases_probs <- cleaned_data_predictions_prob[c('.pred_0','.pred_1','.pred_2','.pred_3','.pred_4')]

calculate_xwOBACON <- function(x) {
  return(sum(x * woba_2024_weights))
}

xwOBACON <- total_bases_probs |>
  mutate(xwOBACON = apply(X = total_bases_probs, MARGIN = 1, FUN = calculate_xwOBACON))
#-------

#----------CALCULATING xwOBA
final_df <- readRDS("./data/statcast2024_cleaned_all_events.rds")

xwOBACON_w_LA_and_LS <- cbind(xwOBACON, cleaned_data$launch_angle, cleaned_data$launch_speed)

xwOBACON <- xwOBACON_w_LA_and_LS |>
  select(`cleaned_data$launch_speed`, `cleaned_data$launch_angle`, xwOBACON) |>
  distinct()

final_df <- final_df |>
  left_join(xwOBACON, by = c("launch_speed" = "cleaned_data$launch_speed",
                             "launch_angle" = "cleaned_data$launch_angle")) |>
  mutate(xwOBA = case_when(
    events == 'walk' ~ 0.689,
    events == 'hit_by_pitch' ~ 0.720,
    events == 'strikeout' ~ 0,
    events == 'strikeout_double_play' ~ 0,
    TRUE ~ xwOBACON))

cleaned_data_grouped_xwOBA <- final_df |>
  group_by(batter) |>
  summarize(!!paste0(park, "_xwOBA") := mean(xwOBA, na.rm = TRUE))

final_filename <- glue("./data/parks/xwoba/{park}_xwoba.rds")
saveRDS(cleaned_data_grouped_xwOBA, final_filename)

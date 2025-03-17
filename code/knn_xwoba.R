#library(tidyverse)

library(tidymodels)
library(kknn)
library(dplyr)
library(yardstick)
library(ggplot2)

#-----IMPORTING CLEANED DATA
cleaned_data <- readRDS("./data/statcast2024_cleaned.rds")
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

saveRDS(final_knn, "./data/best_knn_model.rds")
knn_model_xwoba_saved <- readRDS("./data/best_knn_model.rds")
#------

#------PREDICT TOTAL BASES PROBABILITIES USING FITTED MODEL
cleaned_data_predictions_prob <- knn_model_xwoba_saved |>
  predict(new_data = cleaned_data, type = "prob")

#cleaned_data_predictions_prob <- final_knn |>
#predict(new_data = cleaned_data, type = "prob")

#saveRDS(cleaned_data_predictions_prob, "/Users/chrisa/Documents/GitHub/park-specific-xwoba/data/cleaned_data_predictions_prob_knn.rds")
cleaned_data_predictions_prob <- readRDS("./data/cleaned_data_predictions_prob_knn.rds")

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

accuracy <- comparison_best_results |>
  mutate(match = case_when(
    `cleaned_data$total_bases` == best_prediction ~ 1,
    TRUE ~ 0
  ))

amount_correctly_predicted <- accuracy |>
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

#-------RECREATING STATCAST xwOBACON MODEL GRAPH FROM MEDIUM ARTICLE

#pass aggregate in every distinct combo of launch angle and exit velocity

#Recreating "Statcast xwOBACON Model" graph from xwOBA medium article
xwOBACON_graph <- cbind(xwOBACON, cleaned_data$launch_angle, cleaned_data$launch_speed)

#data.frame(LA = -10:50) |>
#  crossing(data.frame(EV = 50:90))

ggplot(xwOBACON_graph, aes(x = `cleaned_data$launch_speed`, y = `cleaned_data$launch_angle`, fill = xwOBACON)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 1)
#----------

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

#saveRDS(final_df, "./data/knn_xwOBA_ungrouped.rds")

cleaned_data_grouped_xwOBA <- final_df |>
  group_by(batter) |>
  #filter(n() > 100) |>
  #summarize(xwOBA = mean(xwOBA, na.rm = TRUE), woba = mean(woba, na.rm = TRUE))
#=======
  filter(n() > 100) |>
  summarize(xwOBA = mean(xwOBA), woba = mean(woba))
#>>>>>>> Stashed changes

#----------- COMPARING TO OFFICIAL MLB VALUES
# Per Baseball Savant: "* Qualifiers: 2.1 PA per team game for batters, 1.25 PA per team game for pitchers."
# URL: https://baseballsavant.mlb.com/leaderboard/expected_statistics 
official_xwOBA_values <- readRDS("./data/mlb_xwoba_2024.rds")

official_xwOBA_values <- official_xwOBA_values |>
  rename(player_id = `xMLBAMID`)

official_xwOBA_values_by_player <- official_xwOBA_values |>
  rename(official_xwoba = xwOBA)

official_xwOBA_values_by_player <- official_xwOBA_values_by_player |>
  select(player_id, official_xwoba)

cleaned_data_grouped_xwOBA_compare <- cleaned_data_grouped_xwOBA |>
  rename(player_id = `batter`)

cleaned_data_grouped_xwOBA_compare <- cleaned_data_grouped_xwOBA_compare |>
  select(player_id, xwOBA)

predicted_vs_official <- official_xwOBA_values_by_player |>
  inner_join(cleaned_data_grouped_xwOBA_compare, join_by(`player_id` == `player_id`))

saveRDS(predicted_vs_official, "./data/knn_xwoba_vs_mlb.rds")

#Plotting predicted xwOBA vs official MLB values
fit <- lm(data = predicted_vs_official, official_xwoba ~ xwOBA)
summary(fit)

predicted_vs_official_plot <- ggplot(data = predicted_vs_official, aes(x = official_xwoba, y = xwOBA)) + 
  geom_point() +
  stat_smooth(method = "lm", col = "red") +
  labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                     "Intercept =",signif(fit$coef[[1]],5 ),
                     " Slope =",signif(fit$coef[[2]], 5),
                     " P =",signif(summary(fit)$coef[2,4], 5)))
predicted_vs_official_plot

#print the exit velocity and launch angle of the outliers of the final graph 
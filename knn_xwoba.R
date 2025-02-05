library(tidyverse)
library(tidymodels)
library(kknn)
library(dplyr)
library(yardstick)
library(ggplot2)

cleaned_data <- readRDS("./Data/statcast2024_cleaned.rds")
cleaned_data <- cleaned_data |>
  #select('launch_speed','launch_angle','total_bases') |>
  mutate(total_bases = as.factor(total_bases))

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

# Using knn_workflow each time, build 20 knn models using a range of K tuning parameters from 1 to 40.
# Evaluate each model using 2-fold cross validation based on roc_auc metric
set.seed(253)
knn_models <- knn_workflow |>
  tune_grid(
    grid = grid_regular(neighbors(range = c(1,300)), levels = 30),
    resamples = vfold_cv(cleaned_data, v = 2),
    metrics = metric_set(yardstick::accuracy)
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

final_knn <- knn_workflow |>
  finalize_workflow(parameters = best_k) |>
  fit(data = cleaned_data)

cleaned_data_predictions_prob <- final_knn |>
  predict(new_data = cleaned_data, type = "prob")

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

#Saving the best KNN model
#saveRDS(final_knn, "/Users/chrisa/Desktop/best_knn_model_2_2_25.rds")

#saved_knn_model <- readRDS("/Users/chrisa/Desktop/best_knn_model_2_2_25.rds")
#cleaned_data_predictions_prob <- saved_knn_model |>
  #predict(new_data = cleaned_data, type = "prob")

#CALCULATING xwOBACON
#Weights for 0,1,2,3,4 total bases
woba_2024_weights <- c(0, 0.882, 1.254, 1.590, 2.050)
total_bases_probs <- cleaned_data_predictions_prob[c('.pred_0','.pred_1','.pred_2','.pred_3','.pred_4')]

calculate_xwOBACON <- function(x) {
  return(sum(x * woba_2024_weights))
}

xwOBACON <- total_bases_probs |>
  mutate(xwOBACON = apply(X = total_bases_probs, MARGIN = 1, FUN = calculate_xwOBACON))

#accuracy <- accuracy |>
#  mutate(xwOBACON = xwOBACON$xwOBACON)

cleaned_data <- cleaned_data |>
  mutate(xwOBACON_pred = xwOBACON$xwOBACON)

cleaned_data_test <- cleaned_data |>
  mutate(xwOBACON_pred = case_when(
    events == 'walk' ~ 0.689,
    events == 'hit_by_pitch' ~ 0.720,
    events == 'strikeout' ~ 0,
    events == 'strikeout_double_play' ~ 0,
    TRUE ~ xwOBACON_pred
  ))

cleaned_data_grouped_xwOBA <- cleaned_data_test |>
  group_by(player_name) |>
  filter(n() > 100) |>
  summarize(xwOBA_pred = mean(xwOBACON_pred), woba = mean(woba))

official_xwOBA_values <- read.csv("/Users/chrisa/Downloads/statcast_yty.csv")
official_xwOBA_values <- official_xwOBA_values |>
  rename(player_name = `last_name..first_name`) 

official_xwOBA_values <- official_xwOBA_values |>
  select(player_name, X2024)

cleaned_data_grouped_xwOBA_compare <- cleaned_data_grouped_xwOBA |>
  select(player_name, xwOBA_pred)
predicted_vs_official <- official_xwOBA_values |>
  inner_join(cleaned_data_grouped_xwOBA_compare, join_by(`player_name` == `player_name`))

#Plotting predicted xwOBA vs official MLB values
fit <- lm(data = predicted_vs_official, X2024 ~ xwOBA_pred)
summary(fit)
predicted_vs_official_plot <- ggplot(data = predicted_vs_official, aes(x = X2024, y = xwOBA_pred)) + 
  geom_point() +
  stat_smooth(method = "lm", col = "red") +
  labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                     "Intercept =",signif(fit$coef[[1]],5 ),
                     " Slope =",signif(fit$coef[[2]], 5),
                     " P =",signif(summary(fit)$coef[2,4], 5)))
predicted_vs_official_plot

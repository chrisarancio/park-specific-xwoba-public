library(tidyverse)
library(tidymodels)
library(rsample)
library(class)
library(kknn)

cleaned_data <- readRDS("./Data/statcast2024_cleaned.rds")
cleaned_data <- cleaned_data |>
  select('launch_speed','launch_angle','total_bases') |>
  mutate(total_bases = as.factor(total_bases))

# Model spec
knn_spec <- nearest_neighbor() |>
  set_mode("classification") |>
  set_engine(engine = "kknn") |>
  set_args(neighbors = tune())

#Variable spec
variable_recipe <- recipe(total_bases ~ ., data = cleaned_data) |>
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
    grid = grid_regular(neighbors(range = c(1,40)), levels = 20),
    resamples = vfold_cv(cleaned_data, v = 2),
    metrics = metric_set(roc_auc)
  )

# Comparing knn models and choosing which one to use
knn_models |>
  collect_metrics()

# Plotting the different models
knn_models |>
  autoplot()

# Finding the best k
best_k <- knn_models |>
  select_best(metric = "roc_auc")
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


#data_split <- initial_split(cleaned_data, prop=0.8)
#train_data <- training(data_split)
#test_data <- testing(data_split)

#features <- c('launch_angle', 'launch_speed')
#target <- 'total_bases'

#X <- train_data[features]
#y <- train_data[target]

#y_pred = knn(X, y, train$total_bases, 10, prob = TRUE)

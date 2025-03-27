library(tidymodels)
library(xgboost)
library(Matrix)
library(caret)
library(vctrs)

#-----IMPORTING CLEANED DATA
cleaned_data <- readRDS("./data/statcast2024_cleaned.rds")
cleaned_data <- cleaned_data |>
  select(launch_speed,launch_angle,total_bases) |>
  mutate(total_bases = as.numeric(total_bases))
#-----
set.seed(156)

X <- as.matrix(cleaned_data[, 1:2])
y = as.numeric(cleaned_data$total_bases)
dtrain_dmatrix <- xgb.DMatrix(data = X, label = y)

params <- list(
  objective = "multi:softprob",
  eval_metric = "mlogloss",
  num_class = 5
)

cv_results <- xgb.cv(
  params = params,
  data = dtrain_dmatrix,
  nfold = 5,
  nrounds = 100,
  early_stopping_rounds = 100,
  verbose = TRUE
)

best_nrounds <- cv_results$best_iteration

final_model <- xgb.train(
  params = params,
  data = dtrain_dmatrix,
  nrounds = best_nrounds
)

search_grid <- expand.grid(
  max_depth = c(3,6),
  eta = c(0.01, 0.3),
  colsample_bytree = c(0.5, 0.9)
)

best_auc <- 0
best_params <- list()

for (i in 1:nrow(search_grid)) {
  params <- list(
    objective = "multi:softprob",
    eval_metric = "mlogloss",
    num_class = 5,
    max_depth = search_grid$max_depth[i],
    eta = search_grid$eta[i],
    colsample_bytree = search_grid$colsample_bytree[i]
  )
  
  cv_results <- xgb.cv(
    params = params,
    data = dtrain_dmatrix,
    nfold = 5,
    nrounds = 100,
    early_stopping_rounds = 10,
    verbose = TRUE
  )
  
  mean_auc <- max(cv_results$evaluation_log$test_mlogloss_mean)
  if(mean_auc > best_auc) {
    best_auc <- mean_auc
    best_params <- params
    best_nrounds <- cv_results$best_iteration
  }
}

final_model <- xgb.train(
  params = params,
  data = dtrain_dmatrix,
  nrounds = best_nrounds
)

saveRDS(final_model, "./data/best_xgboost_model.rds")
xgboost_model_xwoba_saved <- readRDS("./data/best_xgboost_model.rds")
#------

#------PREDICT TOTAL BASES PROBABILITIES USING FITTED MODEL
cleaned_data_predictions_prob <- xgboost_model_xwoba_saved |>
  predict(newdata = dtrain_dmatrix)
cleaned_data_predictions_prob <- as_tibble(cleaned_data_predictions_prob)
id_vector <- vec_rep_each(c(1:nrow(cleaned_data)), times = 5)
columns_vector <- vec_rep(c(0,1,2,3,4), times = nrow(cleaned_data))
cleaned_data_predictions_prob <- cbind(cleaned_data_predictions_prob, columns_vector, id_vector)
cleaned_data_predictions_prob <- cleaned_data_predictions_prob |>
  pivot_wider(id_cols = id_vector, names_from = columns_vector, values_from = value) |>
  select(-id_vector)

#saveRDS(cleaned_data_predictions_prob, "/Users/chrisa/Documents/GitHub/park-specific-xwoba/data/cleaned_data_predictions_prob_xgboost.rds")
cleaned_data_predictions_prob <- readRDS("./data/cleaned_data_predictions_prob_xgboost.rds")

comparison <- cbind(cleaned_data$total_bases, cleaned_data_predictions_prob)
comparison_best_results <- comparison |>
  mutate(best_prediction = case_when(
    `0` == pmax(`0`,`1`,`2`,`3`,`4`) ~ 0,
    `1` == pmax(`0`,`1`,`2`,`3`,`4`) ~ 1,
    `2` == pmax(`0`,`1`,`2`,`3`,`4`) ~ 2,
    `3` == pmax(`0`,`1`,`2`,`3`,`4`) ~ 3,
    `4` == pmax(`0`,`1`,`2`,`3`,`4`) ~ 4
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
total_bases_probs <- cleaned_data_predictions_prob[c('0','1','2','3','4')]

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

#saveRDS(final_df, "./data/xgboost_xwOBA_ungrouped.rds")

cleaned_data_grouped_xwOBA <- final_df |>
  group_by(batter) |>
  #<<<<<<< Updated upstream
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

saveRDS(predicted_vs_official, "./data/xgboost_xwoba_vs_mlb.rds")

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

#library(tidyverse)

library(tidymodels)
library(dplyr)
library(yardstick)
library(ggplot2)
library(mgcv)

#-----IMPORTING CLEANED DATA
cleaned_data <- readRDS("./data/statcast2024_cleaned.rds")
cleaned_data <- cleaned_data |>
  select(launch_speed, launch_angle, total_bases)
  #mutate(total_bases = as.factor(total_bases))
#-----
class(cleaned_data$total_bases)
#-----DEFINING GAM WORKFLOW WITH TIDYMODELS
# Model spec
gam_model <- gam(list(total_bases ~ s(launch_speed, launch_angle),
                ~ s(launch_speed, launch_angle),
                ~ s(launch_speed, launch_angle),
                ~ s(launch_speed, launch_angle)),
              family = multinom(K = 4),
              data = cleaned_data)
summary(gam_model)

cleaned_data_predictions_prob <- predict(gam_model, cleaned_data, type = "response")
cleaned_data_predictions_prob <- as.data.frame(cleaned_data_predictions_prob)
#comparison <- as_tibble(cleaned_data_predictions_prob)

# Calculating Accuracy
comparison <- comparison |>
  add_column(cleaned_data$total_bases)

comparison_best_results <- comparison |>
  mutate(best_prediction = case_when(
    V1 == pmax(V1, V2, V3, V4, V5) ~ 0,
    V2 == pmax(V1, V2, V3, V4, V5) ~ 1,
    V3 == pmax(V1, V2, V3, V4, V5) ~ 2,
    V4 == pmax(V1, V2, V3, V4, V5) ~ 3,
    V5 == pmax(V1, V2, V3, V4, V5) ~ 4
  ))

accuracy <- comparison_best_results |>
  mutate(match = case_when(
    `cleaned_data$total_bases` == best_prediction ~ 1,
    TRUE ~ 0
  ))

amount_correctly_predicted <- accuracy |>
  count(match == 1)
amount_correctly_predicted_percentage <- (amount_correctly_predicted$n[2] / (amount_correctly_predicted$n[1] + amount_correctly_predicted$n[2])) * 100
amount_correctly_predicted_percentage

saveRDS(gam_model, "./data/best_gam_model.rds")
gam_model_xwoba_saved <- readRDS("./data/best_gam_model.rds")

#--------
woba_2024_weights <- c(0, 0.882, 1.254, 1.590, 2.050)
total_bases_probs <- cleaned_data_predictions_prob[c('V1','V2','V3','V4','V5')]

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

data.frame(LA = -10:50) |>
  crossing(data.frame(EV = 50:90))

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

cleaned_data_grouped_xwOBA <- final_df |>
  group_by(batter) |>
  filter(n() > 100) |>
  summarize(xwOBA = mean(xwOBA), woba = mean(woba))

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

library(tidyverse)
library(xgboost)

statcast <- readRDS("./data/statcast2024(R).rds")

params <- list(max-depth = 2, eta = 1, objective = "multi:softprob", num_class = 5)
multi_cvres <- xgb.cv(params, dmatrix, nrounds = 200, )

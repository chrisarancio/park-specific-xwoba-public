# Park-Specific xwOBA
This project intends to create an open-source version of the Statcast xwOBA model. We trained a KNN, Extreme Gradient Boosting, and Generalized Additive Model (GAM) algorithms using official Statcast data. The best performing model (KNN) was then used in an analysis of a player's park-specific xwOBA.
  
This will be done by taking the xwOBA predictions for all events, subsetting them by player and ballpark, and then taking the average difference between their ballpark-specific xwOBA and that ballpark's average xwOBA for all players. These differences can be visualized for every player for ten different ballparks from the 2015-2024 seasons using our Shiny application. These visualizations can help answer questions like: 1. What players have the highest modeled xwOBAs at each ballpark? 2. How do the modeled xwOBAs compare to the official season-long values? 3. Which players have a higher predicted xwOBA stat at their home ballpark? 4. Do players that consistently bat righty or lefty have consistently better or worse xwOBA scores at certain ballparks?

### Overview
----------------------
- The data was scraped from Statcast using the script `code/get_statcast_data.R` then cleaned using `code/clean_data_knn.R`
	- Note that this statcast script now uses a modified version of the `baseballr` package found [here](https://github.com/ltw8/baseballr), allowing us to scrape park-level data. 
- The original KNN code that attempt to recreate the Statcast xwOBA model lives in `code/knn_xwoba.R`
- The code to create the KNN models for each ballpark reuses most of this original KNN code and is in `code/park_knn_xwoba.R`
- The code to calculate xwOBA for each batter at each park for each year is in `code/park_xwoba_years.R`
- The code to bring in the MLB official xwOBA values and construct the final dataframe used in the shiny dashboard is in `code/compare_park_xwobas.R`
- For the final product of this project we did a shiny dashboard which can be found in `code/shiny/app.R`
- An overview of the performance for the different machine learning models that we trained in the process of recreating xwOBA can be found in `analysis/Final Model Evaluations.docx`
	- The code for the XGBoost and GAM models can be found in `code/xgboost_xwoba.R` and `code/gam_xwoba.R` respectively

# Park-Specific xwOBA
This project intends to create an open-source version of the Statcast xwOBA model. We trained a KNN, Extreme Gradient Boosting, and Generalized Additive Model (GAM) algorithms using official Statcast data. The best performing model (KNN) was then used in an analysis of a player's park-specific xwOBA.
  
This will be done by taking the xwOBA predictions for all events, subsetting them by player and ballpark, and then taking the average difference between their ballpark-specific xwOBA and that ballpark's average xwOBA for all players. These differences can be visualized for every player for ten different ballparks from the 2015-2024 seasons using our Shiny application. These visualizations can help answer questions like: 
1. What players have the highest modeled xwOBAs at each ballpark?
2. How do the modeled xwOBAs compare to the official season-long values?
3. Which players have a higher predicted xwOBA stat at their home ballpark?
4. Do players that consistently bat righty or lefty have consistently better or worse xwOBA scores at certain ballparks?

### Code Overview
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

## Background
In the world of baseball analytics, there are many methods used to try to represent a player’s offensive ability but this project focuses mostly on the wOBA and xwOBA metrics. Weighted On-base Average (wOBA) is a metric defined by the MLB as “a version of on-base percentage that accounts for how a player reached base -- instead of simply considering whether a player reached base. The value for each method of reaching base is determined by how much that event is worth in relation to projected runs scored.” Rather than a simple on-base percentage (OBP), which refers to “how frequently a batter reaches base per plate appearance,” the weighted OBA (wOBA) has the advantage of considering how different events will have different impacts on scoring runs. For example, the 2023 wOBA formula assigns a linear weight of 1.569 to a triple and a linear weight of 0.833 for a single in that season.

However, there is an even more indicative statistic for a player’s offensive skill called Expected Weighted On-base Average (xwOBA). xwOBA incorporates “exit velocity, launch angle and, on certain types of batted balls, Sprint Speed” and “allows for the formation of said player's xwOBA based on the quality of contact, instead of the actual outcomes.” In other words, xwOBA removes defense from the equation and provides probabilities for a single, double, triple, and homerun “based on the results of comparable batted balls since Statcast was implemented Major League wide in 2015.”

For this project, it is important to note that these factors or weights indicate the “adjusted run expectancy of a batting event in the context of the season as a whole.” This analysis trained a model to predict xwOBA for a player on a per-ballpark basis. The reasoning for this is that the outfield walls of each ballpark can vary greatly. In fact, Kansas City and Toronto are the only two stadiums in MLB with symmetrical outfield dimensions and uniform wall height. This means that scoring a homerun at each park will require different exit velocities and launch angles to make it over the outfield walls. Since xwOBA considers exit velocity and launch angle in its calculations, this analysis considers how different ballparks could affect a player’s xwOBA.

## Example of Dashboard Created to View our Final Results
<img width="909" height="710" alt="Screenshot 2026-05-31 at 4 11 36 PM" src="https://github.com/user-attachments/assets/184c0636-0373-4d9d-9281-797f4edc531b" />

# What does this chart mean?
Using KNN models trained on pitches from each ballpark and the MLB wOBA weights for each year, we calculated a park-specific xwOBA for each player. We can then compare the average difference between the predicted park xwOBA and the MLB official xwOBA values for every player for the 2015-2024 seasons. These average differences for a certain season and ballpark can then be compared to a specific player's predicted xwOBA during that season and at that ballpark. These differences can highlight certain ballparks where a player may have overperformed or underperformed (compared to the average xwOBA) during a desired season. For example, one can examine which players have overperformed (in terms of xwOBA) at their home ballpark during various seasons.

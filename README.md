# Park-Specific xwOBA
## Objectives
This project attempts to do two main things: 
1. Create an open-source version of the MLB's official Statcast model of the offensive batting statistic called Expected Weighted On-base Average (xwOBA). This statistic uses only a batted ball's launch angle, its exit velocity, and a player's sprint speed in its prediction. Our version uses only a batted ball's launch angle and exit velocity to predict xwOBA.
2. Use this model to predict a player's park-specific xwOBA stat across several different ballparks and seasons - something that has not been officially done in the MLB. All official MLB xwOBA stats are reported based on league-wide play for each player during each season.

The goal is to be able to visualize and identify patterns in offensive statistics for certain players at certain ballparks across various seasons.

## Results
We have trained several models with publicly available Statcast data. These utilize the K-Nearest Neighbors (KNN), Extreme Gradient Boosting (XGBoost), and Generalized Additive Model (GAM) algorithms for probabilistic multi-class classification. These probabilites are used to calculate an xwOBACON for every batted event and are combined with non-batted events to create an average xwOBA for each (qualified) player at each of our selected ballparks for every season he has played (see [Project Proposal](https://github.com/chrisarancio/park-specific-xwoba-public/blob/main/proposal/aranciochristopher_2321_2405969_MTH320%20-%20Final%20Project%20Proposal.docx) for a more detailed explanation of this method).

The KNN model had results closest to the official MLB values which are representative of league-wide play (see [KNN Analysis](https://github.com/chrisarancio/park-specific-xwoba-public/blob/main/analysis/knn_xwoba.html) for more details). Therefore, in order to predict a player's park-specific xwOBA, we trained a park-specific KNN model for ten different ballparks using data from the 2015-2024 seasons (those can be found [here](https://github.com/chrisarancio/park-specific-xwoba-public/tree/main/data/new_parks/knn_models).
  
We can then compare the average difference between the predicted park-specific xwOBA and the MLB official xwOBA values for _every player_ for the 2015-2024 seasons (these appear as 'League Average' in red). These average differences for a certain season and ballpark can then be compared to a _specific player's_ predicted xwOBA during that season and at that ballpark (these appear as 'Player Performance' in blue). These differences can highlight certain ballparks where a player may have overperformed or underperformed (compared to the average xwOBA) during a desired season. All comparisons can be visualized using our interactive Shiny-based dashboard [here](https://github.com/chrisarancio/park-specific-xwoba-public/blob/main/code/shiny/app.R).

## Example of Dashboard Created to View our Final Results
<img width="909" height="710" alt="Screenshot 2026-05-31 at 4 11 36 PM" src="https://github.com/user-attachments/assets/675b0f01-6ce8-4da1-a9c6-6f2fb4effa62" />

**These visualizations can help answer questions like:**
1. What players have the highest predicted xwOBAs at each ballpark?
2. Given ballparks can vary by wall height, wall depth, and stadium elevation, do certain ballparks have greater average league-wide xwOBAs across multiple seasons?
3. Which players have a higher predicted xwOBA stat at their home ballpark?
4. Do players that consistently bat righty or lefty have consistently better or worse predicted xwOBA scores at certain ballparks?

### Additional Code Files
----------------------
- The data was scraped from Statcast using the script `code/get_statcast_data.R` then cleaned using `code/clean_data_knn.R`
	- Note that this statcast script now uses a modified version of the `baseballr` package found [here](https://github.com/ltw8/baseballr), allowing us to scrape park-level data. 
- The original KNN code that attempts to recreate the Statcast xwOBA model lives in `code/knn_xwoba.R`
- The code to create the KNN models for each ballpark reuses most of this original KNN code and is in `code/park_knn_xwoba.R`
- The code to calculate predicted xwOBAs for each batter at each park for each year is in `code/park_xwoba_years.R`
- The code to bring in the MLB official xwOBA values and construct the final dataframe used in the shiny dashboard is in `code/compare_park_xwobas.R`
- All final results are visualized in a shiny dashboard which can be found in `code/shiny/app.R`
- An overview of the performance for the different machine learning models that we trained in the process of recreating xwOBA can be found in `analysis/Final Model Evaluations.docx`
	- The code for the XGBoost and GAM models can be found in `code/xgboost_xwoba.R` and `code/gam_xwoba.R` respectively

##  Additional Background on Expected Weighted On-base Average (xwOBA)
In the world of baseball analytics, there are many methods used to try to represent a player’s offensive ability but this project focuses mostly on the wOBA and xwOBA metrics. Weighted On-base Average (wOBA) is a metric defined by the MLB as “a version of on-base percentage that accounts for how a player reached base -- instead of simply considering whether a player reached base. The value for each method of reaching base is determined by how much that event is worth in relation to projected runs scored.” Rather than a simple on-base percentage (OBP), which refers to “how frequently a batter reaches base per plate appearance,” the weighted OBA (wOBA) has the advantage of considering how different events will have different impacts on scoring runs. For example, the 2023 wOBA formula assigns a linear weight of 1.569 to a triple and a linear weight of 0.833 for a single in that season.

However, there is an even more indicative statistic for a player’s offensive skill called Expected Weighted On-base Average (xwOBA). xwOBA incorporates “exit velocity, launch angle and, on certain types of batted balls, Sprint Speed” and “allows for the formation of said player's xwOBA based on the quality of contact, instead of the actual outcomes.” In other words, xwOBA removes defense from the equation and provides probabilities for a single, double, triple, and homerun “based on the results of comparable batted balls since Statcast was implemented Major League wide in 2015.”

For this project, it is important to note that these factors or weights indicate the “adjusted run expectancy of a batting event in the context of the season as a whole.” This analysis trained a model to predict xwOBA for a player on a per-ballpark basis. The reasoning for this is that the outfield walls of each ballpark can vary greatly. In fact, Kansas City and Toronto are the only two stadiums in MLB with symmetrical outfield dimensions and uniform wall height. This means that scoring a homerun at each park will require different exit velocities and launch angles to make it over the outfield walls. Since xwOBA considers exit velocity and launch angle in its calculations, this analysis considers how different ballparks could affect a player’s xwOBA.

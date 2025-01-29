## Intro to xwOBA Article Notes
29 January 2025

- The main difference between xwOBA and wOBA is that xwOBA ignores batted ball outcomes, which depend on other variables outside of just the hitter, such as defense, ballpark, etc. 
- ***xwOBA = (xwOBAcon + wBB x (BB-IBB) + wHBP x HBP)/(AB + BB - IBB + SF + HBP)***
- Where xwOBAcon is the xwOBA estimate for contact outcomes, and the other weighted stats are wOBA weights for walk, intentional walks, and hit-by-pitches
- The public version of xwOBAcon is based on exit velocity, launch angle, and sprint speed
- They build a version of xwOBA using only EV and LA with k-nearest neighbors
- Faster players will outperform estimates from this model since sprint speed was not included
- They used Generalized Additive Models to "capture the linear effect of speed with the highly non-linear interaction of LA and EV"
- Used GAMs on batted balls where speed would matter, such as weakly hit balls, shallow pop-ups, and ground balls, and KNN on batted balls where speed matters less
- Evaluate model performance with root mean square error, compare to a naive prediction of wOBA
- Barrels and solid contact are the batted balls that have the most uncertainty, factors include weather, ballpark, defense, etc. 
- These variables are not included so that the model is context neutral, only measuring factors in control of the batter, so players can be compared under average conditions
- Not sufficient evidence that spray angle tendencies (pull/oppo) lead to better wOBA
- Higher temperatures lead to higher wOBA on balls in the air since they travel further
- **Some stadiums have more trouble predicting HRs, often they have a unique feature such as a deep or shallow outfield on one side (deep in BAL LF, shallow in NYY RF**)
- Spearman correlation to see if players maintain similar xwOBA and xwOBAcon from year to year, xwOBAcon is most stable, with xwOBA not far behind
- xwOBA is most predictive of the stats they tested, but not much different than wOBA, could be bias from players staying on the same team and ballpark
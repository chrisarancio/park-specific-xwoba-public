# Modeling xwOBA with KNN Article Notes
29 January 2025
- wOBA is weighted to consider the expected run value of an event rather than just whether a player got on base or not (OBA)
- xwOBA "describes what should have happened given the feature of the batted ball event and removes defense from the equation"
- KNN select the number of neighbors $k$, calculated distance between a data point and other data points, select the $k$ nearest points, classify the point in question depending on the classifications of the neighbors
- **Five batted ball outcomes to consider: field out (including errors), single, double, triple, home run**
- Along with launch speed (exit velocity) and launch angle
- The target for the model is **total bases** 
- The model provides probabilities of outcomes rather than classifying into singular outcome, which can be multiplied by wOBA coefficients to get to xwOBAcon
- to get to 
- $xwOBA = \dfrac{0.696 * uBB + 0.726 * HBP + \sum_{i=1}^{n} xwOBAcon_{i}}{AB + BB - IBB + SF + HBP}$
- Nestico used 2020-2023 season for his model, training on 2020-2022, and testing on 2024
- The model does not calculate xwOBA but predicts total bases, which can then be used to calculated xwOBA
- All non-batted ball data was filtered from the training set
- He used a $k=11$ which "was selected iteratively"
- His model correctly predicted total bases of 76% of the data points, given launch speed and launch angle
- Compare xwOBA to MLB calculated xwOBA on a scatterplot and get the $R^2$, his was 0.96
- Without including sprint speed, there were some outliers that would have had higher xwOBA if they are fast, and lower if they were slow, than the model predicted
## CSC 485  Notes

##### Park Specific KNN Model
- Instead of just grouping the existing KNN by player and park, train a model for each ballpark, starting with the most "interesting" parks (BOS, NYY, BAL, etc.)
- Follow the same procedure as our existing KNN just for a pitches only at that ballpark so you get $f(EV, LA) = xwOBA_{BOS}$, for example.

##### Other KNN 
- Use the `crossing()` function to better recreate the graph from Sharpe article
- Could also make them side by side using the $xwOBA$ included in statcast dataset
- Potentially find into faster way to run KNN with a large $k$

##### GAM
- Continue progess with GAM, fit with multinomial family
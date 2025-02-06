### Meeting 03
6 February 2025
- Recreate the `xwOBAcon` exit velocity versus launch angle graph from Sharpe article mostly to check how much smoothing is done
- Try a $k=11$ from the Nestico article
- Filter on `woba_denom` from statcast dataset to only get rows that are included in `wOBA`
- Stop filtering by `launch_speed > 0`
- Select `launch_speed`, `launch_angle`, `xwOBAcon` into `xWOBAcon`
- Left join join `xWOBAcon` and `df` with walks and hit by pitch, etc. and make sure to filter for unique rows
- Then use `estimated_woba_using_speedangle` to make sure `xwOBAcon` is similar, maybe a scatterplot
- If `xwOBACON` is null then use `wOBA`, otherwise `xwOBAcon`
- group by player id or name, `summarize(xwOBA = mean(xwOBA))`

**Next Steps**
- Try another model like GAMs, Random Forest, etc.
- Use [*Tidy Modeling with R*](https://www.tmwr.org) as reference
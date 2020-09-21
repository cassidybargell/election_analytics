#### [Home](https://cassidybargell.github.io/election_analytics/)

# State Unemployment Data vs. Popular Vote Outcomes
## 9/21/20

Another use for economic data in election prediction is to stratify by state.

The relationship between state economies and two-party vote share for the Republican party can be modelled using Q2 state unemployment data.

![](../figures/swing_lm.png)

For modeling, I have chosen  eleven states that are being included in various discussions as 2020 swing states (including my swing state model from [9/14/20](https://cassidybargell.github.io/election_analytics/posts/week_1.html))) [(NPR)](https://www.npr.org/2020/09/16/912004173/2020-electoral-map-ratings-landscape-tightens-some-but-biden-is-still-ahead).

Only a few states produce models that are significant enough to focus on. These are Wisconsin, Michigan, Pennsylvania, Georgia and Ohio. None of these state models produce t-values for slope >= 2, so their predictive power is limited. 

Based on 2020 Q2 unemployment rates, the predictions of Republican vote share in these five states follow: 

WI: *58.03%*, MI: *63.43%*, PA: *54.74%*, GA: *40.69%*, and OH *60.85%*.*

Although these predictions do not hold much weight, if this outcome was accurate this would add 64 electoral college votes for Trump and 16 for Biden for this particular subset of swing states. 

<hr>

**Additional statistical tests for these values can be found on the github for the blog.*
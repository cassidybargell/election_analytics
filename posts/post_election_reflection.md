#### [Home](https://cassidybargell.github.io/election_analytics/)

# Post Election Reflection
## 11/25/20

<hr>

## How My Model Performed 

My final prediction model was a [**weighted ensemble**](https://cassidybargell.github.io/election_analytics/posts/final_prediction.html) that combined generalized linear models based off of data from polls, demographics, unemployment rates, and COVID-19 deaths. I settled on using weights for each state that were inversely proportionate to the RMSE of each individual model in the weighted ensemble. This meant for the majority of states the COVID-19 7-day death rate model was weighted most heavily, and the unemployment model was given the least amount of weight. 

#### **Predicted Incumbent Vote Share** = (*pwt* * Poll-Model) + (*ewt* * Unemploy-Model) + (*dwt* * Demographic-Model) + (*cwt* * COVID-Model)

Where *pwt*, *ewt*, *dwt*, and *cwt* are weights assigned to each model. The heavier a model is weighted, the more influence it has over the final prediction produced by the model. 

The final point estimate this model produced was **368** electoral college votes to Biden and **170** to Trump. 

The final election outcome was **306** electoral college votes for Biden and **232** for Trump. I overpredicted Biden's win by 62 electoral college votes, which comes down to missing three states that went to Trump: **Florida** (29 votes), **Ohio** (18 votes), and **North Carolina** (15 votes).*(I also predicted Maine and Nebraska without split votes, but both states had one vote go to the non-majority party which was one for Biden in Nebraksa and one for Trump in Maine, so it had no final affect on the overall electoral vote count.)*

![](../figures/post-election/predicted_v_actual.png)

(The three states I missed are the three red points to the left of the verticle line)

States above the diagonal line are states in which I overpredicted the Biden vote share, and states under the diagonal line are where I underpredicted Biden vote share. Overall I overpredicted Biden in 41 out of 50 states, the nine states in which I overpredicted Trump vote share were Maryland, Colorado, New Mexico, Oregon, Vermont, Washington, Nebraksa, Utah, and Delaware.

![](../figures/post-election/missedstates_gt.png)

*The [Choice Model](https://cassidybargell.github.io/election_analytics/posts/final_prediction.html) weighted polls most heavily at 0.85, with unemployment, demographics, and COVID-19 death rates all given a weight of 0.05.*

![](../figures/post-election/rmse_diff_combined.png)

![](../figures/post-election/rmse_diff_separate.png)

![](../figures/post-election/choice_diff_combined.png)

![](../figures/post-election/choice_diff_separate.png)


# Innaccuracies

![](../figures/post-election/compare_models_statebin.png)

![](../figures/post-election/poll_v_actual.png)

# If I Were to Do It Again...




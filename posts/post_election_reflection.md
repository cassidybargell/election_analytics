#### [Home](https://cassidybargell.github.io/election_analytics/)

# Post Election Reflection
## 11/25/20

<hr>

## How My Model Performed 

My final prediction model was a **weighted ensemble** that combined generalized linear models based off of data from polls, demographics, unemployment rates, and COVID-19 deaths. I settled on using weights for each state that were inversely proportionate to the RMSE of each individual model in the weighted ensemble. This meant for the majority of states the COVID-19 7-day death rate model was weighted most heavily, and the unemployment model was given the least amount of weight. 

#### **Predicted Incumbent Vote Share** = (*pwt* * Poll-Model) + (*ewt* * Unemploy-Model) + (*dwt* * Demographic-Model) + (*cwt* * COVID-Model)

Where *pwt*, *ewt*, *dwt*, and *cwt* are weights assigned to each model. The heavier a model is weighted, the more influence it has over the final prediction produced by the model. 

The final point estimate this model produced was **368** electoral college votes to Biden and **170** to Trump. 

The final election outcome was **306** electoral college votes for Biden and **232** for Trump. I overpredicted Biden's win by 62 electoral college votes, which comes down to missing three states that went to Trump: **Florida** (29 votes), **Ohio** (18 votes), and **North Carolina** (15 votes).

![](../figures/post-election/predicted_v_actual.png)

![](../figures/post-election/missedstates_gt.png)

![](../figures/post-election/rmse_diff_combined.png)

![](../figures/post-election/rmse_diff_separate.png)

![](../figures/post-election/choice_diff_combined.png)

![](../figures/post-election/choice_diff_separate.png)

![](../figures/post-election/compare_models_statebin.png)

![](../figures/post-election/poll_v_actual.png)
#### [Home](https://cassidybargell.github.io/election_analytics/)

# Post Election Reflection
## 11/25/20

<hr>

## How My Model Performed 

My final prediction model was a [**weighted ensemble**](https://cassidybargell.github.io/election_analytics/posts/final_prediction.html) that combined generalized linear models based off of data from polls, demographics, unemployment rates, and COVID-19 deaths. I settled on using weights for each state that were inversely proportionate to the RMSE of each individual model in the weighted ensemble. This meant for the majority of states the COVID-19 7-day death rate model was weighted most heavily, and the unemployment model was given the least amount of weight. 

#### **Predicted Incumbent Vote Share** = (*pwt* * Poll-Model) + (*ewt* * Unemploy-Model) + (*dwt* * Demographic-Model) + (*cwt* * COVID-Model)

Where *pwt*, *ewt*, *dwt*, and *cwt* are weights assigned to each model. The heavier a model is weighted, the more influence it has over the final prediction produced by the model. 

The final point estimate this model produced was **368** electoral college votes to Biden and **170** to Trump. 

The final election outcome was **306** electoral college votes for Biden and **232** for Trump. I overpredicted Biden's win by 62 electoral college votes, which comes down to missing three states that went to Trump: **Florida** (29 votes), **Ohio** (18 votes), and **North Carolina** (15 votes). *(I also predicted Maine and Nebraska without split votes, but both states had one vote go to the non-majority party which was one for Biden in Nebraksa and one for Trump in Maine, so it had no final affect on the overall electoral vote count.)*

![](../figures/post-election/predicted_v_actual.png)

(The three states I missed are the three red points to the left of the verticle line)

States above the diagonal line are states in which I overpredicted the Biden vote share, and states under the diagonal line are where I underpredicted Biden vote share. Overall I overpredicted Biden in 41 out of 50 states, the nine states in which I overpredicted Trump vote share were Maryland, Colorado, New Mexico, Oregon, Vermont, Washington, Nebraksa, Utah, and Delaware.

![](../figures/post-election/missedstates_gt.png)

*The [Choice Model](https://cassidybargell.github.io/election_analytics/posts/final_prediction.html) weighted polls most heavily at 0.85, with unemployment, demographics, and COVID-19 death rates all given a weight of 0.05.*

The difference between predicted vote share and actual vote share for Trump can be visualized below. The verticle dashed lines represent the average difference between predicted and actual values for states that went to Trump (-2.95) and states that went to Biden (-1.15).

![](../figures/post-election/rmse_diff_combined.png)


The root mean square error for this model, a measure of how far my predicted values were from the true values, was **3.04**.

![](../figures/post-election/rmse_diff_separate.png)

The RMSE values for the model separated by who won the state vary. For states won by Biden, the RMSE value was **2.57** whereas for states won by Trump the RMSE was **3.45**. This suggests I was more innaccurate in red states than I was in blue states.

Although I chose the RMSE weighted model in the end, I also wanted to examine how the my choice weighted model performed (polls weighted at 0.85, all other models at 0.05). The choice model more closely predicted the true outcome in 28 states, compared to the RMSE model more closely predicting the true outcome in 22. 

![](../figures/post-election/compare_models_statebin.png)

The RMSE model seemed to perform better predicting blue states, while the choice model seemed to perform better predicting red states. Overall however, the choice model was more accurate than the RMSE model. The choice weights model only missed 2 states, Arizona and Georgia, which were the two states with the closest final outcome of all 50 states. 

![](../figures/post-election/choice_diff_combined.png)

![](../figures/post-election/choice_diff_separate.png)

The RMSE for the choice weight model overall was lower than the RMSE weighted model, at **2.98**. When separated by red and blue states, the RMSE for blue states using the choice model was **2.84** and for red states was **3.12**.  

# Sources of Innaccuracy

I think a large source of my underprediction of Trump's performance came from an overreliance on polling data, especially given my inclusion of the COVID-19 model weighted very heavily. 

![](../figures/post-election/poll_v_actual.png)

- changes in polls averages wasn't necessarily reflective of COVID-19 death rate
- a more realistic thing to include should have been approval rating of COVID response, or maybe just approval rating of the president overall. 

# If I Were to Do It Again...

- maybe use more economic factors from the prior year




#### [Home](https://cassidybargell.github.io/election_analytics/)

# Final Election Prediction
## 11/1/20

<hr>

## The Model

For my final election prediction I have chosen to use a **weighted ensemble** that combines generalized linear models based off of data from polls, demographics, unemployment rates, and COVID-19 deaths.

The individual models that make up the weighted ensemble are as follows: 

* **Polling**: Historical Republican two-party popular vote share versus state polling averages one week out or less from the election. (1972-2016) Poll averages from 10/29/20 were used to make a prediction for 2020. 

* **Demographics**: Historical Republican two-party popular vote share versus percentage of white people in the state.(1992-2016) White percentage by state in 2018 was used in the prediction for 2020.

* **Unemployment Rates**: Historical Republican two-party popular vote share versus state unemployment rates from Q2 of the election year. (1976-2016) 2020 Q2 state unemployment rates were used for the 2020 prediction.

* **COVID-19 Deaths**: Incumbent support represented directly by poll support versus 7-day COVID-19 death rate per 100,000. Seven day death rate by state from 10/18/20 was used for the 2020 prediction.

The final weighted ensemble is: 

##### **Predicted Incumbent Vote Share** = (*pwt* * Poll-Model) + (*ewt* * Unemploy-Model) + (*dwt* * Demographic-Model) + (*cwt* * COVID-Model)

Where *pwt*, *ewt*, *dwt*, and *cwt* are weights assigned to each model. The heavier a model is weighted, the more influence it has over the final prediction produced by the model. 

Below is the distribution of coefficients for each state included in the final ensemble.

![](../figures/10_31_hist_coef.png)

Positive coefficients suggest a positive relationship between independent variable and predicted voteshare, and the opposite is true for negative coefficients. Therefore the coefficients can be interpretted as follows: 

* *COVID-19 Deaths*: the change in predicted vote share for the incumbent party (modelled directly with polling data) for a 1% increase in 7-day COVID-19 death rate per 100,000
* *Demographics*: the change in predicted vote share for the Republican party for a 1% increase in white population in a state
* *Unemployment*: the change in predicted vote share for the Republican party for a 1% increase in Q2 unemployment rate 
* *Polls*: the change in predicted vote share for the Republican party for a 1 point increase in the polls (adjusted poll aggregates - [538](https://projects.fivethirtyeight.com/polls/))

The outlier in demographic coefficients is West Virginia, a solidly red state. This is because the white population in West Virginia has steadily declined since 1992, from ~96% to ~94%, while the state has become increasingly Republican. This is not overly informative about the demographic inindependent variable, but rather reflects the rapid increase in vote share the the Republican party experienced in West Virginia; from recieving ~42% in 1992, to ~72% in 2016. 

**Why include these variables in the weighted ensemble?**

I have explored each of these variables in previous weeks, and believe the combination has the potential to accurately capture the complexities of the 2020 election. 

* **Polling**: Polls provide direct insight into voter preferences. Given how unpredictable other variables have been in 2020, I believe polling is essential to create a prediction model this year. As the election date approaches, there is also an uptick in the amount of polls coming from states so polling becomes less variable the closer to the election. 

* **Demographics**: Demographics can also be useful in predicting election outcomes. I have chosen to include white percentage as a predictor for Republican vote share because of the criticisms of 2016 polls having a generally left-leaning bias [(Economist)](https://projects.economist.com/us-2020-forecast/president/how-this-works). In theory including demographic data would increase the stability of the model for 2020 (the pandemic has not drastically altered demographic makeup of states), while also perhaps balancing any potential skewed polling bias that might not yet be detectable. 

* **Unemployment Rates**: Unemployment is the only economic fundamental I have chosen to include in the weighted ensemble. Although nearly every economic indicator crashed in 2020, unemployment may have the most direct impact on individuals, and therefore might have the largest effect on retrospective voting evaluating the incumbent administration. As will be explored in the weighting of the ensemble, unemployment is given a small weight to reflect the potential lack of predictive power economic models have in such an unprecedented year. 

* **COVID-19 Deaths**: The pandemic has been a central theme of this years election as it has massively disrupted life for nearly every American. I think failing to include it in the model would ignore a massive variable in 2020. In theory [casualty sensitivity](https://www-journals-uchicago-edu.ezp-prod1.hul.harvard.edu/doi/pdfplus/10.1111%2Fj.1468-2508.2007.00564.x) would impact support for the incumbent. There is no historical data that can be used to model the effect of the pandemic however, so poll support throughout 2020 is being used as a direct proxy to understand how a second wave near the election could change vote share. 

## Weighting the Models

I explored two ways to weight the models in the ensemble. One method was weighting was based on the root mean squared errors of each generalized linear model. The other was a somewhat arbitrary choice in weights. The weighting options are explained further below. 

### Weight by Root Mean Squared Error

![](../figures/10_31_hist_rmse.png)

![](../figures/rmse_10_31_predictionmap.png)

### Choice Weights

![](../figures/10_31_predictionmap.png)

## Prediction Interval

Confidence intervals

![](../figures/rmse_10_31_ci_predictions.png)
![](../figures/rmse_10_31_swing.png)

![](../figures/10_31_ci_predictions.png)
![](../figures/10_31_swing.png)


## Final Point Estimate of Electoral College

![](../figures/10_31_predictionmap_winners.png)



---
title: "Data Analysis: Fitness User Bahavior and Preferences"
author: "Powei Fan"
output: 
  html_document:
      code_folding: show
      toc: true
      toc_depth: 3
      md_extensions: +emoji
---
```{r package loading, message=FALSE, warning=FALSE, include=FALSE, paged.print=FALSE}
# options(repos=structure(c(CRAN="http://cran.r-project.org")))
# install.packages("tidyverse")
# install.packages("janitor")
# install.packages("lubridate")
# install.packages("dplyr")
# install.packages("anytime")
# install.packages("psych")
#install.packages("rmarkdown")
#install.packages("ggpubr")
#install.packages("coefplot")
#install.packages("ggVennDiagram")
#install.packages("ggplot2")
#install.packages("cowplot")
#install.packages("stringr")
#install.packages("readr")
library(readr)
library(tidyverse)
library(janitor)
library(lubridate)
library(dplyr)
library(anytime)
library(psych)
library(rmarkdown)
library(ggpubr)
library(coefplot)
library(ggVennDiagram)
library(ggplot2)
library(cowplot)
library(stringr)
#install.packages("gridExtra")
library(gridExtra)
```

![](/Users/fanbowei/Downloads/html5up-read-only/images/image.webp)

# Introduction

***

### Company Overview
Bellabeat is a company that offers wearables and accompanying products that monitor biometric and lifestyle data to help women better understand how their bodies work and make healthier choices. Since it was founded in 2013, Bellabeat has grown rapidly and quickly positioned itself as a tech-driven wellness company for women. By 2016, Bellabeat had opened offices around the world and launched multiple products: including the Bellabeat app, Leaf, Time, and Spring. Products that collect data on activity, sleep, stress, and reproductive health have allowed Bellabeat to empower women with knowledge about their own health and habits.


### Business Challenge
The company has invested in traditional advertising media, but focuses on digital marketing extensively. Bellabeat invests year-round in Google Search, maintains active Facebook and Instagram pages, and consistently engages consumers on Twitter. Additionally, Bellabeat runs video ads on Youtube and display ads on the Google Display Network to support campaigns around key marketing dates. 

Bellabeat was looking for information from the analysis of its available consumer data for more opportunities for growth. The business goal is to analyze smart device usage data in order to gain insight into how consumers use non-Bellabeat smart devices. Questions asked by Sršen, Bellabeat’s co-founder and Chief Creative Officer, include:

* Q: What are some trends in smart device usage?
* Q: How could these trends apply to Bellabeat customers and help influence Bellabeat's marketing strategy?



# Data Preparation 

***

## Data Source

**Data source:** 

* FitBit Fitness Tracker Data [here](https://www.kaggle.com/datasets/arashnic/fitbit)\

**Dataset used:**


Units Of Measurement  | File Name
----------------------| -------------
        Daily         | Daily Activity, Sleep Day, Weight Log Info
        Hourly        | Hourly Steps, Hourly Intensities, Hourly Calories
        Secondly      | Heart Rate Seconds
        
**Tool:** 

* The entire project will be conducted through the use of the R programming language. From data importing, formatting & cleaning, analysis, and visualization to the sharing of findings, processes and results are documented clearly throughout this project.
```{r dataset loading, message=FALSE, warning=FALSE, highlight=TRUE}
##Dataset loading##

#set the file location
setwd('/Users/fanbowei/Downloads/Fitabase Data 4.12.16-5.12.16 2/')

#import dataset
daily_activity <- read_csv("dailyActivity_merged.csv") #TotalStep, TotalDistance, (level)Distance, ()Minutes, Calories
seconds_heartrate <- read_csv("heartrate_seconds_merged.csv")
hourly_steps <- read_csv("hourlySteps_merged.csv")
hourly_intensities <- read_csv("hourlyIntensities_merged.csv")
hourly_calories <- read_csv("hourlyCalories_merged.csv")
daily_sleep <- read_csv("sleepDay_merged.csv")
daily_weight <- read_csv("weightLogInfo_merged.csv")
```


## Formatting and Cleaning

**Data formatting and cleaning steps:**\

1. Change column names into a consistent format.
2. Change DateTime variables from character into a Date or DateTime format.
3. Create a weekday variable for analysis.
4. Check missing date or hour.
5. Check Null data.
6. Remove duplicate.
```{r class.source = 'fold-show', message= FALSE, warning= FALSE, highlight=TRUE}
#*****daily_activity******#
daily_activity <- daily_activity %>%
  clean_names() %>% #column name consistent
  mutate(activity_date = mdy(activity_date), week_date = weekdays(activity_date), .after = activity_date) %>% #convert chr to date, add new column weekday
  rename(date = activity_date) %>% #rename date variable
  group_by(id, date) #remove duplicate

#*****daily_sleep*****#
daily_sleep <- daily_sleep %>%
  clean_names() %>%
  mutate(sleep_day = as_date(mdy_hms(sleep_day)), week_date = weekdays(sleep_day), .after = sleep_day) %>%
  mutate(total_minutes_fall_asleep = total_time_in_bed - total_minutes_asleep) %>% #column to record the total minutes to fall asleep
  rename(date = sleep_day) %>%
  group_by(id, date)

#*****daily_weight*****#
daily_weight <- daily_weight %>% 
  clean_names() %>%
  mutate(date = as_date(mdy_hms(date)), week_date = weekdays(date), .after = date) %>%
  group_by(id, date)
  
#*****hourly_steps*****#
hourly_steps <- hourly_steps %>%
  clean_names() %>%
  mutate(activity_hour = mdy_hms(activity_hour), week_date = weekdays(activity_hour), .after = activity_hour) %>%
  rename(datetime = activity_hour) %>%
  group_by(id, datetime)

#*****hourly_calories*****$
hourly_calories <- hourly_calories %>%
  clean_names() %>%
  mutate(activity_hour = mdy_hms(activity_hour), week_date = weekdays(activity_hour), .after = activity_hour) %>%
  rename(datetime = activity_hour) %>%
  group_by(id, datetime)

#*****hourly_intensities*****#
hourly_intensities <- hourly_intensities %>%
  clean_names() %>%
  mutate(activity_hour = mdy_hms(activity_hour), week_date = weekdays(activity_hour), .after = activity_hour) %>%
  rename(datetime = activity_hour) %>%
  group_by(id, datetime)

#*****seconds_heartrate*****#
hourly_heartrate <- seconds_heartrate %>%
  clean_names() %>%
  mutate(time = anytime(cut(mdy_hms(time), breaks = "hour"))) %>%#turn second to hour
  rename(datetime = time) %>%
  group_by(id, datetime) %>%
  summarise(average_heartrate = round(mean(value))) %>% #turn second value to average hour value
  mutate(week_date = weekdays(datetime), .after = datetime)
```

**Combining data**\

1. Combine all daily datasets for exploring relationship between different variables.
2. Combine all hourly datasets for better interpretation.
```{r message=FALSE, warning=FALSE, class.source='fold-show', highlight=TRUE}
#left join the daily datasets into daily_df
daily_df <- list(daily_activity, daily_sleep, daily_weight) %>%
  reduce(left_join, by = c("id", "date", "week_date"))

#left join the hourly datasets into hourly_df
hourly_df <- list(hourly_steps, hourly_calories, hourly_intensities, hourly_heartrate) %>%
  reduce(left_join, by = c("id", "datetime", "week_date"))  
```

## Data summary

**Data summary:**

1.  **Daily Activity** contains **33** ID from **2016-04-12 to 2016-05-12**
2.  **Daily sleep** contains **24** ID from **2016-04-12 to 2016-05-12**
3.  **Daily weight** contains **8** ID from **2016-04-12 to 2016-05-12**
4.  **Hourly steps** contains **33** ID from **2016-04-12 to 2016-05-12 15:00:00**
5.  **Hourly calories** contains **33** ID from **2016-04-12 to 2016-05-12 15:00:00**
6.  **Hourly intensities** contains **33** ID from **2016-04-12 to 2016-05-12 15:00:00**
7.  **Hourly heartrate** contains **14** ID from **2016-04-12 to 2016-05-12 16:00:00**

**Quick view to each dataset**\

Daily activity
```{r echo=FALSE, message=FALSE, warning=FALSE, highlight=TRUE}
paged_table(daily_activity, list(rows.print = 5))
```
Daily sleep
```{r echo=FALSE, message=FALSE, warning=FALSE, highlight=TRUE}
paged_table(daily_sleep, list(rows.print = 5))
```
Daily weight
```{r echo=FALSE, message=FALSE, warning=FALSE, highlight=TRUE}
paged_table(daily_weight, list(rows.print = 5))
```
Hourly steps
```{r echo=FALSE, message=FALSE, warning=FALSE, highlight=TRUE}
paged_table(hourly_steps, list(rows.print = 5))
```
Hourly calories
```{r echo=FALSE, message=FALSE, warning=FALSE}
paged_table(hourly_calories, list(rows.print = 5))
```
Hourly_intensities
```{r echo=FALSE, message=FALSE, warning=FALSE}
paged_table(hourly_intensities, list(rows.print = 5))
```
Hourly heartrate
```{r echo=FALSE, message=FALSE, warning=FALSE}
paged_table(hourly_heartrate, list(rows.print = 5))
```



# Analyze 

***

The desire to have a better health condition is perhaps what drives people to purchase fitness tracker product and keeps using them. Therefore, this project not only studies how people use the fitness tracker but also focuses on two topics that most people care about; The three parts of the project are:

* **_Preference Features and Timing_** - Not all the users enjoy using every function the fitness tracker provides. Through the study of preference features, we can see what customers care most about, and when they like to exercise; thereby to more accurately designing the functions and products that meet the expectations of consumers.

* **_Sleep Quality_** - Sleep is essential for a person’s health and wellbeing, according to the National Sleep Foundation (NSF). Researchers have discovered sleep well can improve memory, strengthens the immune system, and leave you refreshed and alert when you wake up. Yet, more and more people have experienced a hard time from going to bed to actually falling asleep. This condition is called insomnia. A sleep disorder in which you have trouble falling and/or staying asleep.
* **_Calories Burn_** - Calorie is the most important thing people care about, since its strong relationship to losing weight. A healthy shape gives people confidence and decreases the risk of high blood pressure and heart disease. However, for most people, keeping their weight at a healthy level is a difficult task.

The following analysis will focus on these three issues. The goal is to find relationships or patterns that will give us insights for figuring out how and what we can do to support our customers.

## Preference Features and Timing

The analysis of preference features helps the company get to know what kinds of functions people enjoy using. And analyzing timing can know the daily work and the rest of the users. Both the analyses empower the company to get a better understanding of the users. 

### Preference features
```{r message=FALSE, warning=FALSE}
##prefer features
ggVennDiagram(list(daily_activity$id, daily_sleep$id, daily_weight$id),
              label = "count",
              label_alpha = 0,
              category.names = c("activity", "sleep", "weight")) +
  scale_fill_gradient(low = "#F4FAFE", high = "#4981BF") + 
  labs(title = "Intersection between activity, sleep, weight usage")
```

According to the dataset:\
* **All** of the user use the feature of **activity tracker.** This can be explained that people pay attention to calories burned mostly.\
* **A high percentage** of people enable the function of **sleep tracker.**\
* Only one-third of users use the feature of **weight tracker.**\

### Average intensity minutes by hour and by the day of week
```{r message=FALSE, warning=FALSE}
intensity.df <- hourly_df %>%
  ungroup() %>%
  mutate(hour = strftime(datetime, format = "%k", "GMT"), week_date = factor(week_date, levels = c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))) %>%
  group_by(week_date, hour) %>%
  summarise(average_intensity = mean(total_intensity))


ggplot(intensity.df, mapping = aes(week_date, hour, fill = average_intensity)) +
  geom_tile(colour = "white") +
  scale_fill_gradient(low = "#f4fff6", high="#0bb730", breaks = c(0,5,15,25)) +
  scale_x_discrete(expand = c(0,0), position = "top") +
  scale_y_discrete(limits = rev) +
  guides(fill = guide_colourbar(title = "Average\nintensity mins."))
```

What we have found:\

* People prefer to **get up early** to exercise on **weekdays** than on weekends.
* **Saturday's** exercise time is concentrated around **noon.**
* The **evening** time seems to be everyone's favorite time to exercise.

## Sleep Quality

The analysis of sleep quality focus on the condition that how long people need to fall asleep. First, we need to identify the level of sleep quality in the dataset. Second, studying their daily behavior to see what makes them different. Finally, finding when people usually have the sleep issue.

### Sleep quality distribution
Using the subtraction of variable total_minutes_asleep and total_time_in_bed, we get the total_minutes_fall_asleep which will be used in our analysis. The graph below shows the sleep quality distribution of the dataset;

```{r sleep distribution, message=FALSE, warning=FALSE}
id.df <- daily_df %>%
  ungroup() %>%
  select(id,total_steps, very_active_minutes, fairly_active_minutes, lightly_active_minutes, sedentary_minutes, calories, total_minutes_asleep, total_minutes_fall_asleep) %>%
  na.omit() %>%
  group_by(id) %>%
  summarise(avg_steps = mean(total_steps), #Calculate the average value by different people
            avg_very_active = mean(very_active_minutes),
            avg_fairly_active = mean(fairly_active_minutes),
            avg_lightly_active = mean(lightly_active_minutes),
            avg_sedentary = mean(sedentary_minutes),
            avg_calories = mean(calories),
            avg_minutes_asleep = mean(total_minutes_asleep),
            avg_fall_asleep = mean(total_minutes_fall_asleep))

#Plot sleep condition by id
id.df %>%
  ggplot(aes(reorder(id,-avg_fall_asleep), avg_fall_asleep)) +
    geom_bar(stat = "identity") + 
    coord_flip() +
    labs(y = "Average minutes to fall asleep",
         x = "id")
```

According to the graph, we decided to divide them into 3 categories; using the median of average minutes to fall asleep to separte them into sleep_well and sleep_normal, and picking the last two id as people who suffer serious sleep issue. The 3 categories are:

* sleep_well (< median)
* sleep_normal (>median)
* sleep_problem (3977333714, 1844505072)\

```{r message=FALSE, warning=FALSE}
#Divide the dataset into three groups: sleep_well, sleep_normal, and sleep_problem
sleep_group <- id.df %>%
  ungroup() %>%
  mutate(id = ifelse(avg_fall_asleep <= median(avg_fall_asleep), "sleep well", "sleep normal")) %>% #categorize into 2 group
  rename(group = id) %>%
  arrange(avg_fall_asleep)
  
#Find the two people who have sleep problem, and put them into sleep_problem grouop
sleep_group[23:24, 1] <- c("sleep problem", "sleep problem")
```
After that, we turn our attention to observing how their usual activities and behavior are different in each group. We assume that something must be different in their daily lifestyle which causes them to need different times to fall asleep.

### Differency in daily behavior by group
```{r message=FALSE, warning=FALSE}
#Plot the average active minutes by type and by group
active <- sleep_group %>%
  group_by(group) %>%
  summarise('very active' = mean(avg_very_active),  #Calculate the average active minutes by group
            'fairly active' = mean(avg_fairly_active),
            'lightly active' = mean(avg_lightly_active)) %>%
  gather(measurement, value, 'very active':'lightly active') %>% #Turn wide table to long table
  mutate(group = factor(group,levels = c("sleep well", "sleep normal", "sleep problem"))) %>% #Create level
  #Plot bar chart
  ggplot(aes(group, value)) +
    geom_bar(aes(fill = reorder(measurement, value)), stat = "identity", position = "dodge") +
    scale_fill_brewer(palette="Dark2") +
    labs(x = "Group", y = "Minutes", fill = "Active Type")  +
    scale_x_discrete(labels=c("Well", "Normal", "Problem"))

#Plot the average steps and  minutes asleep by type and by group
steps_asleep <- sleep_group %>%
  group_by(group) %>%
  summarise(steps = mean(avg_steps),
            asleep = mean(avg_minutes_asleep)) %>%
  gather(measurement, value, steps:asleep) %>%
  mutate(group = factor(group,levels = c("sleep well", "sleep normal", "sleep problem"))) %>%
  #Plot bar chart
  ggplot(aes(group, value)) +
    geom_bar(aes(fill = reorder(measurement, value)), stat = "identity", position = "dodge") +
    scale_fill_brewer(palette="Accent") +
    labs(x = "Group", y = "Minutes", fill = "Usual behavior") +
    scale_x_discrete(labels=c("Well", "Normal", "Problem"))

grid.arrange(active, steps_asleep, nrow = 1)
```

Several interesting findings from the graph above:

* People with **poor sleep quality** usually do **less very active exercise.**
* The **effect of fair activity and lightly activity** on sleep quality is **unclear.** There is no obvious pattern.
* The **less you walk** each day, the more likely you are to have **poor sleep quality.**
* People who are more prone to **insomnia** need **more sleep time.** This may imply reduced sleep efficiency.

It is valuable to discover that each group has a different daily routine and preference for different types of activities. Based on the information we have, the easiest way to move someone in the sleep problem group is to do more very active exercise and walk more every day. Next, the time variable in the dataset allows us to investigate how long it takes people to fall asleep on a different day of the week.

### Sleep quality in the day of week
```{r message=FALSE, warning=FALSE}
#Patterns for different day of a week 
#install.packages("viridisLite")
library(viridis)

daily_df %>%
  #set level to the day of week
  mutate(week_date = factor(week_date, levels = c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"))) %>%
  #summarise average value to the day of week
  group_by(week_date) %>% 
  summarise(avg_fall_asleep = mean(total_minutes_fall_asleep, na.rm = TRUE), 
            avg_steps = mean(total_steps, na.rm = TRUE),
            avg_sedentary = mean(sedentary_minutes, na.rm = TRUE),
            avg_calories = mean(calories, na.rm = TRUE)) %>%
  arrange(week_date) %>%
  #plot the bar graph
  ggplot(aes(week_date,avg_fall_asleep, fill = avg_fall_asleep))+
  geom_bar(stat = "identity")+
  #scale_fill_viridis(option = "I", "Average minutes\nto fall asleep") +
  scale_fill_gradient(low = "#e1bd70", high="#64cfc1") +
  labs(title = "Minutes To Fall Asleep",
       subtitle = "Average minutes to fall asleep by the day of week",
       x = "Day-of-Week",
       y = "Average minutes to fall asleep") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, color = "grey54"))

```

According to the bar graph that shows the average minutes needed to fall asleep by the day of the week:

* **Sunday** is the day when everyone has the **most insomnia tendency.**
* Between Mondays to Saturdays, people tend to **sleep better** on **Thursdays.**


## Calories Burn

The analysis of calories burn focuses on the relationship between different activities and calories burn, and studies what activities are most effective for burning calories. Additionally, we look into the results and benefits for people who follow the daily activity target according to medical research.

### Relationship between different activities and calories burn
```{r message=FALSE, warning=FALSE}
#Conduct correlation plot between activities and calories
steps.cor <- daily_df %>%
   ggplot(aes(total_steps, calories)) +
   geom_smooth(method = "lm", alpha = 0.2, color = "cyan3") +
   geom_point(alpha = 0.1) +
   labs(x = "Total steps")

v_active.cor <- daily_df %>%
   ggplot(aes(very_active_minutes, calories)) +
   geom_smooth(method = "lm", alpha = 0.2, color = "cyan3") +
   geom_point(alpha = 0.1) +
   labs(x = "Very active minutes")

f_active.cor <- daily_df %>%
   ggplot(aes(fairly_active_minutes, calories)) +
   geom_smooth(method = "lm", alpha = 0.2, color = "deepskyblue3") +
   geom_point(alpha = 0.1) +
   labs(x = "Fairly active minutes")

l_active.cor <- daily_df %>%
   ggplot(aes(lightly_active_minutes, calories)) +
   geom_smooth(method = "lm", alpha = 0.2, color = "deepskyblue3") +
   geom_point(alpha = 0.1) +
   labs(x = "Lightly active minutes")

sedentary.cor <- daily_df %>%
   ggplot(aes(sedentary_minutes, calories)) +
   geom_smooth(method = "lm", alpha = 0.2, color = "grey15") +
   geom_point(alpha = 0.1) +
   labs(x = "Sedentary minutes")


grid.arrange(steps.cor, v_active.cor, f_active.cor, l_active.cor, sedentary.cor, nrow = 2)

```

Insights from the correlation plot between daily activities to calories burn:

* **Total Steps** and **Very Active Minutes** show the **strongest relationship to Calories.**
* **Fairly Active** and **Lightly Active Minutes** also show **positive relationship.**
* **Sedentary Minutes** shows a **negative effect** to Calories

The results from the dataset match the intuition that we can burn more calories as long as we are willing to exercise rather than sit in front of the computer. However, since each variable affects the other in a certain way, it is hard to tell how efficient each variable is for burning calories. Therefore, we decided to use a linear regression model to see the effect of each variable on calorie burn.

### Efficiency for burning calories
```{r message=FALSE, warning=FALSE}
#Prepare the dataset for linear regression model
l.df <- daily_df %>%
  ungroup() %>%
  mutate(total_steps_100 = total_steps/100) %>% #Divide total steps by 100 to make it comparable. 100 steps take about 1 minute.
  select(total_steps_100, very_active_minutes, fairly_active_minutes, lightly_active_minutes, calories)
  
#Conduct a linear regression model
l.model <- lm(calories ~., data = l.df)

#Plot the value of each coefficient 
coefplot(l.model, intercept = FALSE, outerCI = 0, lwdInner = 0.5) +
  scale_y_discrete(labels=c("Every 100 Steps", "Very Active mins.", "Fairly Active mins.", "Lightly Active mins.")) +
  labs(x = "Estimate and 95% Conf. Int.",
       y = "",
       title = "Coefficient Plot",
       subtitle = "Estimate the effect of different Activities on Calories ") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, color = "grey54"))
```

The linear regression formula\

$Calories = 1676.52 + 1.22 * Lightly Active(mins.) + 1.92 * Fairly Active(mins.) + 11.13 * Very Active(mins.) + 1.74 * Steps(100)$

Through the coefficient graph, we can easily find that:\

* **Very Active** has the **strongest** effect on Calories burning. The coefficient of 11.13 suggests that a minute of very active exercise will burn 11.13 calories. This is the most efficient way to burn calories.
* **Lightly Active** and **Fairly Active** both have a **similar** effect on Calorie burn. 
* It is interesting to see that **Walking** is about as efficient as **Fairly Active.** Although it is just the third most efficient way to burn calories by the number, walking is the simplest and easiest exercise to do.

After knowing the efficiency of each exercise for calorie reduction, we wonder if people who meed the medical advice (for example, walk 10000 steps a day or do fairly exercises for more than 30 minutes a day) burn more calories on average.

### The prove and the benefit of following medical advice
```{r message=FALSE, warning=FALSE}
daily_df %>%
  ungroup() %>%
  select(total_steps, calories) %>%
  na.omit() %>%
  mutate(over_7000 = ifelse(total_steps >= 10000, "more", "less")) %>% #According to medical researches, taking 10,000 steps a day helps your health
  ggplot(aes(x = over_7000, y = calories, fill = over_7000)) +
    geom_violin() +
    stat_summary(fun = "mean",
               geom = "point",
               aes(color = "Mean")) +
    stat_summary(fun = "median",
               geom = "point",
               aes(color = "Median")) +
    scale_colour_manual(values = c("darkorchid2", "blue"), name = "") +
    labs(title = "Calories Burn when Walking More than 10000 steps",
         subtitle = "How many calories are burned on average\nfor people walk more than 10000 steps a day or not",
         x = "Steps less than & more than 10000",
         y = "Calories") +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, color = "grey54")) +
    guides(fill = FALSE)
```
```{r message=FALSE, warning=FALSE}
daily_df %>%
  ungroup() %>%
  select(fairly_active_minutes, calories) %>%
  na.omit() %>%
  mutate(over_30 = ifelse(fairly_active_minutes >= 30, "more", "less")) %>%
  ggplot(aes(x = over_30, y = calories, fill = over_30)) +
    geom_violin() +
    stat_summary(fun = "mean",
               geom = "point",
               aes(color = "Mean")) +
    stat_summary(fun = "median",
               geom = "point",
               aes(color = "Median")) +
    scale_colour_manual(values = c("darkorchid2", "blue"), name = "") +
    labs(title = "Calories Burn when Fairly Active for More than 30 minutes",
         subtitle = "How many calories are burned on average\nfor people fairly active more than 30 minutes a day or not",
         x = "Fairly active less than & more than 30 minutes",
         y = "Calories") +
    theme(plot.title = element_text(hjust = 0.5, face = "bold"),
          plot.subtitle = element_text(hjust = 0.5, color = "grey54")) +
    guides(fill = FALSE)
```

From both the graph above:\

* It is obvious that those who met medical recommendations **burned more calories** on average.
* The benefits are not only in the average, but also in the steady calorie consumption.

# Conclusion

***

<font size="5">   :mag_right: </font> <font size="3"> **Activity feature** is **most commonly used** by fitness tracker's users, followed by Sleep feature. The **least used** feature is **weight tracking**.</font>\
\
<font size="5">   :mag_right: </font> <font size="3"> People with **poor sleep quality** usually do **less very active exercise**, **walk less**, and **need longer sleep.** The study shows that the sample has a significant **tendency to insomnia on Sundays**</font>\
\
<font size="5">   :mag_right: </font> <font size="3"> People have generally preferred exercise times. **Intense exercise** is indeed the **most efficient** for calorie burning, but completing **a certain level of fair exercise and steps** can also significantly **help burn calories**</font>\

# Recommendation

***
<font size="3">
Based on these findings my recommendations to the company would be:\

* **Collect the qualitative data to know why users have a preference for one feature but not another.** Qualitative data, which could be collected through questionnaires or focus groups, is good to understand the reasons and motivations that drive certain behavior.
* **Send notification through the Bellabeat app for people with poor sleep quality;** show the recent sleep condition and remind them to do more exercise.
* **Deliver motivational messages before and after exercise** based on each person's preferred exercise time.
* **Add milestones or functions that can set goals in the app** to allow users to actively complete their exercise goals.
</font>\
\
  
  

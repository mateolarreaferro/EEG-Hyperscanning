library(car)
options(scipen=999)
library(ggplot2)
library(dplyr)
library(ggpubr)
library(broom)
library(rstatix)
library(emmeans)
library(reshape2)
library(tidyr)
library(emmeans)

#http://singmann.org/anova-in-r-afex-may-be-the-solution-you-are-looking-for/
#https://cran.r-project.org/web/packages/afex/vignettes/afex_anova_example.html#post-hoc-contrasts-and-plotting
library(afex)

# output Anova table in APA format
library(apa)

# R version 4.4.3 (2025-02-28 ucrt) -- "Trophy Case"
# Copyright (C) 2025 The R Foundation for Statistical Computing
# Platform: x86_64-w64-mingw32/x64

# go to the working directory
setwd('C:/Users/tfujioka/Documents/MATLAB/451C_W26_practice/')
# read in the data (made by do_4a)
dat1 <- read.table(file = "FRN_P3a_amp_20260127.txt", header = TRUE) 
# NaN replaced with 0, Subj NA replaced with NxA

# check out data structure
str(dat1)

# print out the first few rows of the dataset
head(dat1)


# re-order conditions within a factor (rather than appearing alphabetically by default)
dat1$partner <- factor(dat1$partner, levels = c("Human","Comp"))
dat1$agency <- factor(dat1$agency, levels = c("Self","Other"))
dat1$melody <- factor(dat1$melody, levels = c("Same","Diff"))

# # tricks to make another variable with re-named conditions within a factor 
# dat1$ModalityD <-ifelse(dat1$Modality=="Av","A",(ifelse(dat1$Modality =="AvT", "AT","T")))
# # tricks to re-name a factor and the conditions names
# dat1$Exp<-ifelse(dat1$Group=="NH1","Exp1","Exp2")
# dat1$GroupE<-ifelse(dat1$Group=="CI2","CI","NH")

# ANOVA 
# three within-subject factors (if you have different groups of people, use 'between =')
a1<-aov_ez(id="subjID", 
               dv="FRN",
               dat1,
               within = c("partner", "agency", "melody"), 
               factorize = FALSE)

# Print out the results with effect size 'eta squared'  (ges is generalized eta squared)
# # see here for different types of eta squared 
# https://cran.r-project.org/web/packages/effectsize/vignettes/anovaES.html
anova_apa(a1, es = "ges") # you can do 
# Effect                                           
# 1           (Intercept) F(1, 3) = 7.00, p = .077, getasq =  NA .  
# 2               partner F(1, 3) = 0.76, p = .447, getasq = .01    
# 3                agency F(1, 3) = 2.03, p = .249, getasq = .17    
# 4                melody F(1, 3) = 0.00, p = .987, getasq < .01    
# 5        partner:agency F(1, 3) = 0.06, p = .816, getasq < .01    
# 6        partner:melody F(1, 3) = 5.13, p = .108, getasq < .01    
# 7         agency:melody F(1, 3) = 0.09, p = .783, getasq < .01    
# 8 partner:agency:melody F(1, 3) = 1.23, p = .348, getasq < .01  


# residual normality?
model_residuals <- residuals(a1)
qqnorm(model_residuals)
qqline(model_residuals)
# when the majority of the dots are on the line, sort of 'normal'
# on both ends there are dots outside of the line. But the point is to see
# the nice alignment (rather than too wavy and outside things) in the middle



### Post-hoc (in real, do this only for each significant effect)#####

# if one of the main effects is significant, do the post-hoc test 
# only when the factor has 3 or more conditions (if it's two, you don't need to compare
# because the ANOVA already covers it)

# partner
es1 <- emmeans(a1, c("partner"))
es1
# partner emmean    SE df lower.CL upper.CL
# Human    -1.97 0.796  3    -4.50    0.563
# Comp     -1.61 0.606  3    -3.54    0.317
# 
# Results are averaged over the levels of: melody, agency 
# Confidence level used: 0.95 
update(pairs(es1), by=NULL, adjust = "Bonferroni")
# contrast     estimate    SE df t.ratio p.value
# Human - Comp   -0.359 0.411  3  -0.872  0.4474
# 
# Results are averaged over the levels of: melody, agency 

# two way interaction partner x melody
#
es2 <- emmeans(a1, c("partner"), by="melody")
es2
# melody = Same:
#   partner emmean    SE df lower.CL upper.CL
# Human    -2.08 0.679  3    -4.24   0.0839
# Comp     -1.51 0.450  3    -2.94  -0.0819
# 
# melody = Diff:
#   partner emmean    SE df lower.CL upper.CL
# Human    -1.86 0.949  3    -4.88   1.1547
# Comp     -1.71 0.767  3    -4.15   0.7282
# 
# Results are averaged over the levels of: agency 
# Confidence level used: 0.95 

# slice by melody and see the partner difference for each melody condition
update(pairs(es2), c("partner"), by="melody", adjust = "Bonferroni")
# melody = Same:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp   -0.564 0.485  3  -1.162  0.3293
# 
# melody = Diff:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp   -0.153 0.345  3  -0.444  0.6869
# 
# Results are averaged over the levels of: agency

# slicing by partner and make a contrast of melody
es3 <- emmeans(a1, c("melody"), by="partner")
es3
update(pairs(es3), c("melody"), by="partner", adjust = "Bonferroni")

## if 3-way interaction is significant
es4m <- emmeans(a1, c("melody"), by=c("partner", "agency"))
es4m
# partner = Human, agency = Self:
#   melody emmean    SE df lower.CL upper.CL
# Same   -2.887 1.140  3    -6.50    0.728
# Diff   -2.512 1.520  3    -7.34    2.315
# 
# partner = Comp, agency = Self:
#   melody emmean    SE df lower.CL upper.CL
# Same   -2.019 0.809  3    -4.59    0.556
# Diff   -2.580 1.290  3    -6.70    1.541
# 
# partner = Human, agency = Other:
#   melody emmean    SE df lower.CL upper.CL
# Same   -1.266 0.225  3    -1.98   -0.549
# Diff   -1.217 0.417  3    -2.55    0.111
# 
# partner = Comp, agency = Other:
#   melody emmean    SE df lower.CL upper.CL
# Same   -1.007 0.622  3    -2.99    0.973
# Diff   -0.843 0.359  3    -1.99    0.301
# 
# Confidence level used: 0.95 
update(pairs(es4m), c("melody"), by=c("partner","agency"), adjust = "Bonferroni")
# partner = Human, agency = Self:
#   contrast    estimate    SE df t.ratio p.value
# Same - Diff   -0.375 0.718  3  -0.522  0.6376
# 
# partner = Comp, agency = Self:
#   contrast    estimate    SE df t.ratio p.value
# Same - Diff    0.561 0.698  3   0.803  0.4805
# 
# partner = Human, agency = Other:
#   contrast    estimate    SE df t.ratio p.value
# Same - Diff   -0.049 0.217  3  -0.226  0.8358
# 
# partner = Comp, agency = Other:
#   contrast    estimate    SE df t.ratio p.value
# Same - Diff   -0.164 0.455  3  -0.361  0.7420

# in the above constrast, the 'melody' was the key for the contrasts
# for each of the other two other factors

# Of course you can do three different ways to combine the factors

# contast of agency
es4a <- emmeans(a1, c("agency"), by=c("partner", "melody"))
es4a
update(pairs(es4a), c("agency"), by=c("partner","melody"), adjust = "Bonferroni")
# partner = Human, melody = Same:
#   contrast     estimate    SE df t.ratio p.value
# Self - Other    -1.62 0.916  3  -1.769  0.1750
# 
# partner = Comp, melody = Same:
#   contrast     estimate    SE df t.ratio p.value
# Self - Other    -1.01 1.130  3  -0.896  0.4362
# 
# partner = Human, melody = Diff:
#   contrast     estimate    SE df t.ratio p.value
# Self - Other    -1.30 1.160  3  -1.115  0.3462
# 
# partner = Comp, melody = Diff:
#   contrast     estimate    SE df t.ratio p.value
# Self - Other    -1.74 1.120  3  -1.547  0.2197

# contrast of partner
es4p <- emmeans(a1, c("partner"), by=c("agency", "melody"))
es4p
update(pairs(es4p), c("partner"), by=c("agency","melody"), adjust = "Bonferroni")
# agency = Self, melody = Same:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp  -0.8685 0.456  3  -1.906  0.1528
# 
# agency = Other, melody = Same:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp  -0.2590 0.700  3  -0.370  0.7360
# 
# agency = Self, melody = Diff:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp   0.0675 0.332  3   0.203  0.8519
# 
# agency = Other, melody = Diff:
#   contrast     estimate    SE df t.ratio p.value
# Human - Comp  -0.3743 0.484  3  -0.773  0.4957

### plotting data 

# to show the 3-way interaction 
#https://cran.r-project.org/web/packages/afex/vignettes/afex_plot_introduction.html#two-way-within-subjects-anova
p1 <- afex_plot(a1, x = "melody", trace ="partner", error = "within", panel="agency")
p1
p1 <-afex_plot(a1, x = "melody", trace ="partner", error = "within", panel="agency",
               legend_title = "Partner")
p1
# see the legend title text is now 'Partner'
# see no y-axis or x-axis title

p1<-p1+
  labs(y = expression(paste("FRN (", mu, "V)")),x="Melody type") +
  theme_bw() + 
  theme(legend.position="bottom")
p1
# now theme_bw made it the plot background white instead of gray
# y-axis and x-axis title are there 

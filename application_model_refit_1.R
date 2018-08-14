library(xgboost)
library(data.table)
library(caret)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")

app_data_1 <- fread("app_data_refit_1.csv")
app_data_2 <- fread("app_data_refit_2.csv")
app_data_3 <- fread("app_data_refit_3.csv")
app_data_4 <- fread("app_data_refit_4.csv")

app_data <- rbind(app_data_1, app_data_2, app_data_3, app_data_4)

rm(app_data_1)
rm(app_data_2)
rm(app_data_3)
rm(app_data_4)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
write.csv(app_data, file = "kaggle_app_data_refit_1.csv")

# app_data <- fread("kaggle_app_data_refit_1.csv")

#### XGBoosting ####
app_model_data <- app_data[,!(colnames(app_data) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
app_model_data <- app_model_data[!is.na(target)]
app_model_target <- app_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_matrix <- model.matrix(~.+0,data = app_model_data[,-c("target"),with=F])
app_model_matrix <- xgb.DMatrix(data = app_model_matrix,label = app_model_target)

# this was your silly stupid model the first time. Where's it at now?
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=5, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=75, subsample=0.8, colsample_bytree=0.8, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 12, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # max_leaves = 100
        # [12]	train-auc:0.800803+0.002071	test-auc:0.745737+0.001812
    # max_leaves = 500
        # [6]	train-auc:0.817475+0.002774	test-auc:0.726697+0.000453
    # max_leaves = 255, subsample=0.67, colsample_bytree=0.67
        # [9]	train-auc:0.850696+0.002108	test-auc:0.755059+0.000124
    # max_leaves = 255, subsample=0.67, colsample_bytree=0.67, gamma=2.5, min_child_weight=25
        # [12]	train-auc:0.862853+0.001459	test-auc:0.761518+0.002367
    # above, plus eta = 0.25
        # [12]	train-auc:0.848702+0.001258	test-auc:0.764145+0.000657
    # max_leaves = 511, min_child_weight = 50
        # [12]	train-auc:0.821678+0.001518	test-auc:0.767680+0.000533
    # now drop eta to .175
        # [12]	train-auc:0.812722+0.001567	test-auc:0.766722+0.000480
    # max_leaves = 1023, min_child_weight = 75
        # [12]	train-auc:0.800761+0.001347	test-auc:0.766876+0.000734
    # now drop eta to .1
        # [12]	train-auc:0.792664+0.001686	test-auc:0.763375+0.001240
    # subsample=0.8, colsample_bytree=0.8
        # [12]	train-auc:0.798804+0.002081	test-auc:0.763975+0.001405
    # gamma = 5
        # [12]	train-auc:0.786430+0.002093	test-auc:0.761186+0.000228 
    # eta = .05
        # [12]	train-auc:0.778355+0.002859	test-auc:0.757715+0.000345
    # run latest for an hour and see where it lands.
        # 1 round:  37.45
        # 3 rounds: 44.287   (so maybe 35 seconds of fixed time, plus 3 seconds per round)

ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=5, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=75, subsample=0.8, colsample_bytree=0.8, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 1000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    #   [50]	train-auc:0.786665+0.001055	test-auc:0.762693+0.001084 
    #   [100]	train-auc:0.800783+0.001274	test-auc:0.768862+0.001263 
    #   [250]	train-auc:0.839933+0.001405	test-auc:0.785222+0.001107
    #   [500]	train-auc:0.887031+0.001064	test-auc:0.791583+0.001531
    #   [622]	train-auc:0.904367+0.000931	test-auc:0.792247+0.001505  peak


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=7, max_depth=0, max_leaves=750, grow_policy="lossguide", min_child_weight=100, subsample=0.8, colsample_bytree=0.8, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 1000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [50]	train-auc:0.776215+0.001326	test-auc:0.759424+0.000788 
    # [100]	train-auc:0.788440+0.001083	test-auc:0.766002+0.001047 
    # [250]	train-auc:0.823031+0.001276	test-auc:0.783740+0.000907 
    # [500]	train-auc:0.861034+0.001526	test-auc:0.791493+0.001067 
    # [753]	train-auc:0.887836+0.001112	test-auc:0.792656+0.001344 peak


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=10, max_depth=0, max_leaves=511, grow_policy="lossguide", min_child_weight=150, subsample=0.8, colsample_bytree=0.8, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 1000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [50]	train-auc:0.767912+0.001385	test-auc:0.756069+0.000899 
    # [100]	train-auc:0.778062+0.001058	test-auc:0.762593+0.001170 
    # [250]	train-auc:0.806812+0.001222	test-auc:0.781007+0.000910 
    # [500]	train-auc:0.831474+0.001547	test-auc:0.789959+0.001169 
    #[1000] train-auc:0.857469+0.001965	test-auc:0.792719+0.001239   still increasing at minute pace


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=10, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=40, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [2914]	train-auc:0.943108+0.000989	test-auc:0.794874+0.000441    peak


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=40, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=160, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [3402]	train-auc:0.789271+0.000295	test-auc:0.777384+0.00081    massively overcompensated


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=12.5, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [2841]	train-auc:0.890955+0.005494	test-auc:0.795023+0.000434   no further gain


    # cut max leaves instead of increasing gamma, etc.
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=10, max_depth=0, max_leaves=800, grow_policy="lossguide", min_child_weight=40, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [1001]	train-auc:0.858310+0.001187	test-auc:0.786914+0.000222
    # [2001]	train-auc:0.916719+0.001544	test-auc:0.794242+0.000421
    # [2741]	train-auc:0.939302+0.001171	test-auc:0.794916+0.000442  peak


# increase gamma/weight, iterate max_leaves downward.
    # both of these adjustments helped, previously.
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=11.5, max_depth=0, max_leaves=700, grow_policy="lossguide", min_child_weight=46, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [501] 	train-auc:0.801672+0.001484	test-auc:0.770201+0.000157
    # [1001]	train-auc:0.842135+0.001016	test-auc:0.786120+0.000353
    # [2001]	train-auc:0.890528+0.001354	test-auc:0.794139+0.000531 
    # [2821]	train-auc:0.908972+0.004472	test-auc:0.795243+0.000520  stops iterating, also peak


# increase gamma/weight, iterate max_leaves downward.
    # both of these adjustments helped, previously. also, circling back to 12.5 / 50 but with fewer max_leaves.
    # next try same max_leaves with 10/150 gamma and weight split
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=12.5, max_depth=0, max_leaves=511, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [501]	    train-auc:0.797158+0.001362	test-auc:0.769162+0.000344
    # [1001]	train-auc:0.833745+0.001076	test-auc:0.785378+0.000483 
    # [2001]	train-auc:0.875409+0.001578	test-auc:0.793856+0.000554 
    # [2841]	train-auc:0.890955+0.005494	test-auc:0.795023+0.000434    stops iterating, also the peak


    # run this overnight, see if it cracks 0.795243
    # unless it's somehow worse, run it on your 8 data sets and go with those. You have spent enough time on this already....
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10, max_depth=0, max_leaves=725, grow_policy="lossguide", min_child_weight=40, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 5000, nfold = 2, showsd = T, stratified = T, print_every_n = 20, maximize = F)
print(proc.time() - ptm)
    # [5000]	train-auc:0.944375+0.000736	test-auc:0.795121+0.000609  still improving .000003 or so per iter
    # I think I may have overcorrected gamma for the eta drop



ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 7500, nfold = 2, showsd = T, stratified = T, print_every_n = 20, maximize = F)
print(proc.time() - ptm)
    # [101]	    train-auc:0.767177+0.000875	test-auc:0.751262+0.000250 
    # [501]	    train-auc:0.787208+0.000591	test-auc:0.762841+0.000562 
    # [1001]	train-auc:0.815295+0.000748	test-auc:0.774936+0.000497 
    # [2001]	train-auc:0.863445+0.001134	test-auc:0.789827+0.000344
    # [3001]	train-auc:0.894983+0.001493	test-auc:0.793776+0.000490
    # [4001]	train-auc:0.915995+0.001088	test-auc:0.795036+0.000621
    # [5001]	train-auc:0.927819+0.003629	test-auc:0.795354+0.000560 
    # [5221]	train-auc:0.929067+0.004878	test-auc:0.795370+0.000544  peak, test starts dropping after

    # above looks like a winner. I just want to be really sure I didn't overcompensate on shifting gamma down. Maybe there's a .7955 in here? Nudge eta down another little touch, but either *this* or the other. No more tweaking for 4 more days.
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.0025, gamma=11.25, max_depth=0, max_leaves=705, grow_policy="lossguide", min_child_weight=45, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 7500, nfold = 2, showsd = T, stratified = T, print_every_n = 25, maximize = F)
print(proc.time() - ptm)
    # final answer is, you're not using these parameters. 
    # [5876]	train-auc:0.915429+0.004821	test-auc:0.795291+0.000515  flatlines, and then drops. Let it run another 600 rounds and it was all the way down to 0.795265


    # okay, now build a model. Exciting stuff
ptm <- proc.time()
set.seed(102478)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_overall <- xgb.train(params = params, data = app_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_overall, file="app_model_overall_xbg.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = app_model_overall)
head(importance, n=50)
write.csv(importance, file="app_model_overall_importance.csv")


# Predict on all loans, send test group scores
#### XGBoosting ####
app_model_data_overall <- app_data[,(colnames(app_data) %in% c(app_model_overall$feature_names, "target")), with=FALSE]

# Begin by fitting an XGBoost on everything except 
app_model_data_overall_target <- app_model_data_overall$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_matrix_overall <- model.matrix(~.+0,data = app_model_data_overall[,-c("target"),with=F])
app_model_matrix_overall <- xgb.DMatrix(data = app_model_matrix_overall,label = app_model_data_overall_target)

app_data$app_model_overall_response <- predict(app_model_overall, app_model_matrix_overall, type="response")

# quick sanity check of ranking and default
app_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(app_model_overall_response,c(-Inf,quantile(app_model_overall_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
temp_cut <- quantile(app_data$app_model_overall_response,probs=seq(.1,1,.1), na.rm=TRUE)
app_data$app_model_cut <- findInterval(app_data$app_model_overall_response, temp_cut)
app_data[is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),by=app_model_cut][order(app_model_cut)]


# see if this format is identical to what you need to submit
app_model_overall_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(app_model_overall_xgb_model_submission) <- c("sk_id_curr", "target")

app_model_overall_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
app_model_overall_xgb_model_submission$target <- app_data[is.na(target)]$app_model_overall_response

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(app_model_overall_xgb_model_submission, file="app_model_overall_submission_20180717.csv")



# Resampled on ext_source_3 training data.
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/alternate_application_samples")
# source_3_data <- fread("app_data_ext_source_3_sampled.csv")
load("app_data_ext_source_3_sampled.rdata")

#### XGBoosting ####
source_3_model_data <- app_data_ext_source_3_sampled[,!(colnames(app_data_ext_source_3_sampled) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
source_3_model_data <- source_3_model_data[!is.na(target)]
source_3_model_target <- source_3_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
source_3_model_matrix <- model.matrix(~.+0,data = source_3_model_data[,-c("target"),with=F])
source_3_model_matrix <- xgb.DMatrix(data = source_3_model_matrix,label = source_3_model_target)


ptm <- proc.time()
set.seed(102478)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_source_3_sampled_overall <- xgb.train(params = params, data = source_3_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_source_3_sampled_overall, file="app_model_source_3_xbg.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = app_model_source_3_sampled_overall)
head(importance, n=50)
write.csv(importance, file="app_model_source_3_importance.csv")



# Predict on all loans, send test group scores
#### XGBoosting ####
app_model_source_3_data_overall <- app_data[,(colnames(app_data) %in% c(app_model_source_3_sampled_overall$feature_names, "target")), with=FALSE]

# Begin by fitting an XGBoost on everything except 
app_model_source_3_data_overall_target <- app_model_source_3_data_overall$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_source_3_matrix_overall <- model.matrix(~.+0,data = app_model_source_3_data_overall[,-c("target"),with=F])
app_model_source_3_matrix_overall <- xgb.DMatrix(data = app_model_source_3_matrix_overall,label = app_model_source_3_data_overall_target)

app_data$app_model_source_3_overall_response <- predict(app_model_source_3_sampled_overall, app_model_source_3_matrix_overall, type="response")

# quick sanity check of ranking and default
app_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(app_model_source_3_overall_response,c(-Inf,quantile(app_model_source_3_overall_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
temp_cut <- quantile(app_data$app_model_overall_response,probs=seq(.1,1,.1), na.rm=TRUE)
app_data$app_model_cut <- findInterval(app_data$app_model_overall_response, temp_cut)
app_data[is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),by=app_model_cut][order(app_model_cut)]


# see if this format is identical to what you need to submit
app_model_source_3_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(app_model_source_3_xgb_model_submission) <- c("sk_id_curr", "target")

app_model_source_3_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
app_model_source_3_xgb_model_submission$target <- app_data[is.na(target)]$app_model_source_3_overall_response

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(app_model_source_3_xgb_model_submission, file="app_model_source_3_xgb_model_submission_20180718.csv")










# Resampled on ext_source_2 training data.
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/alternate_application_samples")
load("app_data_ext_source_2_sampled.rdata")


#### XGBoosting ####
source_2_model_data <- app_data_ext_source_2_sampled[,!(colnames(app_data_ext_source_2_sampled) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
source_2_model_data <- source_2_model_data[!is.na(target)]
source_2_model_target <- source_2_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
source_2_model_matrix <- model.matrix(~.+0,data = source_2_model_data[,-c("target"),with=F])
source_2_model_matrix <- xgb.DMatrix(data = source_2_model_matrix,label = source_2_model_target)

ptm <- proc.time()
set.seed(072447)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_source_2_sampled_overall <- xgb.train(params = params, data = source_2_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_source_2_sampled_overall, file="app_model_source_2_xbg.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = app_model_source_2_sampled_overall)
head(importance, n=50)
write.csv(importance, file="app_model_source_2_importance.csv")



# Predict on all loans, send test group scores
#### XGBoosting ####
app_model_source_2_data_overall <- app_data[,(colnames(app_data) %in% c(app_model_source_2_sampled_overall$feature_names, "target")), with=FALSE]

# Begin by fitting an XGBoost on everything except 
app_model_source_2_data_overall_target <- app_model_source_2_data_overall$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_source_2_matrix_overall <- model.matrix(~.+0,data = app_model_source_2_data_overall[,-c("target"),with=F])
app_model_source_2_matrix_overall <- xgb.DMatrix(data = app_model_source_2_matrix_overall,label = app_model_source_2_data_overall_target)

ptm <- proc.time()
app_data$app_model_source_2_overall_response <- predict(app_model_source_2_sampled_overall, app_model_source_2_matrix_overall, type="response")
print(proc.time() - ptm)

# quick sanity check of ranking and default
app_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(app_model_source_2_overall_response,c(-Inf,quantile(app_model_source_2_overall_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
temp_cut <- quantile(app_data$app_model_overall_response,probs=seq(.1,1,.1), na.rm=TRUE)
app_data$app_model_cut <- findInterval(app_data$app_model_overall_response, temp_cut)
app_data[is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),by=app_model_cut][order(app_model_cut)]


# see if this format is identical to what you need to submit
app_model_source_2_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(app_model_source_2_xgb_model_submission) <- c("sk_id_curr", "target")

app_model_source_2_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
app_model_source_2_xgb_model_submission$target <- app_data[is.na(target)]$app_model_source_2_overall_response

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(app_model_source_2_xgb_model_submission, file="app_model_source_2_xgb_model_submission_20180718.csv")




# Resampled on ext_source_1 training data.
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/alternate_application_samples")
load("app_data_ext_source_1_sampled.rdata")


#### XGBoosting ####
source_1_model_data <- app_data_ext_source_1_sampled[,!(colnames(app_data_ext_source_1_sampled) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
source_1_model_data <- source_1_model_data[!is.na(target)]
source_1_model_target <- source_1_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
source_1_model_matrix <- model.matrix(~.+0,data = source_1_model_data[,-c("target"),with=F])
source_1_model_matrix <- xgb.DMatrix(data = source_1_model_matrix,label = source_1_model_target)

ptm <- proc.time()
set.seed(021745)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_source_1_sampled_overall <- xgb.train(params = params, data = source_1_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_source_1_sampled_overall, file="app_model_source_1_xbg.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = app_model_source_1_sampled_overall)
head(importance, n=50)
write.csv(importance, file="app_model_source_1_importance.csv")



# Predict on all loans, send test group scores
#### XGBoosting ####
app_model_source_1_data_overall <- app_data[,(colnames(app_data) %in% c(app_model_source_1_sampled_overall$feature_names, "target")), with=FALSE]

# Begin by fitting an XGBoost on everything except 
app_model_source_1_data_overall_target <- app_model_source_1_data_overall$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_source_1_matrix_overall <- model.matrix(~.+0,data = app_model_source_1_data_overall[,-c("target"),with=F])
app_model_source_1_matrix_overall <- xgb.DMatrix(data = app_model_source_1_matrix_overall,label = app_model_source_1_data_overall_target)

ptm <- proc.time()
app_data$app_model_source_1_overall_response <- predict(app_model_source_1_sampled_overall, app_model_source_1_matrix_overall, type="response")
print(proc.time() - ptm)

# quick sanity check of ranking and default
app_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(app_model_source_2_overall_response,c(-Inf,quantile(app_model_source_2_overall_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
temp_cut <- quantile(app_data$app_model_overall_response,probs=seq(.1,1,.1), na.rm=TRUE)
app_data$app_model_cut <- findInterval(app_data$app_model_overall_response, temp_cut)
app_data[is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),by=app_model_cut][order(app_model_cut)]


# see if this format is identical to what you need to submit
app_model_source_2_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(app_model_source_2_xgb_model_submission) <- c("sk_id_curr", "target")

app_model_source_2_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
app_model_source_2_xgb_model_submission$target <- app_data[is.na(target)]$app_model_source_2_overall_response

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(app_model_source_2_xgb_model_submission, file="app_model_source_2_xgb_model_submission_20180718.csv")








#### XGBoosting ####
amt_credit_model_data <- app_data_amt_credit_sampled[,!(colnames(app_data_amt_credit_sampled) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
amt_credit_model_data <- amt_credit_model_data[!is.na(target)]
amt_credit_model_target <- amt_credit_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
amt_credit_model_matrix <- model.matrix(~.+0,data = amt_credit_model_data[,-c("target"),with=F])
amt_credit_model_matrix <- xgb.DMatrix(data = amt_credit_model_matrix,label = amt_credit_model_target)

ptm <- proc.time()
set.seed(021745)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_amt_credit_sampled_overall <- xgb.train(params = params, data = amt_credit_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_amt_credit_sampled_overall, file="app_model_amt_credit_xbg.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = app_model_amt_credit_sampled_overall)
head(importance, n=50)
write.csv(importance, file="app_model_amt_credit_importance.csv")



# Predict on all loans, send test group scores
#### XGBoosting ####
app_model_amt_credit_data_overall <- app_data[,(colnames(app_data) %in% c(app_model_amt_credit_sampled_overall$feature_names, "target")), with=FALSE]

# Begin by fitting an XGBoost on everything except 
app_model_amt_credit_data_overall_target <- app_model_amt_credit_data_overall$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_amt_credit_matrix_overall <- model.matrix(~.+0,data = app_model_amt_credit_data_overall[,-c("target"),with=F])
app_model_amt_credit_matrix_overall <- xgb.DMatrix(data = app_model_amt_credit_matrix_overall,label = app_model_amt_credit_data_overall_target)

ptm <- proc.time()
app_data$app_model_amt_credit_overall_response <- predict(app_model_amt_credit_sampled_overall, app_model_amt_credit_matrix_overall, type="response")
print(proc.time() - ptm)
app_model_amt_credit_overall_response <- app_data$app_model_amt_credit_overall_response
# app_data$app_model_amt_credit_overall_response <- app_model_amt_credit_overall_response

# quick sanity check of ranking and default
app_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(app_model_amt_credit_overall_response,c(-Inf,quantile(app_model_amt_credit_overall_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
temp_cut <- quantile(app_data$app_model_amt_credit_overall_response,probs=seq(.1,1,.1), na.rm=TRUE)
app_data$app_model_cut <- findInterval(app_data$app_model_amt_credit_overall_response, temp_cut)
app_data[is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),by=app_model_cut][order(app_model_cut)]


# see if this format is identical to what you need to submit
app_model_amt_credit_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(app_model_amt_credit_xgb_model_submission) <- c("sk_id_curr", "target")

app_model_amt_credit_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
app_model_amt_credit_xgb_model_submission$target <- app_data[is.na(target)]$app_model_amt_credit_overall_response

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(app_model_amt_credit_xgb_model_submission, file="app_model_amt_credit_xgb_model_submission_20180719.csv")






#### XGBoosting ####
amt_annuity_model_data <- app_data_amt_annuity_sampled[,!(colnames(app_data_amt_annuity_sampled) %in% c("sk_id_curr", "test_group_number")), with=FALSE]
amt_annuity_model_data <- amt_annuity_model_data[!is.na(target)]
amt_annuity_model_target <- amt_annuity_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
amt_annuity_model_matrix <- model.matrix(~.+0,data = amt_annuity_model_data[,-c("target"),with=F])
amt_annuity_model_matrix <- xgb.DMatrix(data = amt_annuity_model_matrix,label = amt_annuity_model_target)

ptm <- proc.time()
set.seed(101022)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.003, gamma=10.75, max_depth=0, max_leaves=720, grow_policy="lossguide", min_child_weight=43, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
app_model_amt_annuity_sampled_overall <- xgb.train(params = params, data = amt_annuity_model_matrix, nrounds = 5220, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(app_model_amt_annuity_sampled_overall, file="app_model_amt_annuity_xbg.Rdata")





### Refit on a subset of more-important columns ###
cols_to_cut <- c("bal_cc_credit_limit_max", "bal_cc_current_balance_sum", "br_xgb_model_response_max_180_days", "incc_xgb_target_pred_cv", "prev_app_tot_target_pred_max_180_days", "bal_cc_current_annuity_sum", "br_credit_type_mortgage_cnt", "elevators_avg", "br_credit_type_credit_card_cnt", "br_early_payoff_count", "br_xgb_model_response_min_90_days", "bal_total_acct_cnt", "br_xgb_model_response_avg_90_days", "br_xgb_model_response_max_90_days", "br_late_payoff_count", "prev_app_tot_target_pred_min_90_days", "br_count_days_credit_730_days", "prev_app_tot_target_pred_avg_90_days", "pa_est_int_rate_lt_50_ntile_cnt", "amt_income_total_mod_score", "br_xgb_model_excess_risk_sum_90_days", "prev_app_tot_target_pred_excess_risk_sum_90_days", "br_count_days_enddate_fact_gt_n30", "br_credit_type_consumer_cnt", "pa_xgb_model_lt_50_ntile_cnt", "pa_count_name_portf_cash", "br_max_overdue_gt_0_cnt_consumer", "amt_req_cred_bureau_qrt_cmltv", "cnt_fam_members")
cols_to_cut <- c(cols_to_cut, "icc_xgb_target_pred_min", "pa_count_client_type_refreshed", "appr_process_start_weekday", "br_xgb_model_response_min_30_days", "br_credit_type_microloan_cnt", "pa_count_730_days", "prev_app_tot_target_pred_max_90_days", "pa_count_name_portf_pos", "cnt_children", "icc_xgb_target_pred_max", "region_id_7", "br_max_overdue_gt_0_cnt_total", "pa_xgb_model_gt_95_ntile_cnt", "region_id_8", "flag_phone", "br_xgb_model_excess_risk_sum_30_days", "pa_count_name_portf_cards", "flag_own_realty_y", "pa_est_int_rate_lt_50_ntile_cnt_1_year", "pa_count_approved_credit_gt_250000", "document_good_count", "pa_count_client_type_new", "name_income_type_comm_assoc", "name_housing_type_house", "pa_approved_count_730_days", "reg_live_work_city_not_city_cnt", "pa_count_approved_down_pmt_gt_0", "flag_document_3", "icc_xgb_target_pred_avg", "name_family_status_civil", "name_type_suite_unaccompanied", "name_family_status_separated", "name_income_type_state_serv")
cols_to_cut <- c(cols_to_cut, "pa_count_purpose_not_xap_xna", "pa_count_name_portf_xna", "pa_count_active_acct", "pa_est_annual_int_rate_canceled_accts_weighted", "prev_app_tot_target_pred_max_30_days", "flag_document_8", "name_housing_type_office", "pa_sellerplace_area_lte_7_cnt", "br_xgb_model_response_avg_30_days", "pa_xgb_model_gt_90_ntile_cnt", "br_count_days_credit_365_days", "pa_count_365_days", "pa_sellerplace_area_gte_18_cnt", "br_credit_status_sold_count", "pa_count_180_days", "reg_city_not_work_city", "flag_email", "br_credit_type_car_loan_cnt", "pa_est_int_rate_lt_10_ntile_cnt", "name_type_suite_spouse", "region_id_5", "pa_est_annual_interest_rate_canceled_max", "region_id_6", "name_type_suite_family", "occupation_type_driver")
cols_to_cut <- c(cols_to_cut, "pa_refused_count_365_days", "name_family_status_widow", "pa_refused_count_730_days", "occupation_type_blank", "region_id_1", "name_education_type_lower_sec", "occupation_type_manager", "prev_app_tot_target_pred_min_30_days", "pa_est_int_rate_gt_95_ntile_cnt", "prev_app_tot_target_pred_excess_risk_sum_30_days", "amt_req_cred_bureau_week_over_mon", "name_type_suite_other_b", "pa_xgb_model_lt_10_ntile_cnt", "name_education_type_incomplete_higher", "region_id_9", "prev_app_tot_target_pred_avg_30_days", "occupation_type_core", "occupation_type_accountant", "name_housing_type_parents", "organization_type_govt", "pa_canceled_count", "pa_unused_offer_count", "pa_refused_count_180_days", "flag_own_car_y", "pa_est_int_rate_lt_10_ntile_cnt_1_year", "name_housing_type_municipal", "br_max_overdue_gt_0_cnt_credit_card", "pa_est_annual_interest_rate_canceled_min", "pa_est_int_rate_lt_05_ntile_cnt", "occupation_type_security", "organization_type_const")
cols_to_cut <- c(cols_to_cut, "pa_est_int_rate_gt_90_ntile_cnt", "amt_req_cred_bureau_mon_cmltv", "pa_est_int_rate_gt_99_ntile_cnt", "br_xgb_model_response_max_30_days", "pa_xgb_model_gt_90_ntile_cnt_1_year", "pa_canceled_count_90_days", "organization_type_kindg", "organization_type_school", "pa_est_int_rate_lt_50_ntile_cnt_90_days", "occupation_type_high_skill", "region_id_2", "pa_anty_x_cnt_pmt_to_amt_canceled_min", "pa_est_int_rate_lt_05_ntile_cnt_1_year", "name_housing_type_rented", "pa_canceled_count_180_days", "pa_anty_x_cnt_pmt_to_amt_canceled_max", "amt_req_cred_bureau_week_cmltv", "reg_region_not_live_region", "flag_document_6", "reg_region_not_work_region", "pa_approved_count_365_days", "pa_canceled_count_730_days", "flag_document_18", "def_social_circle_30_60_diff", "organization_type_bus_1", "name_type_suite_children", "pa_canceled_count_30_days")
cols_to_cut <- c(cols_to_cut, "region_id_12", "pa_xgb_model_lt_50_ntile_cnt_1_year", "pa_count_90_days", "region_id_3", "br_count_days_credit_180_days", "live_region_not_work_region", "pa_xgb_model_gt_99_ntile_cnt", "pa_approved_count_7_days", "occupation_type_low_skill", "pa_count_7_days", "region_id_4", "pa_count_30_days", "br_count_days_credit_60_days", "pa_approved_count_90_days", "name_type_suite_blank", "occupation_type_cooking", "pa_xgb_model_lt_05_ntile_cnt", "organization_type_trans_1", "pa_xgb_model_lt_01_ntile_cnt", "pa_est_int_rate_gt_90_ntile_cnt_1_year", "br_count_days_credit_90_days", "pa_approved_count_180_days", "organization_type_other", "pa_refused_count_90_days", "organization_type_bus_2", "pa_sellerplace_area_gte_25_cnt", "pa_est_int_rate_lt_01_ntile_cnt", "organization_type_med", "pa_xgb_model_gt_95_ntile_cnt_1_year", "occupation_type_medicine")
cols_to_cut <- c(cols_to_cut, "flag_document_5", "name_contract_type_cash_loans", "occupation_type_cleaning", "pa_xgb_model_gt_95_ntile_cnt_90_days", "pa_xgb_model_gt_99_ntile_cnt_1_year", "amt_req_cred_bureau_day_cmltv", "flag_document_11", "br_max_overdue_gt_0_cnt_car_loan", "region_id_10", "pa_sellerplace_area_gte_18_cnt_1_year", "pa_est_int_rate_gt_999_ntile_cnt", "pa_est_int_rate_gt_90_ntile_cnt_90_days", "pa_est_int_rate_gt_95_ntile_cnt_1_year", "occupation_type_waiter", "flag_document_16", "organization_type_trade_7", "name_income_type_pensioner", "pa_sellerplace_area_gte_25_cnt_1_year", "ext_source_1_3_cnt", "pa_xgb_model_lt_10_ntile_cnt_1_year", "pa_refused_count_30_days", "pa_xgb_model_lt_01_ntile_cnt_1_year", "pa_est_int_rate_lt_10_ntile_cnt_90_days", "br_xgb_model_response_cv", "br_xgb_model_response_max_365_days", "br_pct_of_prin_paid_vs_pct_loan_term_avg")
cols_to_cut <- c(cols_to_cut, "pa_days_decision_min_approved", "br_days_credit_avg", "pa_anty_x_cnt_pmt_to_amt_refused_max", "pa_days_decision_min_refused", "hour_appr_process_start_adj", "bal_cc_current_balance_max", "ccb_xgb_target_pred_avg", "pa_days_decision_max_canceled", "prev_app_tot_target_pred_max_365_days", "years_beginexpluatation_mode", "amt_income_total_mod_10000", "pa_est_annual_interest_rate_refused_max", "name_education_type_sec", "pa_est_annual_interest_rate_refused_min", "br_xgb_model_response_min_180_days", "ccb_xgb_target_pred_min", "br_xgb_model_excess_risk_sum_180_days", "br_xgb_model_response_avg_180_days", "bal_cc_credit_limit_sum", "flag_work_phone", "icc_xgb_target_pred_excess_risk_sum", "prev_app_tot_target_pred_avg_180_days")
cols_to_cut <- c(cols_to_cut, "prev_app_tot_target_pred_min_180_days", "reg_city_not_live_city", "obs_60_cnt_social_circle", "prev_app_tot_target_pred_excess_risk_sum_180_days", "pa_sellerplace_area_risk_sd_1_year", "def_60_cnt_social_circle", "obs_30_cnt_social_circle", "br_count_days_enddate_lt_0", "pa_amt_credit_approved_sum_90_days", "br_credit_status_closed_count", "amt_req_cred_bureau_mon_over_qrt", "floorsmax_avg", "amt_req_cred_bureau_mon_over_year", "pa_count_approved_credit_lt_25000", "name_income_type_working", "br_count_total", "pa_apprv_pos_rate_down_payment_min", "pa_sellerplace_area_risk_min_1_year", "pa_count_name_pmt_type_xna")
cols_to_cut <- c(cols_to_cut, "pa_sellerplace_area_lte_10_cnt", "pa_count_consumer", "pa_count_cash", "pa_count_client_type_repeater", "pa_count", "pa_sellerplace_area_risk_max_1_year", "pa_refused_count", "name_family_status_single", "organization_type_self_emp", "pa_approved_count", "occupation_type_laborer", "live_city_not_work_city", "organization_type_bus_3", "occupation_type_sales", "pa_canceled_count_365_days", "all_acct_days_in_past_gt_n90_cnt", "all_acct_days_in_past_gt_n60_cnt", "all_acct_days_in_past_gt_n30_cnt")

#### XGBoosting ####
app_model_data <- app_data[,!(colnames(app_data) %in% c(cols_to_cut, "sk_id_curr", "test_group_number")), with=FALSE]
app_model_data <- app_model_data[!is.na(target)]
app_model_target <- app_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
app_model_matrix <- model.matrix(~.+0,data = app_model_data[,-c("target"),with=F])
app_model_matrix <- xgb.DMatrix(data = app_model_matrix,label = app_model_target)


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=5, max_depth=0, max_leaves=1023, grow_policy="lossguide", min_child_weight=75, subsample=0.8, colsample_bytree=0.8, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 1000, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.801464+0.001309	test-auc:0.769110+0.000871 
    # [251]	train-auc:0.840750+0.001299	test-auc:0.785622+0.001015 
    # [501]	train-auc:0.887677+0.001278	test-auc:0.791902+0.001464 
    # [641]	train-auc:0.907123+0.001298	test-auc:0.792397+0.001474  peak and decline


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=4, max_depth=0, max_leaves=513, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.832814+0.001468	test-auc:0.773076+0.000123 
    # [251]	train-auc:0.885320+0.001179	test-auc:0.788281+0.000200 
    # [501]	train-auc:0.946683+0.000956	test-auc:0.793172+0.000415 
    # [521]	train-auc:0.950133+0.000906	test-auc:0.793207+0.000463


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=4, max_depth=0, max_leaves=255, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [251]	train-auc:0.885475+0.001385	test-auc:0.788143+0.000037   if train and test both lag, a no-go


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=4, max_depth=0, max_leaves=350, grow_policy="lossguide", min_child_weight=60, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.825514+0.001471	test-auc:0.772343+0.000063 
    # [251]	train-auc:0.873362+0.001251	test-auc:0.787679+0.000124 
    # [501]	train-auc:0.931733+0.000997	test-auc:0.793095+0.000176
    # [541]	train-auc:0.938454+0.000910	test-auc:0.793226+0.000226   best so far


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6, max_depth=0, max_leaves=400, grow_policy="lossguide", min_child_weight=62.5, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.812357+0.001469	test-auc:0.770742+0.000018 
    # [251]	train-auc:0.862087+0.001308	test-auc:0.787481+0.000011 
    # [501]	train-auc:0.920078+0.001100	test-auc:0.793393+0.000242 
    # [601]	train-auc:0.935823+0.001208	test-auc:0.793600+0.000173   peak, drops.


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.5, max_depth=0, max_leaves=450, grow_policy="lossguide", min_child_weight=65, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.808955+0.001156	test-auc:0.770270+0.000004 
    # [251]	train-auc:0.857991+0.001204	test-auc:0.787309+0.000333 
    # [501]	train-auc:0.914415+0.001180	test-auc:0.793590+0.000446 
    # [551]	train-auc:0.922614+0.001054	test-auc:0.793851+0.000488 


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.25, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.5, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.810907+0.001144	test-auc:0.770544+0.000034 
    # [251]	train-auc:0.861148+0.001205	test-auc:0.787516+0.000281 
    # [501]	train-auc:0.918595+0.001213	test-auc:0.793687+0.000518 
    # [651]	train-auc:0.941044+0.000986	test-auc:0.793924+0.000690 


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.125, max_depth=0, max_leaves=475, grow_policy="lossguide", min_child_weight=61.25, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.812268+0.001249	test-auc:0.770782+0.000022 
    # [251]	train-auc:0.863025+0.001146	test-auc:0.787540+0.000151 
    # [501]	train-auc:0.921107+0.001163	test-auc:0.793322+0.000200 
    # [581]	train-auc:0.933940+0.001114	test-auc:0.793468+0.000193 
    # [661]	train-auc:0.944662+0.001092	test-auc:0.793481+0.000208    peak at 581, drop, and then a little higher



ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.375, max_depth=0, max_leaves=467, grow_policy="lossguide", min_child_weight=63.75, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.809996+0.001294	test-auc:0.770563+0.000060 
    # [251]	train-auc:0.859489+0.001200	test-auc:0.787482+0.000206 
    # [501]	train-auc:0.916762+0.001178	test-auc:0.793516+0.000182 
    # [611]	train-auc:0.933682+0.001006	test-auc:0.793810+0.000215



ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.3, max_depth=0, max_leaves=455, grow_policy="lossguide", min_child_weight=63.5, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.810534+0.001378	test-auc:0.770536+0.000097 
    # [251]	train-auc:0.860158+0.001202	test-auc:0.787461+0.000168 
    # [501]	train-auc:0.917457+0.001178	test-auc:0.793502+0.000405 
    # [651]	train-auc:0.939506+0.000892	test-auc:0.793805+0.000417


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.25, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.5, subsample=0.95, colsample_bytree=0.95, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.810023+0.000914	test-auc:0.771638+0.000240
    # [251]	train-auc:0.858075+0.001020	test-auc:0.788293+0.000188 
    # [501]	train-auc:0.913969+0.001021	test-auc:0.794560+0.000546 
    # [611]	train-auc:0.930877+0.000973	test-auc:0.794901+0.000802     this one is a revelation


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.25, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.5, subsample=0.875, colsample_bytree=0.95, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.807481+0.000969	test-auc:0.771637+0.000218 
    # [251]	train-auc:0.853413+0.001178	test-auc:0.788073+0.000397 
    # [501]	train-auc:0.907308+0.001308	test-auc:0.794381+0.000982 
    # [671]	train-auc:0.931974+0.001223	test-auc:0.794768+0.000917


    # these are the best params I'm finding. Run them with greatly reduced eta and many more rounds
ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.25, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.5, subsample=0.95, colsample_bytree=0.95, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = app_model_matrix, nrounds = 8000, nfold = 2, showsd = T, stratified = T, print_every_n = 25, maximize = F)
print(proc.time() - ptm)
    # [6251]	train-auc:0.933895+0.001124	test-auc:0.795875+0.000803 


ptm <- proc.time()
set.seed(080685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.245, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.25, subsample=0.9485, colsample_bytree=0.9485, scale_pos_weight = 1, tree_method="hist")
overall_smallvars_model_1 <- xgb.train(params = params, data = app_model_matrix, nrounds = 6250, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_smallvars_model_1, file="overall_smallvars_model_1_xbg.Rdata")


ptm <- proc.time()
set.seed(080417)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.248, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.2, subsample=0.9495, colsample_bytree=0.9485, scale_pos_weight = 1, tree_method="hist")
overall_smallvars_model_2 <- xgb.train(params = params, data = app_model_matrix, nrounds = 6250, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_smallvars_model_2, file="overall_smallvars_model_2_xbg.Rdata")


#### build prediction files on all 2 of these #####
# below is same code, for 1,2
#### XGBoosting ####
smallvars_pred_data <- app_data[,(colnames(app_data) %in% c(overall_smallvars_model_2$feature_names, "target")), with=FALSE]
smallvars_pred_data <- smallvars_pred_data[is.na(target)]
smallvars_pred_target <- smallvars_pred_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
smallvars_pred_matrix <- model.matrix(~.+0,data = smallvars_pred_data[,-c("target"),with=F])
smallvars_pred_matrix <- xgb.DMatrix(data = smallvars_pred_matrix,label = smallvars_pred_target)

smallvars_2_pred_scores <- predict(overall_smallvars_model_2, smallvars_pred_matrix, type="response")


smallvars_2_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(smallvars_2_xgb_model_submission) <- c("sk_id_curr", "target")

smallvars_2_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
smallvars_2_xgb_model_submission$target <- smallvars_2_pred_scores

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(smallvars_2_xgb_model_submission, file="smallvars_2_xgb_model_submission_20180721.csv")









##### tiny vars is just top 100 vars. does this continue to drive improvemnts to model performance vs. more vars? #####
    # this really doesn't perform close to the deep cut. try shallow cut next.
tiny_vars <- c("prev_app_xgb_x_ext_source_max","ext_source_min_plus_max","ext_source_min","estimated_annual_interest_rate","amt_credit_over_price","bal_cc_utilization_pct","incc_xgb_target_pred_avg","cnt_payment","incc_xgb_target_pred_excess_risk_sum","br_xgb_model_response_avg_3_years","days_employed_over_birth_ratio","ext_source_2_3_avg","br_xgb_model_excess_risk_sum","organization_type_risk_rating","incc_xgb_target_pred_min","ext_source_3","incc_xgb_target_pred_max","prev_app_xgb_x_bureau_xgb","pa_sellerplace_area_risk_min","days_birth","ext_source_1_2_3_avg","prev_app_xgb_x_norm_annuity","ext_source_2","prev_app_tot_target_pred_min_880_days","ext_source_1","days_id_publish","ext_source_max_x_norm_annuity","ext_source_min_over_max_ratio","pa_active_acct_amt_annuity_to_credit_ratio","prev_app_tot_target_pred_excess_risk_sum_880_days","pos_xgb_target_pred_excess_risk_sum")
tiny_vars <- c(tiny_vars,"code_gender_f","prev_app_xgb_x_norm_age","own_car_age","prev_app_tot_target_pred_excess_risk_sum","info_over_days_birth_ratio_2","br_xgb_model_response_avg","days_last_phone_change","pa_days_decision_max_approved","pos_xgb_target_pred_avg","norm_days_birth_x_norm_annuity","pos_xgb_target_pred_max","occupation_type_risk_rating","br_xgb_model_excess_risk_sum_3_years","all_acct_days_in_past_cv","days_registration","br_xgb_model_response_max","ccb_xgb_target_pred_excess_risk_sum","pa_sellerplace_area_risk_avg","bureau_xgb_x_norm_annuity","amt_credit","region_risk_rating","prev_app_tot_target_pred_avg_880_days","pa_amt_credit_approved_sum","bureau_xgb_x_norm_age","ext_source_1_2_avg","info_over_days_birth_ratio_1","pa_anty_x_cnt_pmt_to_amt_approved_avg","days_employed","pa_amt_annuity_active_acct_sum","pa_anty_x_cnt_pmt_to_amt_approved_stddev")
tiny_vars <- c(tiny_vars,"income_adj_for_age_fam_pmt","ext_source_max_x_norm_age","all_acct_days_in_past_max","br_xgb_model_response_max_3_years","amt_income_over_annuity","br_amt_credit_cv","bal_tot_annty_after_new_app_over_income","br_xgb_model_response_avg_365_days","incc_xgb_target_pred_stddev","pa_anty_x_cnt_pmt_to_amt_approved_min","pa_anty_x_cnt_pmt_to_amt_approved_max","amt_annuity","all_acct_days_in_past_sd","pa_est_annual_interest_rate_approved_stddev","pa_est_annual_interest_rate_approved_min","br_xgb_model_response_min_3_years","bureau_xgb_x_ext_source_max","br_amt_credit_min","pa_days_decision_avg","amt_income_over_credit","all_acct_days_in_past_avg")
tiny_vars <- c(tiny_vars,"ext_source_max","pa_amt_credit_approved_sum_365_days","prev_app_tot_target_pred_min","br_xgb_model_response_sd","pa_est_annual_interest_rate_approved_max","bal_total_annuity_after_new_app","pa_days_decision_cv","bal_total_balance_and_credit_over_income","br_amt_credit_avg","pa_sellerplace_area_risk_sd","br_pct_of_prin_paid_vs_pct_loan_term_min","pa_est_annual_int_rate_approved_accts_weighted","br_days_credit_cv","br_amt_credit_stddev","br_xgb_model_response_min_365_days","pa_days_decision_sd","name_education_type_higher","bal_non_utilized_over_amt_credit")

#### XGBoosting ####
tiny_model_data <- app_data[,(colnames(app_data) %in% c(tiny_vars, "target")), with=FALSE]
tiny_model_data <- tiny_model_data[!is.na(target)]
tiny_model_target <- tiny_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
tiny_model_matrix <- model.matrix(~.+0,data = tiny_model_data[,-c("target"),with=F])
tiny_model_matrix <- xgb.DMatrix(data = tiny_model_matrix,label = tiny_model_target)


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=0, max_depth=0, max_leaves=590, grow_policy="lossguide", min_child_weight=1, subsample=0.5, colsample_bytree=0.5, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = tiny_model_matrix, nrounds = 500, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)








##### tiny vars is just top 100 vars. does this continue to drive improvemnts to model performance vs. more vars? #####
# this really doesn't perform close to the deep cut. try shallow cut next.
shallow_cut <- c("bal_cc_credit_limit_max", "bal_cc_current_balance_sum", "br_xgb_model_response_max_180_days", "incc_xgb_target_pred_cv", "prev_app_tot_target_pred_max_180_days", "bal_cc_current_annuity_sum", "br_credit_type_mortgage_cnt", "elevators_avg", "br_credit_type_credit_card_cnt", "br_early_payoff_count", "br_xgb_model_response_min_90_days", "bal_total_acct_cnt", "br_xgb_model_response_avg_90_days", "br_xgb_model_response_max_90_days", "br_late_payoff_count", "prev_app_tot_target_pred_min_90_days", "br_count_days_credit_730_days", "prev_app_tot_target_pred_avg_90_days", "pa_est_int_rate_lt_50_ntile_cnt", "amt_income_total_mod_score", "br_xgb_model_excess_risk_sum_90_days", "prev_app_tot_target_pred_excess_risk_sum_90_days", "br_count_days_enddate_fact_gt_n30", "br_credit_type_consumer_cnt", "pa_xgb_model_lt_50_ntile_cnt", "pa_count_name_portf_cash", "br_max_overdue_gt_0_cnt_consumer", "amt_req_cred_bureau_qrt_cmltv", "cnt_fam_members")
shallow_cut <- c(shallow_cut, "icc_xgb_target_pred_min", "pa_count_client_type_refreshed", "appr_process_start_weekday", "br_xgb_model_response_min_30_days", "br_credit_type_microloan_cnt", "pa_count_730_days", "prev_app_tot_target_pred_max_90_days", "pa_count_name_portf_pos", "cnt_children", "icc_xgb_target_pred_max", "region_id_7", "br_max_overdue_gt_0_cnt_total", "pa_xgb_model_gt_95_ntile_cnt", "region_id_8", "flag_phone", "br_xgb_model_excess_risk_sum_30_days", "pa_count_name_portf_cards", "flag_own_realty_y", "pa_est_int_rate_lt_50_ntile_cnt_1_year", "pa_count_approved_credit_gt_250000", "document_good_count", "pa_count_client_type_new", "name_income_type_comm_assoc", "name_housing_type_house", "pa_approved_count_730_days", "reg_live_work_city_not_city_cnt", "pa_count_approved_down_pmt_gt_0", "flag_document_3", "icc_xgb_target_pred_avg", "name_family_status_civil", "name_type_suite_unaccompanied", "name_family_status_separated", "name_income_type_state_serv")
shallow_cut <- c(shallow_cut, "pa_count_purpose_not_xap_xna", "pa_count_name_portf_xna", "pa_count_active_acct", "pa_est_annual_int_rate_canceled_accts_weighted", "prev_app_tot_target_pred_max_30_days", "flag_document_8", "name_housing_type_office", "pa_sellerplace_area_lte_7_cnt", "br_xgb_model_response_avg_30_days", "pa_xgb_model_gt_90_ntile_cnt", "br_count_days_credit_365_days", "pa_count_365_days", "pa_sellerplace_area_gte_18_cnt", "br_credit_status_sold_count", "pa_count_180_days", "reg_city_not_work_city", "flag_email", "br_credit_type_car_loan_cnt", "pa_est_int_rate_lt_10_ntile_cnt", "name_type_suite_spouse", "region_id_5", "pa_est_annual_interest_rate_canceled_max", "region_id_6", "name_type_suite_family", "occupation_type_driver")
shallow_cut <- c(shallow_cut, "pa_refused_count_365_days", "name_family_status_widow", "pa_refused_count_730_days", "occupation_type_blank", "region_id_1", "name_education_type_lower_sec", "occupation_type_manager", "prev_app_tot_target_pred_min_30_days", "pa_est_int_rate_gt_95_ntile_cnt", "prev_app_tot_target_pred_excess_risk_sum_30_days", "amt_req_cred_bureau_week_over_mon", "name_type_suite_other_b", "pa_xgb_model_lt_10_ntile_cnt", "name_education_type_incomplete_higher", "region_id_9", "prev_app_tot_target_pred_avg_30_days", "occupation_type_core", "occupation_type_accountant", "name_housing_type_parents", "organization_type_govt", "pa_canceled_count", "pa_unused_offer_count", "pa_refused_count_180_days", "flag_own_car_y", "pa_est_int_rate_lt_10_ntile_cnt_1_year", "name_housing_type_municipal", "br_max_overdue_gt_0_cnt_credit_card", "pa_est_annual_interest_rate_canceled_min", "pa_est_int_rate_lt_05_ntile_cnt", "occupation_type_security", "organization_type_const")
shallow_cut <- c(shallow_cut, "pa_est_int_rate_gt_90_ntile_cnt", "amt_req_cred_bureau_mon_cmltv", "pa_est_int_rate_gt_99_ntile_cnt", "br_xgb_model_response_max_30_days", "pa_xgb_model_gt_90_ntile_cnt_1_year", "pa_canceled_count_90_days", "organization_type_kindg", "organization_type_school", "pa_est_int_rate_lt_50_ntile_cnt_90_days", "occupation_type_high_skill", "region_id_2", "pa_anty_x_cnt_pmt_to_amt_canceled_min", "pa_est_int_rate_lt_05_ntile_cnt_1_year", "name_housing_type_rented", "pa_canceled_count_180_days", "pa_anty_x_cnt_pmt_to_amt_canceled_max", "amt_req_cred_bureau_week_cmltv", "reg_region_not_live_region", "flag_document_6", "reg_region_not_work_region", "pa_approved_count_365_days", "pa_canceled_count_730_days", "flag_document_18", "def_social_circle_30_60_diff", "organization_type_bus_1", "name_type_suite_children", "pa_canceled_count_30_days")
shallow_cut <- c(shallow_cut, "region_id_12", "pa_xgb_model_lt_50_ntile_cnt_1_year", "pa_count_90_days", "region_id_3", "br_count_days_credit_180_days", "live_region_not_work_region", "pa_xgb_model_gt_99_ntile_cnt", "pa_approved_count_7_days", "occupation_type_low_skill", "pa_count_7_days", "region_id_4", "pa_count_30_days", "br_count_days_credit_60_days", "pa_approved_count_90_days", "name_type_suite_blank", "occupation_type_cooking", "pa_xgb_model_lt_05_ntile_cnt", "organization_type_trans_1", "pa_xgb_model_lt_01_ntile_cnt", "pa_est_int_rate_gt_90_ntile_cnt_1_year", "br_count_days_credit_90_days", "pa_approved_count_180_days", "organization_type_other", "pa_refused_count_90_days", "organization_type_bus_2", "pa_sellerplace_area_gte_25_cnt", "pa_est_int_rate_lt_01_ntile_cnt", "organization_type_med", "pa_xgb_model_gt_95_ntile_cnt_1_year", "occupation_type_medicine")
shallow_cut <- c(shallow_cut, "flag_document_5", "name_contract_type_cash_loans", "occupation_type_cleaning", "pa_xgb_model_gt_95_ntile_cnt_90_days", "pa_xgb_model_gt_99_ntile_cnt_1_year", "amt_req_cred_bureau_day_cmltv", "flag_document_11", "br_max_overdue_gt_0_cnt_car_loan", "region_id_10", "pa_sellerplace_area_gte_18_cnt_1_year", "pa_est_int_rate_gt_999_ntile_cnt", "pa_est_int_rate_gt_90_ntile_cnt_90_days", "pa_est_int_rate_gt_95_ntile_cnt_1_year", "occupation_type_waiter", "flag_document_16", "organization_type_trade_7", "name_income_type_pensioner", "pa_sellerplace_area_gte_25_cnt_1_year", "ext_source_1_3_cnt", "pa_xgb_model_lt_10_ntile_cnt_1_year", "pa_refused_count_30_days", "pa_xgb_model_lt_01_ntile_cnt_1_year", "pa_est_int_rate_lt_10_ntile_cnt_90_days")


#### XGBoosting ####
shallow_cut_model_data <- app_data[,!(colnames(app_data) %in% c(shallow_cut, "sk_id_curr", "test_group_number")), with=FALSE]
shallow_cut_model_data <- shallow_cut_model_data[!is.na(target)]
shallow_cut_target <- shallow_cut_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
shallow_cut_model_matrix <- model.matrix(~.+0,data = shallow_cut_model_data[,-c("target"),with=F])
shallow_cut_model_matrix <- xgb.DMatrix(data = shallow_cut_model_matrix,label = shallow_cut_target)


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.25, max_depth=0, max_leaves=460, grow_policy="lossguide", min_child_weight=62.5, subsample=0.95, colsample_bytree=0.95, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = shallow_cut_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.810372+0.000752	test-auc:0.771436+0.000411 
    # [251]	train-auc:0.859287+0.001033	test-auc:0.788282+0.000447 
    # [501]	train-auc:0.916284+0.001349	test-auc:0.794893+0.000820
    # [641]	train-auc:0.937277+0.001083	test-auc:0.795262+0.000924


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=6.75, max_depth=0, max_leaves=440, grow_policy="lossguide", min_child_weight=67.5, subsample=0.925, colsample_bytree=0.925, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = shallow_cut_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [101]	train-auc:0.804801+0.000998	test-auc:0.770296+0.000583 
    # [251]	train-auc:0.851533+0.001115	test-auc:0.788030+0.000321     
    # [501]	train-auc:0.905146+0.001321	test-auc:0.794925+0.000597
    # [641]	train-auc:0.925540+0.001104	test-auc:0.795474+0.000896


ptm <- proc.time()
set.seed(8685)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.02, gamma=7.25, max_depth=0, max_leaves=420, grow_policy="lossguide", min_child_weight=72.5, subsample=0.90, colsample_bytree=0.90, scale_pos_weight = 1, tree_method="hist", eval_metric="auc")
xgb1 <- xgb.cv(params = params, data = shallow_cut_model_matrix, nrounds = 800, nfold = 2, showsd = T, stratified = T, print_every_n = 10, maximize = F)
print(proc.time() - ptm)
    # [701]	train-auc:0.920496+0.000945	test-auc:0.795318+0.000746 





ptm <- proc.time()
set.seed(39344324)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.85, max_depth=0, max_leaves=436, grow_policy="lossguide", min_child_weight=68.5, subsample=0.92, colsample_bytree=0.92, scale_pos_weight = 1, tree_method="hist")
overall_shallow_cut_model_1 <- xgb.train(params = params, data = shallow_cut_model_matrix, nrounds = 6600, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_shallow_cut_model_1, file="overall_shallow_cut_model_1_xbg.Rdata")


ptm <- proc.time()
set.seed(390203)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.82, max_depth=0, max_leaves=438, grow_policy="lossguide", min_child_weight=68.2, subsample=0.923, colsample_bytree=0.923, scale_pos_weight = 1, tree_method="hist")
overall_shallow_cut_model_2 <- xgb.train(params = params, data = shallow_cut_model_matrix, nrounds = 6575, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_shallow_cut_model_2, file="overall_shallow_cut_model_2_xbg.Rdata")


ptm <- proc.time()
set.seed(0489243)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.88, max_depth=0, max_leaves=435, grow_policy="lossguide", min_child_weight=68.8, subsample=0.917, colsample_bytree=0.917, scale_pos_weight = 1, tree_method="hist")
overall_shallow_cut_model_3 <- xgb.train(params = params, data = shallow_cut_model_matrix, nrounds = 6625, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_shallow_cut_model_3, file="overall_shallow_cut_model_3_xgb.Rdata")


ptm <- proc.time()
set.seed(0489243)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=6.9, max_depth=0, max_leaves=433, grow_policy="lossguide", min_child_weight=69.0, subsample=0.915, colsample_bytree=0.915, scale_pos_weight = 1, tree_method="hist")
overall_shallow_cut_model_4 <- xgb.train(params = params, data = shallow_cut_model_matrix, nrounds = 6800, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_shallow_cut_model_4, file="overall_shallow_cut_model_4_xgb.Rdata")


ptm <- proc.time()
set.seed(39344324)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.001, gamma=6.85, max_depth=0, max_leaves=436, grow_policy="lossguide", min_child_weight=68.5, subsample=0.92, colsample_bytree=0.92, scale_pos_weight = 1, tree_method="hist")
overall_shallow_cut_model_5 <- xgb.train(params = params, data = shallow_cut_model_matrix, nrounds = 12500, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application refit")
save(overall_shallow_cut_model_5, file="overall_shallow_cut_model_5_xbg.Rdata")






#### build prediction files on all 5 of these #####
    # below is same code, for 1,2,3...
#### XGBoosting ####
shallow_cut_pred_data <- app_data[,(colnames(app_data) %in% c(overall_shallow_cut_model_2$feature_names, "target")), with=FALSE]
shallow_cut_pred_data <- shallow_cut_pred_data[is.na(target)]
shallow_cut_pred_target <- shallow_cut_pred_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
shallow_cut_pred_matrix <- model.matrix(~.+0,data = shallow_cut_pred_data[,-c("target"),with=F])
shallow_cut_pred_matrix <- xgb.DMatrix(data = shallow_cut_pred_matrix,label = shallow_cut_pred_target)

shallow_cut_2_pred_scores <- predict(overall_shallow_cut_model_2, shallow_cut_pred_matrix, type="response")


shallow_cut_2_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(shallow_cut_2_xgb_model_submission) <- c("sk_id_curr", "target")

shallow_cut_2_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
shallow_cut_2_xgb_model_submission$target <- shallow_cut_2_pred_scores

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(shallow_cut_2_xgb_model_submission, file="shallow_cut_2_xgb_model_submission_20180722.csv")




shallow_cut_pred_data <- app_data[,(colnames(app_data) %in% c(overall_shallow_cut_model_3$feature_names, "target")), with=FALSE]
shallow_cut_pred_data <- shallow_cut_pred_data[is.na(target)]
shallow_cut_pred_target <- shallow_cut_pred_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
shallow_cut_pred_matrix <- model.matrix(~.+0,data = shallow_cut_pred_data[,-c("target"),with=F])
shallow_cut_pred_matrix <- xgb.DMatrix(data = shallow_cut_pred_matrix,label = shallow_cut_pred_target)

shallow_cut_3_pred_scores <- predict(overall_shallow_cut_model_3, shallow_cut_pred_matrix, type="response")


shallow_cut_3_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(shallow_cut_3_xgb_model_submission) <- c("sk_id_curr", "target")

shallow_cut_3_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
shallow_cut_3_xgb_model_submission$target <- shallow_cut_3_pred_scores

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(shallow_cut_3_xgb_model_submission, file="shallow_cut_3_xgb_model_submission_20180722.csv")



shallow_cut_pred_data <- app_data[,(colnames(app_data) %in% c(overall_shallow_cut_model_4$feature_names, "target")), with=FALSE]
shallow_cut_pred_data <- shallow_cut_pred_data[is.na(target)]
shallow_cut_pred_target <- shallow_cut_pred_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
shallow_cut_pred_matrix <- model.matrix(~.+0,data = shallow_cut_pred_data[,-c("target"),with=F])
shallow_cut_pred_matrix <- xgb.DMatrix(data = shallow_cut_pred_matrix,label = shallow_cut_pred_target)

shallow_cut_4_pred_scores <- predict(overall_shallow_cut_model_4, shallow_cut_pred_matrix, type="response")


shallow_cut_4_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(shallow_cut_4_xgb_model_submission) <- c("sk_id_curr", "target")

shallow_cut_4_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
shallow_cut_4_xgb_model_submission$target <- shallow_cut_4_pred_scores

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(shallow_cut_4_xgb_model_submission, file="shallow_cut_4_xgb_model_submission_20180722.csv")





shallow_cut_pred_data <- app_data[,(colnames(app_data) %in% c(overall_shallow_cut_model_5$feature_names, "target")), with=FALSE]
shallow_cut_pred_data <- shallow_cut_pred_data[is.na(target)]
shallow_cut_pred_target <- shallow_cut_pred_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
shallow_cut_pred_matrix <- model.matrix(~.+0,data = shallow_cut_pred_data[,-c("target"),with=F])
shallow_cut_pred_matrix <- xgb.DMatrix(data = shallow_cut_pred_matrix,label = shallow_cut_pred_target)

shallow_cut_5_pred_scores <- predict(overall_shallow_cut_model_5, shallow_cut_pred_matrix, type="response")


shallow_cut_5_xgb_model_submission <- as.data.frame(matrix(0, ncol=2, nrow=48744))
colnames(shallow_cut_5_xgb_model_submission) <- c("sk_id_curr", "target")

shallow_cut_5_xgb_model_submission$sk_id_curr <- app_data[is.na(target)]$sk_id_curr
shallow_cut_5_xgb_model_submission$target <- shallow_cut_5_pred_scores

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submissions")
write.csv(shallow_cut_5_xgb_model_submission, file="shallow_cut_5_xgb_model_submission_20180722.csv")





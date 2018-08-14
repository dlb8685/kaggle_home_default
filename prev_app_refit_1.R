library(pROC)
library(caret)
library(xgboost)
library(data.table)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")

# had to save 8 separate csv's due to size limitations and DataGrip crashing.
prev_app_1 <- fread("prev_app_data_1_refit.csv")
prev_app_2 <- fread("prev_app_data_2_refit.csv")
prev_app_3 <- fread("prev_app_data_3_refit.csv")
prev_app_4 <- fread("prev_app_data_4_refit.csv")
prev_app_5 <- fread("prev_app_data_5_refit.csv")
prev_app_6 <- fread("prev_app_data_6_refit.csv")
prev_app_7 <- fread("prev_app_data_7_refit.csv")
prev_app_8 <- fread("prev_app_data_8_refit.csv")
prev_app_9 <- fread("prev_app_data_9_refit.csv")

prev_app <- rbind(prev_app_1, prev_app_2, prev_app_3, prev_app_4, prev_app_5, prev_app_6, prev_app_7, prev_app_8, prev_app_9)

rm(prev_app_1)
rm(prev_app_2)
rm(prev_app_3)
rm(prev_app_4)
rm(prev_app_5)
rm(prev_app_6)
rm(prev_app_7)
rm(prev_app_8)
rm(prev_app_9)

prev_app$estimated_annual_interest_rate[prev_app$estimated_annual_interest_rate == 0] <- NA


#### XGBoosting ####
prev_app_model_data <- prev_app[,!(colnames(prev_app) %in% c("sk_id_curr", "sk_id_prev")), with=FALSE]
prev_app_model_data <- prev_app_model_data[!is.na(target)]
prev_app_model_target <- prev_app_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
prev_app_model_matrix <- model.matrix(~.+0,data = prev_app_model_data[,-c("target"),with=F])
prev_app_model_matrix <- xgb.DMatrix(data = prev_app_model_matrix,label = prev_app_model_target)



ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=100, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=1000, subsample=0.4, colsample_bytree=0.4, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = prev_app_model_matrix, nrounds = 30, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [30]	train-auc:0.595966+0.001391	test-auc:0.595143+0.000450


ptm <- proc.time()
set.seed(104)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=100, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=1000, subsample=0.4, colsample_bytree=0.4, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = prev_app_model_matrix, nrounds = 150, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [100]	train-auc:0.604096+0.000433	test-auc:0.603007+0.000229
    # [150]	train-auc:0.604970+0.000260	test-auc:0.603770+0.000344


ptm <- proc.time()
set.seed(104)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=85, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=850, subsample=0.4, colsample_bytree=0.4, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = prev_app_model_matrix, nrounds = 150, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [100]	train-auc:0.606609+0.000395	test-auc:0.605128+0.000972
    # [150]	train-auc:0.607058+0.000055	test-auc:0.605517+0.001362


ptm <- proc.time()
set.seed(104)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.09, gamma=80, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=800, subsample=0.4, colsample_bytree=0.4, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = prev_app_model_matrix, nrounds = 160, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [100]	train-auc:0.607536+0.000444	test-auc:0.605997+0.000938
    # [160]	train-auc:0.607877+0.000146	test-auc:0.606224+0.001184   about as wide a gap as i can tolerate.


ptm <- proc.time()
set.seed(102478)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.09, gamma=80, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=800, subsample=0.4, colsample_bytree=0.4, scale_pos_weight = 1, tree_method="hist")
prev_app_xgb_model <- xgb.train(params = params, data = prev_app_model_matrix, nrounds = 160, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(prev_app_xgb_model, file="prev_app_refit_1_xbg1.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = prev_app_xgb_model)
head(importance, n=50)

prev_app_model_data$xgb_model_response <- predict(prev_app_xgb_model,prev_app_model_matrix, type="response")
prev_app_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(xgb_model_response,c(-Inf,quantile(xgb_model_response,probs=seq(.125,1,.125), na.rm=TRUE),+Inf))]
prev_app_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),by=floor(xgb_model_response* 100) / 100][order(floor)]




# RERUN it
prev_app_model_data <- prev_app[,!(colnames(prev_app) %in% c("sk_id_curr", "sk_id_prev")), with=FALSE]
prev_app_model_target <- prev_app_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
prev_app_model_matrix <- model.matrix(~.+0,data = prev_app_model_data[,-c("target"),with=F])
prev_app_model_matrix <- xgb.DMatrix(data = prev_app_model_matrix,label = prev_app_model_target)

prev_app_model_data$xgb_model_response <- predict(prev_app_xgb_model,prev_app_model_matrix, type="response")


prev_app_model_scores_refit <- as.data.frame(matrix(0, ncol=2, nrow=1670214))
colnames(prev_app_model_scores_refit) <- c("sk_id_prev", "xgb_model_response")

prev_app_model_scores_refit$sk_id_prev <- prev_app$sk_id_prev
prev_app_model_scores_refit$xgb_model_response <- prev_app_model_data$xgb_model_response


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(prev_app_model_scores_refit, "prev_app_scores_refit_1_xgb.csv")


# for ntile levels
quantile(prev_app_model_data$xgb_model_response, probs=c(.001, .01, .05, .1, .5, .9, .95, .99, .999))




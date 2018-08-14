# you're going to re-use this model twice, so the train-test separation has to be extremely tight.
# Even if it only means 2-3 rounds and a significant loss in auc, cannot have more than 0.002 or so.

library(pROC)
library(caret)
library(xgboost)
library(data.table)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
inst_data <- fread("installments_non_cc_w_kmeans_pca.csv")
# 791k records, .073 target mean
inst_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target))]

# drop identifier columns, etc. in model data. No kmeans and PCA here!
inst_model_data <- inst_data[,!(colnames(inst_data) %in% c("V1",  "sk_id_curr", "kmeans_cluster")) & !(substring(colnames(inst_data), 0, 2) == "PC"), with=FALSE]
inst_model_data <- inst_model_data[!is.na(inst_model_data$target)]


# XGBoost stuff
inst_model_data <- inst_model_data[,!c("sk_id_prev", "kmeans_cluster")]
inst_model_data <- inst_model_data[!is.na(target)]
inst_model_target <- inst_model_data$target  # target is a separate deal
# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
inst_model_matrix <- model.matrix(~.+0,data = inst_model_data[,-c("target"),with=F])
inst_model_matrix <- xgb.DMatrix(data = inst_model_matrix,label = inst_model_target)


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=20, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=5000, subsample=0.50, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 20, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [13]	train-auc:0.575979+0.000429	test-auc:0.573997+0.000110 
    # already a substantial improvement


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=20, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=2000, subsample=0.60, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 20, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [17]	train-auc:0.581948+0.001813	test-auc:0.579336+0.001049


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=15, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=1500, subsample=0.60, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 20, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [16]	train-auc:0.582540+0.002279	test-auc:0.580247+0.000593
    # not finding a real improvement on this with the 0.002 constaint


### final model ###
set.seed(102478)
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=15, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=1500, subsample=0.60, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
xgb_inst_non_cc_model <- xgb.train(params = params, data = inst_model_matrix, nrounds = 30, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


inst_model_data$xgb_model_response <- predict(xgb_inst_non_cc_model,inst_model_matrix, type="response")
inst_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(xgb_model_response,c(-Inf,quantile(xgb_model_response,probs=seq(.1,.9,.1), na.rm=TRUE),+Inf))] 



# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(xgb_inst_non_cc_model, file="inst_non_cc_balance_refit_1_xbg1.Rdata")


# score and save
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
inst_data <- fread("installments_non_cc_w_kmeans_pca.csv")

# drop identifier columns, etc. in model data. No kmeans and PCA here!
inst_model_data <- inst_data[,!(colnames(inst_data) %in% c("V1",  "sk_id_curr", "kmeans_cluster")) & !(substring(colnames(inst_data), 0, 2) == "PC"), with=FALSE]
# inst_model_data <- inst_model_data[!is.na(inst_model_data$target)]

# XGBoost stuff
inst_model_data <- inst_model_data[,!c("sk_id_prev", "kmeans_cluster")]
#inst_model_data <- inst_model_data[!is.na(target)]
inst_model_target <- inst_model_data$target  # target is a separate deal
# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
inst_model_matrix <- model.matrix(~.+0,data = inst_model_data[,-c("target"),with=F])
inst_model_matrix <- xgb.DMatrix(data = inst_model_matrix,label = inst_model_target)

inst_data$xgb_target_pred <- predict(xgb_inst_non_cc_model, inst_model_matrix, type="response")

inst_model_non_cc_data_scores_refit <- as.data.frame(matrix(0, ncol=2, nrow=925074))
colnames(inst_model_non_cc_data_scores_refit) <- c("sk_id_prev", "xgb_model_response")

inst_model_non_cc_data_scores_refit$sk_id_prev <- inst_data$sk_id_prev
inst_model_non_cc_data_scores_refit$xgb_model_response <- inst_data$xgb_target_pred


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(inst_model_non_cc_data_scores_refit, "inst_non_cc_scores_refit_1_xgb.csv")




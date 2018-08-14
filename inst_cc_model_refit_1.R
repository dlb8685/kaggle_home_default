library(pROC)
library(caret)
library(xgboost)
library(data.table)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
inst_data <- fread("installments_cc_w_kmeans_pca.csv")


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
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.5, gamma=44, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=400, subsample=1, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 10, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [1]	train-auc:0.604729+0.000065	test-auc:0.602860+0.001646
    # [2]	train-auc:0.609306+0.002129	test-auc:0.603560+0.002302


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.5, gamma=50, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=1000, subsample=0.75, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 5, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [1]	train-auc:0.583741+0.003173	test-auc:0.583771+0.001952
    # [3]	train-auc:0.605306+0.001967	test-auc:0.604244+0.002679


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.5, gamma=50, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=800, subsample=0.75, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 12, nfold = 5, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [4]	train-auc:0.620597+0.002970	test-auc:0.618142+0.010676  if you get a lucky split
    # [4]	train-auc:0.618828+0.005315	test-auc:0.613752+0.005858  more normally?



ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=12.5, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=50, subsample=0.6, colsample_bytree=0.5, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 25, nfold = 4, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [20]	train-auc:0.613753+0.002260	test-auc:0.611812+0.008598 



ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=12.5, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=50, subsample=0.55, colsample_bytree=0.45, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = inst_model_matrix, nrounds = 50, nfold = 4, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [30]	train-auc:0.613753+0.003920	test-auc:0.611847+0.001659



### final model ###
set.seed(102478)
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.002, gamma=12.5, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=50, subsample=0.55, colsample_bytree=0.45, scale_pos_weight = 1, tree_method="hist")
xgb_inst_cc_model <- xgb.train(params = params, data = inst_model_matrix, nrounds = 30, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


inst_model_data$xgb_model_response <- predict(xgb_inst_cc_model,inst_model_matrix, type="response")
inst_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(xgb_model_response,c(-Inf,quantile(xgb_model_response,probs=seq(.25,1,.25), na.rm=TRUE),+Inf))] 


# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(xgb_inst_cc_model, file="inst_cc_balance_refit_1_xbg1.Rdata")


# score and save
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
inst_data <- fread("installments_cc_w_kmeans_pca.csv")

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

inst_data$xgb_target_pred <- predict(xgb_inst_cc_model, inst_model_matrix, type="response")

inst_model_cc_data_scores_refit <- as.data.frame(matrix(0, ncol=2, nrow=72678))
colnames(inst_model_cc_data_scores_refit) <- c("sk_id_prev", "xgb_model_response")

inst_model_cc_data_scores_refit$sk_id_prev <- inst_data$sk_id_prev
inst_model_cc_data_scores_refit$xgb_model_response <- inst_data$xgb_target_pred


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(inst_model_cc_data_scores_refit, "inst_cc_scores_refit_1_xgb.csv")

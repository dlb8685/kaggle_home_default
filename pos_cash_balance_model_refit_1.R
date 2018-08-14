library(randomForest)
library(pROC)
library(caret)
library(xgboost)
library(data.table)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
pos_data <- fread("pos_cash_balance_w_kmeans_pca.csv")

# drop identifier columns, create factors, etc. in model data
pos_model_data <- pos_data[,!(colnames(pos_data) %in% c("V1", "sk_id_curr", "sk_id_prev", "kmeans_cluster", "name_contract_status_last")) & !(substring(colnames(pos_data), 0, 2) == "PC"), with=FALSE]

pos_model_data <- pos_model_data[!is.na(pos_model_data$target)]
colSums(is.na(pos_model_data))

pos_model_target <- pos_model_data$target  # target is a separate deal
# must convert predictors to a Matrix!
pos_model_matrix <- model.matrix(~.+0,data = pos_model_data[,-c("target"),with=F])
pos_model_matrix <- xgb.DMatrix(data = pos_model_matrix,label = pos_model_target)




ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=80, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=135, subsample=0.75, colsample_bytree=0.8, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = pos_model_matrix, nrounds = 50, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [47]	train-auc:0.551991+0.000408	test-auc:0.551140+0.000744


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=20, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=120, subsample=0.65, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = pos_model_matrix, nrounds = 50, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [32]	train-auc:0.554432+0.000743	test-auc:0.552656+0.000174


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.15, gamma=10, max_depth=0, max_leaves=25, grow_policy="lossguide", min_child_weight=50, subsample=0.6, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = pos_model_matrix, nrounds = 25, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [13]	train-auc:0.555552+0.001800	test-auc:0.553670+0.002810


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.15, gamma=15, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = pos_model_matrix, nrounds = 25, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [15]	train-auc:0.556342+0.000348	test-auc:0.554129+0.000339




ptm <- proc.time()
set.seed(070476)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.15, gamma=15, max_depth=0, max_leaves=15, grow_policy="lossguide", min_child_weight=50, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
pos_cash_balance_xgb <- xgb.train(params = params, data = pos_model_matrix, nrounds = 14, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)



# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(pos_cash_balance_xgb, file="pos_cash_balance_refit_1_xgb1.Rdata")


# drop identifier columns, create factors, etc. in model data
pos_model_data <- pos_data[,!(colnames(pos_data) %in% c("V1", "sk_id_curr", "sk_id_prev", "kmeans_cluster", "name_contract_status_last")) & !(substring(colnames(pos_data), 0, 2) == "PC"), with=FALSE]

pos_model_target <- pos_model_data$target  # target is a separate deal
# must convert predictors to a Matrix!
pos_model_matrix <- model.matrix(~.+0,data = pos_model_data[,-c("target"),with=F])
pos_model_matrix <- xgb.DMatrix(data = pos_model_matrix,label = pos_model_target)


pos_data$xgb_target_pred <- predict(pos_cash_balance_xgb, pos_model_matrix, type="response")

pos_model_data_scores_refit <- as.data.frame(matrix(0, ncol=2, nrow=936325))
colnames(pos_model_data_scores_refit) <- c("sk_id_prev", "xgb_model_response")

pos_model_data_scores_refit$sk_id_prev <- pos_data$sk_id_prev
pos_model_data_scores_refit$xgb_model_response <- pos_data$xgb_target_pred


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(pos_model_data_scores_refit, "pos_cash_bal_scores_refit_1_xgb.csv")



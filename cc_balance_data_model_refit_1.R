library(randomForest)
library(pROC)
library(caret)
library(xgboost)
library(data.table)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/kmeans groups")
cc_data <- fread("cc_balance_w_kmeans_pca.csv")

# drop identifier columns, create factors, etc. in model data
cc_model_data <- cc_data[,!(colnames(cc_data) %in% c("V1", "sk_id_curr", "kmeans8_cluster", "name_contract_status_last")) & !(substring(colnames(cc_data), 0, 2) == "PC"), with=FALSE]
cc_model_data <- cc_model_data[!is.na(cc_model_data$target)]

# now clean out the shit
cc_model_data <- cc_model_data[,!c("sk_id_prev", "kmeans8_cluster", "name_contract_status_last")]
cc_model_data <- cc_model_data[!is.na(target)]
cc_model_target <- cc_model_data$target  # target is a separate deal
# must convert predictors to a Matrix!
cc_model_matrix <- model.matrix(~.+0,data = cc_model_data[,-c("target"),with=F])
cc_model_matrix <- xgb.DMatrix(data = cc_model_matrix,label = cc_model_target)


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=105, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=4800, subsample=1, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = cc_model_matrix, nrounds = 20, nfold = 3, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [12]	train-auc:0.638407+0.001786	test-auc:0.636745+0.000596



ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=100, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=2500, subsample=1, colsample_bytree=1, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = cc_model_matrix, nrounds = 20, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm) 
    # [20]	train-auc:0.642967+0.003877	test-auc:0.641302+0.002911
    # tried a few more, but generally topping out here.



ptm <- proc.time()
set.seed(10001)
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.1, gamma=100, max_depth=0, max_leaves=7, grow_policy="lossguide", min_child_weight=2500, subsample=1, colsample_bytree=1, scale_pos_weight = 1, tree_method="hist")
cc_balance_xgb <- xgb.train(params = params, data = cc_model_matrix, nrounds = 20, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)

cc_model_data$xgb_model_response <- predict(cc_balance_xgb,cc_model_matrix, type="response")
cc_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(xgb_model_response,c(-Inf,quantile(xgb_model_response,probs=seq(.5,1,.5), na.rm=TRUE),+Inf))]  
cc_model_data[,.(target.Cnt = length(target), target.Mean = mean(target)),by=floor(xgb_model_response* 1000)/1000][order(floor)]

# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(cc_balance_xgb, file="cc_balance_refit_1_xgb1.Rdata")



# drop identifier columns, create factors, etc. in model data
cc_model_data <- cc_data[,!(colnames(cc_data) %in% c("V1", "sk_id_curr", "kmeans8_cluster", "name_contract_status_last")) & !(substring(colnames(cc_data), 0, 2) == "PC"), with=FALSE]


# now clean out the shit
cc_model_data <- cc_model_data[,!c("sk_id_prev", "kmeans8_cluster", "name_contract_status_last")]
cc_model_target <- cc_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
cc_model_matrix <- model.matrix(~.+0,data = cc_model_data[,-c("target"),with=F])
cc_model_matrix <- xgb.DMatrix(data = cc_model_matrix,label = cc_model_target)

cc_data$xgb_target_pred <- predict(cc_balance_xgb, cc_model_matrix, type="response")

cc_model_data_scores_refit <- as.data.frame(matrix(0, ncol=2, nrow=104307))
colnames(cc_model_data_scores_refit) <- c("sk_id_prev", "xgb_model_response")

cc_model_data_scores_refit$sk_id_prev <- cc_data$sk_id_prev
cc_model_data_scores_refit$xgb_model_response <- cc_data$xgb_target_pred


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(cc_model_data_scores_refit, "cc_bal_scores_refit_1_xgb.csv")



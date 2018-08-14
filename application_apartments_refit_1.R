library(xgboost)
library(data.table)
library(caret)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/application")

apt_data <- fread("application_apartments.csv")

#### XGBoosting ####
apt_model_data <- apt_data[,!(colnames(apt_data) %in% c("sk_id_curr")), with=FALSE]
apt_model_data <- apt_model_data[!is.na(target)]
apt_model_target <- apt_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
apt_model_matrix <- model.matrix(~.+0,data = apt_model_data[,-c("target"),with=F])
apt_model_matrix <- xgb.DMatrix(data = apt_model_matrix,label = apt_model_target)




ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.005, gamma=15, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=30, subsample=0.60, colsample_bytree=0.5, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = apt_model_matrix, nrounds = 50, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)



ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=25, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=75, subsample=0.60, colsample_bytree=0.5, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = apt_model_matrix, nrounds = 50, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [49]	train-auc:0.549996+0.002549	test-auc:0.548555+0.002108 


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=25, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=75, subsample=0.60, colsample_bytree=0.5, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = apt_model_matrix, nrounds = 50, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
# [50]	train-auc:0.550655+0.002344	test-auc:0.549256+0.002481 


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=20, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=60, subsample=0.60, colsample_bytree=0.5, eval_metric="auc", scale_pos_weight = 1, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = apt_model_matrix, nrounds = 60, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [60]	train-auc:0.550718+0.000832	test-auc:0.549917+0.001077


# 15 rounds with first parameter set
set.seed(102478)
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.10, gamma=20, max_depth=0, max_leaves=3, grow_policy="lossguide", min_child_weight=60, subsample=0.60, colsample_bytree=0.5, scale_pos_weight = 1, tree_method="hist")
xgb_apt_model <- xgb.train(params = params, data = apt_model_matrix, nrounds = 60, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)


# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(xgb_apt_model, file="application_apartments_refit_1_xbg1.Rdata")


# predict score on entire data set and save it for each id
apt_model_data <- apt_data[,!(colnames(apt_data) %in% c("sk_id_curr")), with=FALSE]
# apt_model_data <- apt_model_data[!is.na(target)]
apt_model_target <- apt_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
apt_model_matrix <- model.matrix(~.+0,data = apt_model_data[,-c("target"),with=F])
apt_model_matrix <- xgb.DMatrix(data = apt_model_matrix,label = apt_model_target)

apt_model_data$xgb_model_response <- predict(xgb_apt_model,apt_model_matrix, type="response")


apt_model_data_scores <- as.data.frame(matrix(0, ncol=2, nrow=356255))
colnames(apt_model_data_scores) <- c("sk_id_curr", "xgb_model_response")

apt_model_data_scores$sk_id_curr <- apt_data$sk_id_curr
apt_model_data_scores$xgb_model_response <- apt_model_data$xgb_model_response

# save scores to csv., will pick it back up later.
write.csv(apt_model_data_scores, file="apt_model_refit_1_data_scores.csv")




library(xgboost)
library(data.table)
library(caret)

setwd("/Users/Dan/Documents/Personal/kaggle/home_default/bureau models")

bureau_data_1 <- fread("bureau_model_data_1.csv")
bureau_data_2 <- fread("bureau_model_data_2.csv")
bureau_data_3 <- fread("bureau_model_data_3.csv")
bureau_data_4 <- fread("bureau_model_data_4.csv")
bureau_data_5 <- fread("bureau_model_data_5.csv")
bureau_data_6 <- fread("bureau_model_data_6.csv")
bureau_data_7 <- fread("bureau_model_data_7.csv")
bureau_data_8 <- fread("bureau_model_data_8.csv")

bureau_data <- rbind(bureau_data_1, bureau_data_2, bureau_data_3, bureau_data_4, bureau_data_5, bureau_data_6, bureau_data_7, bureau_data_8)

rm(bureau_data_1)
rm(bureau_data_2)
rm(bureau_data_3)
rm(bureau_data_4)
rm(bureau_data_5)
rm(bureau_data_6)
rm(bureau_data_7)
rm(bureau_data_8)

# had to include this column twice for dumb reasons.
bureau_data$sk_id_bureau <- bureau_data$sk_id_bureau_1
bureau_data$sk_id_bureau_1 <- NULL

colSums(is.na(bureau_data))

# For principal component analysis, only a minority of columns don't have massive # of missing values.
bureau_data_scaled <- scale(bureau_data[,(colnames(bureau_data) %in% c("credit_active_status_closed", "credit_active_status_active", "credit_active_status_sold", "credit_currency_1", "credit_currency_2", "days_credit", "credit_day_overdue", "early_payoff_flag", "early_payoff_days", "late_payoff_flag", "late_payoff_days", "cnt_credit_prolong", "amt_credit_sum_overdue", "credit_type_consumer_credit", "credit_type_credit_card", "credit_type_car_loan", "credit_type_mortgage", "credit_type_microloan", "days_credit_update")), with=FALSE])

set.seed(666)
prin_comp <- prcomp(bureau_data_scaled)
bureau_data <- cbind(bureau_data, prin_comp$x)
rm(bureau_data_scaled)


#### XGBoosting ####
bureau_model_data <- bureau_data[,!(colnames(bureau_data) %in% c("sk_id_bureau")), with=FALSE]
bureau_model_data <- bureau_model_data[!is.na(target)]
bureau_model_target <- bureau_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
bureau_model_matrix <- model.matrix(~.+0,data = bureau_model_data[,-c("target"),with=F])
bureau_model_matrix <- xgb.DMatrix(data = bureau_model_matrix,label = bureau_model_target)




# 1st crack before
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.33, gamma=5, max_depth=3, min_child_weight=5, subsample=0.80, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method = "hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 20, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    #   old...
        # [1]	train-auc:0.572474+0.000792	test-auc:0.571152+0.000372 
        # [2]	train-auc:0.583784+0.002779	test-auc:0.581902+0.001599
    #   with tree_method = "hist" ...
        # [1]	train-auc:0.572252+0.000945	test-auc:0.571079+0.000379 
        # [2]	train-auc:0.586523+0.000036	test-auc:0.584607+0.001125 


# final before
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=400, max_depth=2, min_child_weight=30, subsample=0.55, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 300, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # old ..
        # [145]	train-auc:0.598443+0.000027	test-auc:0.596821+0.000980   same for like 15 rounds, not finding new trees.
    # new ..
        # [193]	train-auc:0.598273+0.000294	test-auc:0.596846+0.000276
        # seems you could cut gamma/weight slightly now.

ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=250, max_depth=2, min_child_weight=20, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 200, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [118]	train-auc:0.600261+0.000836	test-auc:0.598273+0.000610

ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=200, max_depth=2, min_child_weight=16, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 200, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [151]	train-auc:0.601859+0.000861	test-auc:0.599861+0.000791
        # can support much lower gamma with better generalization. tree_method = "hist" is a miracle

ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=150, max_depth=2, min_child_weight=12, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 200, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [150]	train-auc:0.602281+0.000554	test-auc:0.600283+0.000791 


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=100, max_depth=2, min_child_weight=8, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 200, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # [143]	train-auc:0.602363+0.000190	test-auc:0.600378+0.000465

    
    # also tried gamma/weight of 75/6, 125/10, but that was inferior.
    # next, try the max_leaves stuff you were reading about. https://lightgbm.readthedocs.io/en/latest/Experiments.html 
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.05, gamma=100, max_depth=0, max_leaves=5, grow_policy = "lossguide", min_child_weight=8, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 250, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # max_leaves = 3
        # [200]	train-auc:0.602116+0.000277	test-auc:0.600207+0.000672 
    # max_leaves = 4
        # [122]	train-auc:0.602303+0.002058	test-auc:0.600305+0.002374
    # max_leaves = 5
        # [70]	train-auc:0.600311+0.001812	test-auc:0.598319+0.001100


ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.01, gamma=50, max_depth=0, max_leaves=4, grow_policy = "lossguide", min_child_weight=4, subsample=0.60, colsample_bytree=0.80, eval_metric="auc", scale_pos_weight = 13, tree_method="hist")
xgb1 <- xgb.cv(params = params, data = bureau_model_matrix, nrounds = 1000, nfold = 2, showsd = T, stratified = T, print_every_n = 1, maximize = F)
print(proc.time() - ptm)
    # gamma/weight = 100/8, [499]	train-auc:0.600643+0.000334	test-auc:0.598645+0.000838
    # gamma/weight = 50/4, [672]	train-auc:0.602904+0.001466	test-auc:0.600909+0.001803


### your model refit_1 is like .004 better than the old one. That is a pretty big difference for something that will be the primary variable in your final model.

### Train a model with 675 rounds. 
set.seed(102478)
ptm <- proc.time()
params <- list(booster = "gbtree", objective = "binary:logistic", eta=0.01, gamma=50, max_depth=0, max_leaves=4, grow_policy = "lossguide", min_child_weight=4, subsample=0.60, colsample_bytree=0.80, scale_pos_weight = 13, tree_method="hist")
bureau_xgb <- xgb.train(params = params, data = bureau_model_matrix, nrounds = 675, maximize = F , eval_metric = "auc", silent=0)
print(proc.time() - ptm)



# save your model
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
save(bureau_xgb, file="bureau_data_refit_1_xbg1.Rdata")

# most important variables  (keep in mind for later intuition)
importance <- xgb.importance(model = bureau_xgb)
head(importance, n=50)


setwd("/Users/Dan/Documents/Personal/kaggle/home_default/bureau models")
# bureau_data must be a version that includes test set! this was a mistake you made first time
bureau_data_1 <- fread("bureau_model_data_1.csv")
bureau_data_2 <- fread("bureau_model_data_2.csv")
bureau_data_3 <- fread("bureau_model_data_3.csv")
bureau_data_4 <- fread("bureau_model_data_4.csv")
bureau_data_5 <- fread("bureau_model_data_5.csv")
bureau_data_6 <- fread("bureau_model_data_6.csv")
bureau_data_7 <- fread("bureau_model_data_7.csv")
bureau_data_8 <- fread("bureau_model_data_8.csv")
bureau_data_test <- fread("bureau_model_data_test.csv")

bureau_data <- rbind(bureau_data_1, bureau_data_2, bureau_data_3, bureau_data_4, bureau_data_5, bureau_data_6, bureau_data_7, bureau_data_8, bureau_data_test)

rm(bureau_data_1)
rm(bureau_data_2)
rm(bureau_data_3)
rm(bureau_data_4)
rm(bureau_data_5)
rm(bureau_data_6)
rm(bureau_data_7)
rm(bureau_data_8)
rm(bureau_data_test)

# had to include this column twice for dumb reasons.
bureau_data$sk_id_bureau <- bureau_data$sk_id_bureau_1
bureau_data$sk_id_bureau_1 <- NULL


# prediction of PCs for validation dataset
bureau_data_scaled <- scale(bureau_data[,(colnames(bureau_data) %in% c("credit_active_status_closed", "credit_active_status_active", "credit_active_status_sold", "credit_currency_1", "credit_currency_2", "days_credit", "credit_day_overdue", "early_payoff_flag", "early_payoff_days", "late_payoff_flag", "late_payoff_days", "cnt_credit_prolong", "amt_credit_sum_overdue", "credit_type_consumer_credit", "credit_type_credit_card", "credit_type_car_loan", "credit_type_mortgage", "credit_type_microloan", "days_credit_update")), with=FALSE])
pred <- predict(prin_comp, newdata=bureau_data_scaled)

bureau_data <- cbind(bureau_data, pred)



bureau_model_data <- bureau_data[,!(colnames(bureau_data) %in% c("sk_id_bureau")), with=FALSE]
# bureau_model_data <- bureau_model_data[!is.na(target)]
bureau_model_target <- bureau_model_data$target  # target is a separate deal

# must convert predictors to a Matrix!
options(na.action="na.pass")    # bc a few NA's that don't make sense to convert to other stuff
bureau_model_matrix <- model.matrix(~.+0,data = bureau_model_data[,-c("target"),with=F])
bureau_model_matrix <- xgb.DMatrix(data = bureau_model_matrix,label = bureau_model_target)

bureau_model_data$xgb_model_response <- predict(bureau_xgb,bureau_model_matrix, type="response")
bureau_model_data[!is.na(target),.(target.Cnt = length(target), target.Mean = mean(target)),keyby=cut(xgb_model_response,c(-Inf,quantile(xgb_model_response,probs=seq(.1,.9,.1), na.rm=TRUE),+Inf))]

bureau_model_data_scores <- as.data.frame(matrix(0, ncol=2, nrow=1716428))
colnames(bureau_model_data_scores) <- c("sk_id_bureau", "xgb_model_response")

bureau_model_data_scores$sk_id_bureau <- bureau_data$sk_id_bureau
bureau_model_data_scores$xgb_model_response <- bureau_model_data$xgb_model_response

# save scores to csv., will pick it back up later.
setwd("/Users/Dan/Documents/Personal/kaggle/home_default/submodel refits")
write.csv(bureau_model_data_scores, file="bureau_model_data_scores_refit_1.csv")

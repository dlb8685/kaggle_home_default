select * from previous_application_data_scores limit 400


create table previous_application_data_scores_refit (
    sk_id_prev integer,
    xgb_model_response numeric
);
create index temp_idx_effo4o4p23 on previous_application_data_scores_refit(sk_id_prev);
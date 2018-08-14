/*
------
create table previous_application_data_scores (
    sk_id_prev integer,
    prev_app_xgb_segment_num integer,
    prev_app_xgb_model_response numeric
)
;
    -- uploading csv of completed predictions here.
----

create table previous_application_scored as
select
    pa.sk_id_prev, pa.sk_id_curr,
    pa.name_contract_type, pa.weekday_appr_process_start, pa.name_cash_loan_purpose, pa.name_contract_status,
    pa.name_payment_type, pa.code_reject_reason, pa.name_type_suite, pa.name_client_type,
    pa.name_goods_category, pa.name_portfolio, pa.name_product_type, pa.channel_type,
    pa.name_seller_industry, pa.name_yield_group, pa.product_combination,
    case when pa.name_contract_type = 'Cash loans' then 1 else 0 end as name_contract_type_cash,
    case when pa.name_contract_type = 'Consumer loans' then 1 else 0 end as name_contract_type_consumer,
    case when pa.name_contract_type = 'Revolving loans' then 1 else 0 end as name_contract_type_revolving,
    case when pa.name_contract_type = 'XNA' then 1 else 0 end as name_contract_type_xna,
    coalesce(pa.amt_annuity, 0) as amt_annuity,
    coalesce(pa.amt_application, 0) as amt_application, coalesce(pa.amt_credit, 0) as amt_credit, coalesce(pa.amt_down_payment, 0) as amt_down_payment,
    coalesce(pa.amt_goods_price, 0) as amt_goods_price,
    case when coalesce(pa.amt_credit, 0) = 0 then 0
        else coalesce(pa.amt_annuity, 0) / pa.amt_credit end as annuity_to_credit_amt_ratio,
    coalesce(pa.amt_annuity, 0) * coalesce(pa.cnt_payment, 0) as annuity_times_cnt_payment,
    case when coalesce(pa.amt_annuity, 0) = 0 then 0
        else coalesce(pa.amt_down_payment, 0) / pa.amt_annuity end as down_payment_to_annuity_ratio,
    case when coalesce(pa.amt_credit, 0) = 0 then 0
        else (coalesce(pa.amt_annuity, 0) * coalesce(pa.cnt_payment, 0)) / pa.amt_credit end as anty_x_cnt_pmt_to_amt_cred_ratio,
    -- estimated interest rate is kind of mathy. assumes monthly repayments.
    case when coalesce(pa.cnt_payment,0) = 0 then 0
        else
            ((case when coalesce(pa.amt_credit, 0) = 0 then 0
            else (coalesce(pa.amt_annuity, 0) * coalesce(pa.cnt_payment, 0)) / pa.amt_credit end) ^ (1.0 / cnt_payment::numeric)) ^ 12
            - 1
        end as estimated_annual_interest_rate,
    case when coalesce(pa.amt_goods_price, 0) = 0 then 0
        else coalesce(pa.amt_application, 0)::numeric / pa.amt_goods_price end as amt_application_to_goods_price_ratio,
    case when pa.weekday_appr_process_start = 'MONDAY' then 1 else 0 end as weekday_appr_process_start_mon,
    case when pa.weekday_appr_process_start = 'TUESDAY' then 1 else 0 end as weekday_appr_process_start_tue,
    case when pa.weekday_appr_process_start = 'WEDNESDAY' then 1 else 0 end as weekday_appr_process_start_wed,
    case when pa.weekday_appr_process_start = 'THURSDAY' then 1 else 0 end as weekday_appr_process_start_thr,
    case when pa.weekday_appr_process_start = 'FRIDAY' then 1 else 0 end as weekday_appr_process_start_fri,
    case when pa.weekday_appr_process_start = 'SATURDAY' then 1 else 0 end as weekday_appr_process_start_sat,
    case when pa.weekday_appr_process_start = 'SUNDAY' then 1 else 0 end as weekday_appr_process_start_sun,
    pa.hour_appr_process_start,
    case when pa.weekday_appr_process_start in ('MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY') then 1 else 0 end as appr_process_start_bt_monfri,
    case when pa.hour_appr_process_start = 23 then -1 else pa.hour_appr_process_start end - 20 as hour_appr_process_start_adj,
    case when pa.flag_last_appl_per_contract = 'Y' then 1 else 0 end as flag_last_appl_per_contract,
    pa.nflag_last_appl_in_day, coalesce(pa.rate_down_payment, 0) as rate_down_payment,
    pa.rate_interest_primary, pa.rate_interest_privileged,
    case when pa.name_cash_loan_purpose = 'XAP' then 1 else 0 end as name_cash_loan_purp_xap,
    case when pa.name_cash_loan_purpose = 'XNA' then 1 else 0 end as name_cash_loan_purp_xna,
    case when pa.name_cash_loan_purpose = 'Repairs' then 1 else 0 end as name_cash_loan_purp_repairs,
    case when pa.name_cash_loan_purpose = 'Other' then 1 else 0 end as name_cash_loan_purp_oth,
    case when pa.name_cash_loan_purpose = 'Urgent needs' then 1 else 0 end as name_cash_loan_purp_urgent,
    case when pa.name_cash_loan_purpose = 'Buying a used car' then 1 else 0 end as name_cash_loan_purp_usedcar,
    case when pa.name_cash_loan_purpose = 'Buying a house or an annex' then 1 else 0 end as name_cash_loan_purp_buildhouse,
    case when pa.name_cash_loan_purpose = 'Everyday expenses' then 1 else 0 end as name_cash_loan_purp_everyday,
    case when pa.name_cash_loan_purpose = 'Medicine' then 1 else 0 end as name_cash_loan_purp_med,
    case when pa.name_cash_loan_purpose = 'Payments on other loans' then 1 else 0 end as name_cash_loan_purp_othloans,
    case when pa.name_cash_loan_purpose = 'Education' then 1 else 0 end as name_cash_loan_purp_education,
    case when pa.name_cash_loan_purpose = 'Journey' then 1 else 0 end as name_cash_loan_purp_journey,
    case when pa.name_cash_loan_purpose = 'Purchase of electronic equipment' then 1 else 0 end as name_cash_loan_purp_electr,
    case when pa.name_cash_loan_purpose = 'Buying a new car' then 1 else 0 end as name_cash_loan_purp_newcar,
    case when pa.name_cash_loan_purpose = 'Wedding / gift / holiday' then 1 else 0 end as name_cash_loan_purp_wedding,
    case when pa.name_cash_loan_purpose = 'Buying a home' then 1 else 0 end as name_cash_loan_purp_buyhome,
    case when pa.name_cash_loan_purpose = 'Car repairs' then 1 else 0 end as name_cash_loan_purp_carrepair,
    case when pa.name_cash_loan_purpose = 'Furniture' then 1 else 0 end as name_cash_loan_purp_furnit,
    case when pa.name_cash_loan_purpose = 'Buying a holiday home / land' then 1 else 0 end as name_cash_loan_purp_holidayhome,
    case when pa.name_cash_loan_purpose = 'Business development' then 1 else 0 end as name_cash_loan_purp_busdev,
    case when pa.name_cash_loan_purpose = 'Gasification / water supply' then 1 else 0 end as name_cash_loan_purp_gasorwater,
    case when pa.name_cash_loan_purpose = 'Buying a garage' then 1 else 0 end as name_cash_loan_purp_garage,
    case when pa.name_cash_loan_purpose = 'Hobby' then 1 else 0 end as name_cash_loan_purp_hobby,
    case when pa.name_cash_loan_purpose = 'Money for a third person' then 1 else 0 end as name_cash_loan_purp_3rdperson,
    case when pa.name_contract_status = 'Approved' then 1 else 0 end as name_contract_status_approved,
    case when pa.name_contract_status = 'Canceled' then 1 else 0 end as name_contract_status_canceled,
    case when pa.name_contract_status = 'Refused' then 1 else 0 end as name_contract_status_refused,
    pa.days_decision,
    case when pa.name_payment_type = 'Cash through the bank' then 1 else 0 end as name_pmt_type_cash,
    case when pa.name_payment_type = 'XNA' then 1 else 0 end as name_pmt_type_xna,
    case when pa.name_payment_type = 'Non-cash from your account' then 1 else 0 end as name_pmt_type_noncash_thru_acct,
    case when pa.code_reject_reason = 'XAP' then 1 else 0 end as code_reject_reason_xap,
    case when pa.code_reject_reason = 'HC' then 1 else 0 end as code_reject_reason_hc,
    case when pa.code_reject_reason = 'LIMIT' then 1 else 0 end as code_reject_reason_limit,
    case when pa.code_reject_reason = 'SCO' then 1 else 0 end as code_reject_reason_sco,
    case when pa.code_reject_reason = 'CLIENT' then 1 else 0 end as code_reject_reason_client,
    case when pa.code_reject_reason = 'SCOFR' then 1 else 0 end as code_reject_reason_scofr,
    case when pa.code_reject_reason = 'XNA' then 1 else 0 end as code_reject_reason_xna,
    case when pa.code_reject_reason = 'VERIF' then 1 else 0 end as code_reject_reason_verif,
    case when pa.name_type_suite = '' then 1 else 0 end as name_type_suite_blank,
    case when pa.name_type_suite = 'Unaccompanied' then 1 else 0 end as name_type_suite_unaccompanied,
    case when pa.name_type_suite = 'Family' then 1 else 0 end as name_type_suite_family,
    case when pa.name_type_suite = 'Spouse, partner' then 1 else 0 end as name_type_suite_spouse,
    case when pa.name_type_suite = 'Children' then 1 else 0 end as name_type_suite_children,
    case when pa.name_type_suite = 'Other_B' then 1 else 0 end as name_type_suite_other_b,
    case when pa.name_client_type = 'Repeater' then 1 else 0 end as name_client_type_repeater,
    case when pa.name_client_type = 'New' then 1 else 0 end as name_client_type_new,
    case when pa.name_client_type = 'Refreshed' then 1 else 0 end as name_client_type_refreshed,
    case when pa.name_goods_category = 'XNA' then 1 else 0 end as name_goods_category_xna,
    case when pa.name_goods_category = 'Mobile' then 1 else 0 end as name_goods_category_mobile,
    case when pa.name_goods_category = 'Consumer Electronics' then 1 else 0 end as name_goods_category_electr,
    case when pa.name_goods_category = 'Computers' then 1 else 0 end as name_goods_category_compt,
    case when pa.name_goods_category = 'Audio/Video' then 1 else 0 end as name_goods_category_audiovideo,
    case when pa.name_goods_category = 'Furniture' then 1 else 0 end as name_goods_category_furnit,
    case when pa.name_goods_category = 'Photo / Cinema Equipment' then 1 else 0 end as name_goods_category_photo,
    case when pa.name_goods_category = 'Construction Materials' then 1 else 0 end as name_goods_category_constr,
    case when pa.name_goods_category = 'Clothing and Accessories' then 1 else 0 end as name_goods_category_clothes,
    case when pa.name_goods_category = 'Auto Accessories' then 1 else 0 end as name_goods_category_autoaccess,
    case when pa.name_goods_category = 'Jewelry' then 1 else 0 end as name_goods_category_jewelry,
    case when pa.name_goods_category = 'Homewares' then 1 else 0 end as name_goods_category_homeware,
    case when pa.name_goods_category = 'Medical Supplies' then 1 else 0 end as name_goods_category_medical,
    case when pa.name_goods_category = 'Vehicles' then 1 else 0 end as name_goods_category_vehicl,
    case when pa.name_goods_category = 'Sport and Leisure' then 1 else 0 end as name_goods_category_sport,
    case when pa.name_goods_category = 'Other' then 1 else 0 end as name_goods_category_other,
    case when pa.name_goods_category = 'Gardening' then 1 else 0 end as name_goods_category_gardening,
    case when pa.name_goods_category = 'Office Appliances' then 1 else 0 end as name_goods_category_office,
    case when pa.name_goods_category = 'Tourism' then 1 else 0 end as name_goods_category_tourism,
    case when pa.name_goods_category = 'Medicine' then 1 else 0 end as name_goods_category_medicine,
    case when pa.name_portfolio = 'POS' then 1 else 0 end as name_portfolio_pos,
    case when pa.name_portfolio = 'Cash' then 1 else 0 end as name_portfolio_cash,
    case when pa.name_portfolio = 'XNA' then 1 else 0 end as name_portfolio_xna,
    case when pa.name_portfolio = 'Cards' then 1 else 0 end as name_portfolio_cards,
    case when pa.name_product_type = 'XNA' then 1 else 0 end as name_product_type_xna,
    case when pa.name_product_type = 'x-sell' then 1 else 0 end as name_product_type_xsell,
    case when pa.name_product_type = 'walk-in' then 1 else 0 end as name_product_type_walkin,
    case when pa.channel_type = 'Credit and cash offices' then 1 else 0 end as channel_type_credit_cash_offices,
    case when pa.channel_type = 'Country-wide' then 1 else 0 end as channel_type_credit_countrywide,
    case when pa.channel_type = 'Stone' then 1 else 0 end as channel_type_credit_stone,
    case when pa.channel_type = 'Regional / Local' then 1 else 0 end as channel_type_credit_regional,
    case when pa.channel_type = 'Contact center' then 1 else 0 end as channel_type_credit_contact,
    case when pa.channel_type = 'AP+ (Cash loan)' then 1 else 0 end as channel_type_ap_plus,
    case when pa.channel_type = 'Channel of corporate sales' then 1 else 0 end as channel_type_corporate_sales,
    -- there are over 2,000 "areas", many with < 10 applications. Will just encode the ones with over 10k.
        -- Will also have a "score" which is the rank-order of many qualifiers where 1 is great, 40 is terrible performance.
    case when pa.sellerplace_area = -1 then 1 else 0 end as sellerplace_area_neg1,
    case when pa.sellerplace_area = 0 then 1 else 0 end as sellerplace_area_0,
    case when pa.sellerplace_area = 50 then 1 else 0 end as sellerplace_area_50,
    case when pa.sellerplace_area = 30 then 1 else 0 end as sellerplace_area_30,
    case when pa.sellerplace_area = 20 then 1 else 0 end as sellerplace_area_20,
    case when pa.sellerplace_area = 100 then 1 else 0 end as sellerplace_area_100,
    case when pa.sellerplace_area = 40 then 1 else 0 end as sellerplace_area_40,
    case when pa.sellerplace_area = 25 then 1 else 0 end as sellerplace_area_25,
    case when pa.sellerplace_area = 15 then 1 else 0 end as sellerplace_area_15,
    case when pa.sellerplace_area = 150 then 1 else 0 end as sellerplace_area_150,
    case when pa.sellerplace_area = 10 then 1 else 0 end as sellerplace_area_10,
    case when pa.sellerplace_area = 5 then 1 else 0 end as sellerplace_area_5,
    case when pa.sellerplace_area = 200 then 1 else 0 end as sellerplace_area_200,
    case when pa.sellerplace_area = 1770 then 1
        when pa.sellerplace_area = 445 then 1
        when pa.sellerplace_area = 2806 then 1
        when pa.sellerplace_area = 654 then 1
        when pa.sellerplace_area = 573 then 1
        when pa.sellerplace_area = 655 then 1
        when pa.sellerplace_area = 353 then 1
        when pa.sellerplace_area = 8636 then 1
        when pa.sellerplace_area = 1483 then 1
        when pa.sellerplace_area = 276 then 1
        when pa.sellerplace_area = 1430 then 1
        when pa.sellerplace_area = 2059 then 1
        when pa.sellerplace_area = 338 then 1
        when pa.sellerplace_area = 645 then 1
        when pa.sellerplace_area = 4900 then 1
        when pa.sellerplace_area = 2380 then 1
        when pa.sellerplace_area = 1505 then 1
        when pa.sellerplace_area = 428 then 1
        when pa.sellerplace_area = 2845 then 1
        when pa.sellerplace_area = 1535 then 1
        when pa.sellerplace_area = 2604 then 1
        when pa.sellerplace_area = 815 then 1
        when pa.sellerplace_area = 2370 then 1
        when pa.sellerplace_area = 830 then 1
        when pa.sellerplace_area = 1399 then 1
        when pa.sellerplace_area = 1820 then 1
        when pa.sellerplace_area = 888 then 1
        when pa.sellerplace_area = 611 then 1
        when pa.sellerplace_area = 1202 then 1
        when pa.sellerplace_area = 607 then 1
        when pa.sellerplace_area = 718 then 1
        when pa.sellerplace_area = 407 then 1
        when pa.sellerplace_area = 452 then 1
        when pa.sellerplace_area = 1116 then 1
        when pa.sellerplace_area = 2715 then 1
        when pa.sellerplace_area = 810 then 1
        when pa.sellerplace_area = 1074 then 1
        when pa.sellerplace_area = 414 then 1
        when pa.sellerplace_area = 2674 then 1
        when pa.sellerplace_area = 2566 then 1
        when pa.sellerplace_area = 3104 then 1
        when pa.sellerplace_area = 2430 then 1
        when pa.sellerplace_area = 1172 then 1
        when pa.sellerplace_area = 1499 then 1
        when pa.sellerplace_area = 2644 then 1
        when pa.sellerplace_area = 2266 then 1
        when pa.sellerplace_area = 1406 then 1
        when pa.sellerplace_area = 608 then 1
        when pa.sellerplace_area = 1650 then 1
        when pa.sellerplace_area = 1615 then 1
        when pa.sellerplace_area = 2265 then 1
        when pa.sellerplace_area = 1710 then 1
        when pa.sellerplace_area = 680 then 1
        when pa.sellerplace_area = 5299 then 1
        when pa.sellerplace_area = 2645 then 1
        when pa.sellerplace_area = 909 then 1
        when pa.sellerplace_area = 777 then 1
        when pa.sellerplace_area = 1103 then 1
        when pa.sellerplace_area = 1360 then 1
        when pa.sellerplace_area = 4340 then 1
        when pa.sellerplace_area = 342 then 1
        when pa.sellerplace_area = 2222 then 1
        when pa.sellerplace_area = 1719 then 1
        when pa.sellerplace_area = 1511 then 1
        when pa.sellerplace_area = 958 then 1
        when pa.sellerplace_area = 1225 then 1
        when pa.sellerplace_area = 2335 then 1
        when pa.sellerplace_area = 1608 then 1
        when pa.sellerplace_area = 2560 then 1
        when pa.sellerplace_area = 1834 then 1
        when pa.sellerplace_area = 847 then 1
        when pa.sellerplace_area = 721 then 1
        when pa.sellerplace_area = 2709 then 1
        when pa.sellerplace_area = 2421 then 1
        when pa.sellerplace_area = 396 then 1
        when pa.sellerplace_area = 2057 then 1
        when pa.sellerplace_area = 2605 then 1
        when pa.sellerplace_area = 1121 then 1
        when pa.sellerplace_area = 1222 then 1
        when pa.sellerplace_area = 3189 then 1
        when pa.sellerplace_area = 1648 then 2
        when pa.sellerplace_area = 3198 then 2
        when pa.sellerplace_area = 756 then 2
        when pa.sellerplace_area = 1012 then 2
        when pa.sellerplace_area = 784 then 2
        when pa.sellerplace_area = 489 then 2
        when pa.sellerplace_area = 393 then 2
        when pa.sellerplace_area = 3214 then 2
        when pa.sellerplace_area = 3245 then 2
        when pa.sellerplace_area = 443 then 2
        when pa.sellerplace_area = 184 then 2
        when pa.sellerplace_area = 513 then 3
        when pa.sellerplace_area = 1405 then 3
        when pa.sellerplace_area = 172 then 3
        when pa.sellerplace_area = 330 then 3
        when pa.sellerplace_area = 389 then 3
        when pa.sellerplace_area = 258 then 3
        when pa.sellerplace_area = 2301 then 3
        when pa.sellerplace_area = 1763 then 3
        when pa.sellerplace_area = 510 then 3
        when pa.sellerplace_area = 540 then 3
        when pa.sellerplace_area = 5207 then 3
        when pa.sellerplace_area = 836 then 3
        when pa.sellerplace_area = 684 then 3
        when pa.sellerplace_area = 234 then 3
        when pa.sellerplace_area = 1560 then 3
        when pa.sellerplace_area = 1057 then 4
        when pa.sellerplace_area = 1354 then 4
        when pa.sellerplace_area = 228 then 4
        when pa.sellerplace_area = 352 then 4
        when pa.sellerplace_area = 251 then 4
        when pa.sellerplace_area = 297 then 4
        when pa.sellerplace_area = 295 then 4
        when pa.sellerplace_area = 3190 then 4
        when pa.sellerplace_area = 2568 then 4
        when pa.sellerplace_area = 1581 then 4
        when pa.sellerplace_area = 376 then 4
        when pa.sellerplace_area = 1695 then 4
        when pa.sellerplace_area = 2056 then 4
        when pa.sellerplace_area = 460 then 4
        when pa.sellerplace_area = 890 then 4
        when pa.sellerplace_area = 2358 then 4
        when pa.sellerplace_area = 1339 then 4
        when pa.sellerplace_area = 911 then 4
        when pa.sellerplace_area = 1091 then 5
        when pa.sellerplace_area = 366 then 5
        when pa.sellerplace_area = 1786 then 5
        when pa.sellerplace_area = 299 then 5
        when pa.sellerplace_area = 224 then 5
        when pa.sellerplace_area = 358 then 5
        when pa.sellerplace_area = 266 then 5
        when pa.sellerplace_area = 1597 then 5
        when pa.sellerplace_area = 1044 then 5
        when pa.sellerplace_area = 1588 then 5
        when pa.sellerplace_area = 1487 then 5
        when pa.sellerplace_area = 1900 then 5
        when pa.sellerplace_area = 1707 then 5
        when pa.sellerplace_area = 575 then 5
        when pa.sellerplace_area = 602 then 5
        when pa.sellerplace_area = 3230 then 5
        when pa.sellerplace_area = 233 then 5
        when pa.sellerplace_area = 470 then 5
        when pa.sellerplace_area = 524 then 5
        when pa.sellerplace_area = 1160 then 5
        when pa.sellerplace_area = 1498 then 5
        when pa.sellerplace_area = 444 then 5
        when pa.sellerplace_area = 1328 then 5
        when pa.sellerplace_area = 3357 then 5
        when pa.sellerplace_area = 267 then 5
        when pa.sellerplace_area = 192 then 5
        when pa.sellerplace_area = 1170 then 6
        when pa.sellerplace_area = 1402 then 6
        when pa.sellerplace_area = 1465 then 6
        when pa.sellerplace_area = 181 then 6
        when pa.sellerplace_area = 3063 then 6
        when pa.sellerplace_area = 3446 then 7
        when pa.sellerplace_area = 2178 then 7
        when pa.sellerplace_area = 166 then 7
        when pa.sellerplace_area = 2112 then 7
        when pa.sellerplace_area = 4601 then 7
        when pa.sellerplace_area = 4232 then 7
        when pa.sellerplace_area = 253 then 7
        when pa.sellerplace_area = 2326 then 7
        when pa.sellerplace_area = 151 then 7
        when pa.sellerplace_area = 2078 then 7
        when pa.sellerplace_area = 2535 then 7
        when pa.sellerplace_area = 3100 then 7
        when pa.sellerplace_area = 71 then 7
        when pa.sellerplace_area = 98 then 8
        when pa.sellerplace_area = 5094 then 8
        when pa.sellerplace_area = 351 then 8
        when pa.sellerplace_area = 2105 then 8
        when pa.sellerplace_area = 402 then 8
        when pa.sellerplace_area = 1524 then 8
        when pa.sellerplace_area = 1455 then 8
        when pa.sellerplace_area = 520 then 8
        when pa.sellerplace_area = 1782 then 8
        when pa.sellerplace_area = 1892 then 8
        when pa.sellerplace_area = 951 then 8
        when pa.sellerplace_area = 2425 then 8
        when pa.sellerplace_area = 246 then 8
        when pa.sellerplace_area = 176 then 8
        when pa.sellerplace_area = 124 then 8
        when pa.sellerplace_area = 2148 then 8
        when pa.sellerplace_area = 102 then 8
        when pa.sellerplace_area = 1050 then 8
        when pa.sellerplace_area = 2600 then 8
        when pa.sellerplace_area = 103 then 8
        when pa.sellerplace_area = 128 then 8
        when pa.sellerplace_area = 162 then 8
        when pa.sellerplace_area = 156 then 9
        when pa.sellerplace_area = 3205 then 9
        when pa.sellerplace_area = 2586 then 9
        when pa.sellerplace_area = 331 then 9
        when pa.sellerplace_area = 158 then 9
        when pa.sellerplace_area = 1400 then 9
        when pa.sellerplace_area = 946 then 9
        when pa.sellerplace_area = 1550 then 9
        when pa.sellerplace_area = 3575 then 9
        when pa.sellerplace_area = 146 then 9
        when pa.sellerplace_area = 584 then 9
        when pa.sellerplace_area = 161 then 9
        when pa.sellerplace_area = 765 then 9
        when pa.sellerplace_area = 3093 then 9
        when pa.sellerplace_area = 3102 then 9
        when pa.sellerplace_area = 88 then 9
        when pa.sellerplace_area = 3600 then 9
        when pa.sellerplace_area = 240 then 9
        when pa.sellerplace_area = 130 then 10
        when pa.sellerplace_area = 2200 then 10
        when pa.sellerplace_area = 5000 then 10
        when pa.sellerplace_area = 3000 then 10
        when pa.sellerplace_area = 800 then 11
        when pa.sellerplace_area = 500 then 11
        when pa.sellerplace_area = 148 then 11
        when pa.sellerplace_area = 100 then 11
        when pa.sellerplace_area = 54 then 11
        when pa.sellerplace_area = 48 then 11
        when pa.sellerplace_area = 1500 then 11
        when pa.sellerplace_area = 2500 then 11
        when pa.sellerplace_area = 1600 then 11
        when pa.sellerplace_area = 145 then 12
        when pa.sellerplace_area = 142 then 12
        when pa.sellerplace_area = 3500 then 12
        when pa.sellerplace_area = 0 then 12
        when pa.sellerplace_area = 250 then 12
        when pa.sellerplace_area = 2000 then 12
        when pa.sellerplace_area = 700 then 12
        when pa.sellerplace_area = 1100 then 12
        when pa.sellerplace_area = 1700 then 13
        when pa.sellerplace_area = 65 then 13
        when pa.sellerplace_area = 1000 then 13
        when pa.sellerplace_area = 110 then 13
        when pa.sellerplace_area = 34 then 13
        when pa.sellerplace_area = 29 then 13
        when pa.sellerplace_area = 300 then 13
        when pa.sellerplace_area = 12 then 13
        when pa.sellerplace_area = 150 then 13
        when pa.sellerplace_area = 4000 then 13
        when pa.sellerplace_area = 350 then 13
        when pa.sellerplace_area = 600 then 13
        when pa.sellerplace_area = 180 then 13
        when pa.sellerplace_area = 18 then 13
        when pa.sellerplace_area = 52 then 13
        when pa.sellerplace_area = 120 then 13
        when pa.sellerplace_area = 80 then 13
        when pa.sellerplace_area = 46 then 13
        when pa.sellerplace_area = 31 then 13
        when pa.sellerplace_area = 51 then 13
        when pa.sellerplace_area = 47 then 13
        when pa.sellerplace_area = 200 then 14
        when pa.sellerplace_area = 33 then 14
        when pa.sellerplace_area = 2300 then 14
        when pa.sellerplace_area = 1200 then 14
        when pa.sellerplace_area = 400 then 14
        when pa.sellerplace_area = 38 then 14
        when pa.sellerplace_area = 72 then 14
        when pa.sellerplace_area = 90 then 14
        when pa.sellerplace_area = 15 then 14
        when pa.sellerplace_area = 17 then 14
        when pa.sellerplace_area = 75 then 14
        when pa.sellerplace_area = 22 then 14
        when pa.sellerplace_area = 57 then 14
        when pa.sellerplace_area = 56 then 14
        when pa.sellerplace_area = 149 then 14
        when pa.sellerplace_area = 70 then 14
        when pa.sellerplace_area = 43 then 15
        when pa.sellerplace_area = 50 then 15
        when pa.sellerplace_area = 21 then 15
        when pa.sellerplace_area = 25 then 15
        when pa.sellerplace_area = 27 then 15
        when pa.sellerplace_area = 60 then 15
        when pa.sellerplace_area = 58 then 15
        when pa.sellerplace_area = 36 then 15
        when pa.sellerplace_area = 20 then 15
        when pa.sellerplace_area = 16 then 16
        when pa.sellerplace_area = 45 then 16
        when pa.sellerplace_area = 140 then 16
        when pa.sellerplace_area = 23 then 16
        when pa.sellerplace_area = 30 then 16
        when pa.sellerplace_area = 40 then 16
        when pa.sellerplace_area = 32 then 16
        when pa.sellerplace_area = 53 then 16
        when pa.sellerplace_area = 19 then 16
        when pa.sellerplace_area = -1 then 16
        when pa.sellerplace_area = 37 then 16
        when pa.sellerplace_area = 39 then 16
        when pa.sellerplace_area = 35 then 16
        when pa.sellerplace_area = 55 then 17
        when pa.sellerplace_area = 26 then 17
        when pa.sellerplace_area = 1 then 17
        when pa.sellerplace_area = 42 then 17
        when pa.sellerplace_area = 28 then 17
        when pa.sellerplace_area = 14 then 17
        when pa.sellerplace_area = 261 then 18
        when pa.sellerplace_area = 10 then 18
        when pa.sellerplace_area = 24 then 18
        when pa.sellerplace_area = 8025 then 18
        when pa.sellerplace_area = 6 then 18
        when pa.sellerplace_area = 126 then 18
        when pa.sellerplace_area = 8 then 18
        when pa.sellerplace_area = 5 then 18
        when pa.sellerplace_area = 44 then 18
        when pa.sellerplace_area = 133 then 18
        when pa.sellerplace_area = 1690 then 18
        when pa.sellerplace_area = 41 then 18
        when pa.sellerplace_area = 2441 then 18
        when pa.sellerplace_area = 1607 then 18
        when pa.sellerplace_area = 206 then 19
        when pa.sellerplace_area = 1655 then 19
        when pa.sellerplace_area = 3560 then 19
        when pa.sellerplace_area = 68 then 19
        when pa.sellerplace_area = 64 then 19
        when pa.sellerplace_area = 1590 then 19
        when pa.sellerplace_area = 370 then 20
        when pa.sellerplace_area = 1084 then 20
        when pa.sellerplace_area = 390 then 20
        when pa.sellerplace_area = 1972 then 20
        when pa.sellerplace_area = 2929 then 21
        when pa.sellerplace_area = 139 then 21
        when pa.sellerplace_area = 143 then 21
        when pa.sellerplace_area = 79 then 21
        when pa.sellerplace_area = 2775 then 21
        when pa.sellerplace_area = 129 then 22
        when pa.sellerplace_area = 1291 then 22
        when pa.sellerplace_area = 220 then 23
        when pa.sellerplace_area = 650 then 23
        when pa.sellerplace_area = 420 then 24
        when pa.sellerplace_area = 652 then 24
        when pa.sellerplace_area = 265 then 24
        when pa.sellerplace_area = 197 then 24
        when pa.sellerplace_area = 1911 then 25
        when pa.sellerplace_area = 2 then 25
        when pa.sellerplace_area = 4 then 25
        when pa.sellerplace_area = 3 then 25
        when pa.sellerplace_area = 1810 then 27
        when pa.sellerplace_area = 230 then 27
        when pa.sellerplace_area = 306 then 28
        when pa.sellerplace_area = 4596 then 28
        when pa.sellerplace_area = 605 then 29
        when pa.sellerplace_area = 597 then 29
        when pa.sellerplace_area = 314 then 30
        when pa.sellerplace_area = 465 then 31
        when pa.sellerplace_area = 277 then 31
        when pa.sellerplace_area = 313 then 32
        when pa.sellerplace_area = 12102 then 33
        when pa.sellerplace_area = 1175 then 34
        when pa.sellerplace_area = 1916 then 36
        when pa.sellerplace_area = 2161 then 37
        when pa.sellerplace_area = 1375 then 40
        when pa.sellerplace_area = 255 then 40
        when pa.sellerplace_area = 695 then 40
        when pa.sellerplace_area = 648 then 40
        else 13               -- average on remaining odds and ends is closest to this group
        end as sellerplace_area_risk_ranking,
    case when pa.name_seller_industry = 'XNA' then 1 else 0 end as name_seller_industry_xna,
    case when pa.name_seller_industry = 'Consumer electronics' then 1 else 0 end as name_seller_industry_elect,
    case when pa.name_seller_industry = 'Connectivity' then 1 else 0 end as name_seller_industry_connect,
    case when pa.name_seller_industry = 'Furniture' then 1 else 0 end as name_seller_industry_furnit,
    case when pa.name_seller_industry = 'Construction' then 1 else 0 end as name_seller_industry_constr,
    case when pa.name_seller_industry = 'Clothing' then 1 else 0 end as name_seller_industry_clothing,
    case when pa.name_seller_industry = 'Industry' then 1 else 0 end as name_seller_industry_indst,
    case when pa.name_seller_industry = 'Auto technology' then 1 else 0 end as name_seller_industry_auto,
    case when pa.name_seller_industry = 'Jewelry' then 1 else 0 end as name_seller_industry_jewelry,
    case when pa.name_seller_industry = 'MLM partners' then 1 else 0 end as name_seller_industry_mlm,
    case when pa.name_seller_industry = pa.name_goods_category then 1 else 0 end as name_seller_ind_goods_cat_match_flag,
    coalesce(pa.cnt_payment, 0) as cnt_payment,
    case when pa.name_yield_group = 'XNA' then 1 else 0 end as name_yield_group_xna,
    case when pa.name_yield_group = 'middle' then 1 else 0 end as name_yield_group_middle,
    case when pa.name_yield_group = 'high' then 1 else 0 end as name_yield_group_high,
    case when pa.name_yield_group = 'low_normal' then 1 else 0 end as name_yield_group_low_normal,
    case when pa.name_yield_group = 'low_action' then 1 else 0 end as name_yield_group_low_action,
    case when pa.product_combination = 'Cash' then 1 else 0 end as product_combination_cash,
    case when pa.product_combination = 'POS household with interest' then 1 else 0 end as product_combination_pos_hh_wint,
    case when pa.product_combination = 'POS mobile with interest' then 1 else 0 end as product_combination_pos_mob_wint,
    case when pa.product_combination = 'Cash X-Sell: middle' then 1 else 0 end as product_combination_cash_xsell_mid,
    case when pa.product_combination = 'Cash X-Sell: low' then 1 else 0 end as product_combination_cash_xsell_low,
    case when pa.product_combination = 'Card Street' then 1 else 0 end as product_combination_card_street,
    case when pa.product_combination = 'POS industry with interest' then 1 else 0 end as product_combination_pos_ind_wint,
    case when pa.product_combination = 'POS household without interest' then 1 else 0 end as product_combination_pos_gg_woint,
    case when pa.product_combination = 'Card X-Sell' then 1 else 0 end as product_combination_card_xsell,
    case when pa.product_combination = 'Cash Street: high' then 1 else 0 end as product_combination_cash_street_high,
    case when pa.product_combination = 'Cash X-Sell: high' then 1 else 0 end as product_combination_cash_xsell_high,
    case when pa.product_combination = 'Cash Street: middle' then 1 else 0 end as product_combination_cash_street_mid,
    case when pa.product_combination = 'Cash Street: low' then 1 else 0 end as product_combination_cash_street_low,
    case when pa.product_combination = 'POS other with interest' then 1 else 0 end as product_combination_pos_oth_wint,
    case when pa.product_combination = 'POS mobile without interest' then 1 else 0 end as product_combination_pos_mob_woint,
    case when pa.product_combination = 'POS industry without interest' then 1 else 0 end as product_combination_pos_ind_woint,
    case when pa.product_combination = 'POS others without interest' then 1 else 0 end as product_combination_pos_oth_woint,
    case when pa.days_first_drawing <> 365243 then pa.days_first_drawing end as days_first_drawing,
    case when pa.days_first_due <> 365243 then pa.days_first_due end as days_first_due,
    case when pa.days_last_due_1st_version <> 365243 then pa.days_last_due_1st_version end as days_last_due_1st_version,
    case when pa.days_last_due <> 365243 then pa.days_last_due end as days_last_due,
    case when pa.days_termination <> 365243 then pa.days_termination end as days_termination,
    case when pa.days_termination <> 365243 then pa.days_termination end - pa.days_decision as days_termination_decision_diff,
    case when pa.days_last_due_1st_version <> 365243 then pa.days_last_due_1st_version end - case when pa.days_last_due <> 365243 then pa.days_last_due end as days_last_due_versions_diff,
    case when pa.name_contract_status = 'Approved' and case when pa.days_last_due <> 365243 then pa.days_last_due end is null then 1
        else 0 end as approved_no_days_last_due_flg,
    case when (case when pa.days_last_due <> 365243 then pa.days_last_due end) < (case when pa.days_last_due_1st_version <> 365243 then pa.days_last_due_1st_version end)
        then 1 else 0 end as days_last_due_lt_dld_1st_version,
    pa.nflag_insured_on_approval,
    case when pa.name_contract_status = 'Approved' and pa.nflag_insured_on_approval is null then 1 else 0 end
        as approved_and_no_insured_data_flg,
    pos.dpd_def_last as pos_dpd_def_last, pos.dpd_ever_gt_0_flg as pos_dpd_ever_gt_o_flg,
    pos.months_balance_min as pos_months_balance_min, pos.pc1 as pos_pc1, pos.pc3 as pos_pc3,
    pos.pc9 as pos_pc9, pos.pc11 as pos_pc11, pos.pc15 as pos_pc15,
    pos.pc22 as pos_pc22, pos.pc23 as pos_pc23, pos.pc25 as pos_pc25,
    (pos.months_balance_min * 30.45) - case when pa.days_first_due <> 365243 then pa.days_first_due end as pos_to_pa_acct_length_est_comparison_days,
    pos.xgb_target_pred as pos_xgb_target_pred,
    ccb.amt_payment_current_avg_3_months as ccb_amt_payment_current_avg_3_months, ccb.cnt_drawings_atm_current_12_months as ccb_cnt_drawings_atm_current_12_months,
    ccb.credit_utilization_pct_last as ccb_credit_utilization_pct_last, ccb.credit_utilization_pct_max as ccb_credit_utilization_pct_max,
    ccb.non_utilized_amount_avg as ccb_non_utilized_amount_avg, ccb.non_utilized_amount_cv as ccb_non_utilized_amount_cv,
    ccb.non_utilized_amount_last as ccb_non_utilized_amount_last, ccb.non_utilized_amount_min as ccb_non_utilized_amount_min,
    ccb.pc8 as ccb_pc8, ccb.pc14 as ccb_pc14, ccb.xgb_target_pred as ccb_xgb_target_pred,
    icc.pc23 as icc_pc23, icc.instalment_count as icc_instalment_count, icc.days_instalment_min as icc_days_instalment_min,
    icc.amt_instalment_max as icc_amt_instalment_max, icc.amt_instalment_min as icc_amt_instalment_min,
    icc.days_per_instalment as icc_days_per_instalment, icc.last_payment_rel_to_due_date_eq_0_cnt as icc_last_payment_rel_to_due_date_eq_0_cnt,
    icc.last_payment_rel_to_due_date_max as icc_last_payment_rel_to_due_date_max, icc.last_payment_rel_to_due_date_min as icc_last_payment_rel_to_due_date_min,
    icc.days_instalment_min - case when pa.days_first_due <> 365243 then pa.days_first_due end as icc_to_pa_acct_length_est_comparision_days,
    icc.xgb_target_pred as icc_xgb_target_pred,
    incc.last_payment_rel_to_due_date_min as incc_last_payment_rel_to_due_date_min, incc.last_payment_rel_to_due_date_max as incc_last_payment_rel_to_due_date_max,
    incc.amt_instalment_min as incc_amt_instalment_min, incc.days_instalment_min as incc_days_instalment_min, incc.total_payments_sum as incc_total_payments_sum,
    incc.amt_instalment_cv as incc_amt_instalment_cv, incc.amt_instalment_last_over_avg as incc_amt_instalment_last_over_avg,
    incc.days_instalment_max as incc_days_instalment_max, incc.installment_unpaid_count_7_days as incc_installment_unpaid_count_7_days,
    incc.pc6 as incc_pc6, incc.pc7 as incc_pc7, incc.pc12 as incc_pc12, incc.total_payments_cv as incc_total_payments_cv,
    incc.days_instalment_min - case when pa.days_first_due <> 365243 then pa.days_first_due end as incc_to_pa_acct_length_est_comparision_days,
    incc.xgb_target_pred as incc_xgb_target_pred,
    pds.prev_app_xgb_segment_num, pds.prev_app_xgb_model_response,
    a.target            -- select count(*)
from
    previous_application pa
    left outer join application a
        on a.sk_id_curr = pa.sk_id_curr
    left outer join pos_cash_balance_data_scores pos
        on pos.sk_id_prev = pa.sk_id_prev
    left outer join cc_balance_data_scores ccb
        on ccb.sk_id_prev = pa.sk_id_prev
    left outer join installment_cc_data_scores icc
        on icc.sk_id_prev = pa.sk_id_prev
    left outer join installment_non_cc_data_scores incc
        on incc.sk_id_prev = pa.sk_id_prev
    inner join previous_application_data_scores pds
        on pds.sk_id_prev = pa.sk_id_prev
;

create index temp_idx_f23i4jf4kjr on previous_application_scored(sk_id_curr);
*/

-- baselines for "excess risk" variables
select
    avg(ccb_xgb_target_pred) as ccb_xgb_mean,   -- 0.08962576911804400144
    avg(icc_xgb_target_pred) as icc_xgb_mean,   -- 0.10718097346796083023
    avg(incc_xgb_target_pred) as incc_xgb_mean, -- 0.07375363175343605433
    avg(pos_xgb_target_pred) as pos_xgb_mean,   -- 0.0740704501115607262
    avg(prev_app_xgb_model_response) as prev_app_xgb_mean_all,  -- 0.4910705957764651123
    avg(case when prev_app_xgb_segment_num = 1 then prev_app_xgb_model_response end) as prev_app_xgb_mean_segment_1,
        -- 0.50493877066759989394
    avg(case when prev_app_xgb_segment_num = 2 then prev_app_xgb_model_response end) as prev_app_xgb_mean_segment_2,
        -- 0.4354932280019993161
    avg(case when prev_app_xgb_segment_num = 3 then prev_app_xgb_model_response end) as prev_app_xgb_mean_segment_3
        -- 0.48398169691181959885
from previous_application_scored

/*
-- percentiles of prev_app_xgb_model_response_score
      0.1%         1%         5%        10%        50%        90%        95%        99%      99.9%
0.09218878 0.17710304 0.29412484 0.34699005 0.48867905 0.63565894 0.68607877 0.76784031 0.86299391

*/


drop table if exists temp_credit_card_balances;
create temp table temp_credit_card_balances as
select
    sk_id_curr,
    sum(case when months_from_last = 1 then amt_receivable_principal else 0 end) as amt_balance_last,
    sum(case when months_from_last = 1 then amt_credit_limit_actual else 0 end) as amt_credit_limit_last,
    sum(case when months_from_last = 1 then amt_inst_min_regularity else 0 end) as amt_inst_regularity_last,
    sum(case when months_balance = -3 then amt_receivable_principal else 0 end) as amt_balance_3_months,
    sum(case when months_balance = -3 then amt_credit_limit_actual else 0 end) as amt_credit_limit_3_months,
    sum(case when months_balance = -3 then amt_inst_min_regularity else 0 end) as amt_inst_regularity_3_months,
    sum(case when months_balance = -12 then amt_receivable_principal else 0 end) as amt_balance_12_months,
    sum(case when months_balance = -12 then amt_credit_limit_actual else 0 end) as amt_credit_limit_12_months,
    sum(case when months_balance = -12 then amt_inst_min_regularity else 0 end) as amt_inst_regularity_12_months
from
    (
    select
        sk_id_curr,
        sk_id_prev,
        amt_receivable_principal,
        amt_credit_limit_actual,
        amt_inst_min_regularity,
        months_balance,
        row_number() over (partition by sk_id_curr, sk_id_prev order by months_balance desc) as months_from_last
    from
        credit_card_balance
    ) a
where
    a.months_from_last = 1 or months_balance in (-3, -12)
group by 1
;
create index temp_idx_4fi4fj on temp_credit_card_balances(sk_id_curr);


drop table if exists previous_application_aggregated;
create table previous_application_aggregated as

select
    a.sk_id_curr,
    coalesce(x.prev_app_count, 0) as pa_count,
    coalesce(x.prev_app_count_7_days, 0) as pa_count_7_days,
    coalesce(x.prev_app_count_30_days, 0) as pa_count_30_days,
    coalesce(x.prev_app_count_90_days, 0) as pa_count_90_days,
    coalesce(x.prev_app_count_180_days, 0) as pa_count_180_days,
    coalesce(x.prev_app_count_365_days, 0) as pa_count_365_days,
    coalesce(x.prev_app_count_730_days, 0) as pa_count_730_days,
    x.pa_days_decision_min, x.pa_days_decision_max, x.pa_days_decision_min_approved, x.pa_days_decision_max_approved,
    x.pa_days_decision_min_refused, x.pa_days_decision_max_refused, x.pa_days_decision_min_canceled, x.pa_days_decision_max_canceled,
    coalesce(x.pa_approved_count, 0) as pa_approved_count,
    coalesce(x.pa_approved_count_7_days, 0) as pa_approved_count_7_days,
    coalesce(x.pa_approved_count_30_days, 0) as pa_approved_count_30_days,
    coalesce(x.pa_approved_count_90_days, 0) as pa_approved_count_90_days,
    coalesce(x.pa_approved_count_180_days, 0) as pa_approved_count_180_days,
    coalesce(x.pa_approved_count_365_days, 0) as pa_approved_count_365_days,
    coalesce(x.pa_approved_count_730_days, 0) as pa_approved_count_730_days,
    coalesce(x.pa_refused_count, 0) as pa_refused_count,
    coalesce(x.pa_refused_count_7_days, 0) as pa_refused_count_7_days,
    coalesce(x.pa_refused_count_30_days, 0) as pa_refused_count_30_days,
    coalesce(x.pa_refused_count_90_days, 0) as pa_refused_count_90_days,
    coalesce(x.pa_refused_count_180_days, 0) as pa_refused_count_180_days,
    coalesce(x.pa_refused_count_365_days, 0) as pa_refused_count_365_days,
    coalesce(x.pa_refused_count_730_days, 0) as pa_refused_count_730_days,
    coalesce(x.pa_canceled_count, 0) as pa_canceled_count,
    coalesce(x.pa_canceled_count_7_days, 0) as pa_canceled_count_7_days,
    coalesce(x.pa_canceled_count_30_days, 0) as pa_canceled_count_30_days,
    coalesce(x.pa_canceled_count_90_days, 0) as pa_canceled_count_90_days,
    coalesce(x.pa_canceled_count_180_days, 0) as pa_canceled_count_180_days,
    coalesce(x.pa_canceled_count_365_days, 0) as pa_canceled_count_365_days,
    coalesce(x.pa_canceled_count_730_days, 0) as pa_canceled_count_730_days,
    coalesce(x.pa_unused_offer_count, 0) as pa_unused_offer_count,
    coalesce(x.prev_app_count_consumer, 0) as pa_count_consumer,
    coalesce(x.prev_app_count_cash, 0) as pa_count_cash,
    coalesce(x.pa_amt_annuity_active_acct_sum, 0) as pa_amt_annuity_active_acct_sum,
    x.pa_active_acct_amt_annuity_to_credit_ratio,
    coalesce(x.pa_amt_credit_approved_sum, 0) as pa_amt_credit_approved_sum,
    coalesce(x.pa_amt_credit_approved_sum_90_days, 0) as pa_amt_credit_approved_sum_90_days,
    coalesce(x.pa_amt_credit_approved_sum_365_days, 0) as pa_amt_credit_approved_sum_365_days,
    x.pa_est_annual_int_rate_approved_accts_weighted, x.pa_est_annual_int_rate_canceled_accts_weighted, x.pa_est_annual_int_rate_refused_accts_weighted,
    x.estimated_annual_interest_rate_approved_max as pa_est_annual_interest_rate_approved_max,
    x.estimated_annual_interest_rate_approved_min as pa_est_annual_interest_rate_approved_min,
    x.estimated_annual_interest_rate_approved_stddev as pa_est_annual_interest_rate_approved_stddev,
    x.estimated_annual_interest_rate_canceled_max as pa_est_annual_interest_rate_canceled_max,
    x.estimated_annual_interest_rate_canceled_min as pa_est_annual_interest_rate_canceled_min,
    x.estimated_annual_interest_rate_refused_max as pa_est_annual_interest_rate_refused_max,
    x.estimated_annual_interest_rate_refused_min as pa_est_annual_interest_rate_refused_min,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_approved_avg as pa_anty_x_cnt_pmt_to_amt_approved_avg,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_approved_max as pa_anty_x_cnt_pmt_to_amt_approved_max,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_approved_min as pa_anty_x_cnt_pmt_to_amt_approved_min,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_approved_stddev as pa_anty_x_cnt_pmt_to_amt_approved_stddev,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_canceled_max as pa_anty_x_cnt_pmt_to_amt_canceled_max,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_canceled_min as pa_anty_x_cnt_pmt_to_amt_canceled_min,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_refused_max as pa_anty_x_cnt_pmt_to_amt_refused_max,
    x.anty_x_cnt_pmt_to_amt_cred_ratio_refused_min as pa_anty_x_cnt_pmt_to_amt_refused_min,
    coalesce(x.prev_app_count_walk_in, 0) as pa_count_walk_in,
    coalesce(x.prev_app_count_name_pmt_type_xna, 0) as pa_count_name_pmt_type_xna,
    coalesce(x.prev_app_count_purpose_not_xap_xna, 0) as pa_count_purpose_not_xap_xna,
    coalesce(x.prev_app_count_name_portf_pos, 0) as pa_count_name_portf_pos,
    coalesce(x.prev_app_count_name_portf_cash, 0) as pa_count_name_portf_cash,
    coalesce(x.prev_app_count_name_portf_xna, 0) as pa_count_name_portf_xna,
    coalesce(x.prev_app_count_name_portf_cards, 0) as pa_count_name_portf_cards,
    coalesce(x.pa_count_approved_credit_lt_25000, 0) as pa_count_approved_credit_lt_25000,
    coalesce(x.pa_count_approved_credit_gt_250000, 0) as pa_count_approved_credit_gt_250000,
    coalesce(x.pa_count_approved_down_pmt_gt_0, 0) as pa_count_approved_down_pmt_gt_0,
    coalesce(x.pa_count_active_acct, 0) as pa_count_active_acct,
    coalesce(x.pa_count_client_type_repeater, 0) as pa_count_client_type_repeater,
    coalesce(x.pa_count_client_type_new, 0) as pa_count_client_type_new,
    coalesce(x.pa_count_client_type_refreshed, 0) as pa_count_client_type_refreshed,
    x.ccb_xgb_target_pred_excess_risk_sum, x.ccb_xgb_target_pred_avg, x.ccb_xgb_target_pred_min,
    x.ccb_xgb_target_pred_max, x.ccb_xgb_target_pred_stddev, x.ccb_xgb_target_pred_cv,
    x.icc_xgb_target_pred_excess_risk_sum, x.icc_xgb_target_pred_avg, x.icc_xgb_target_pred_min,
    x.icc_xgb_target_pred_max, x.icc_xgb_target_pred_stddev, x.icc_xgb_target_pred_cv,
    x.incc_xgb_target_pred_excess_risk_sum, x.incc_xgb_target_pred_avg, x.incc_xgb_target_pred_min,
    x.incc_xgb_target_pred_max, x.incc_xgb_target_pred_stddev, x.incc_xgb_target_pred_cv,
    x.pos_xgb_target_pred_excess_risk_sum, x.pos_xgb_target_pred_avg, x.pos_xgb_target_pred_min,
    x.pos_xgb_target_pred_max, x.pos_xgb_target_pred_stddev, x.pos_xgb_target_pred_cv,
    x.prev_app_tot_target_pred_excess_risk_sum, x.prev_app_tot_target_pred_avg, x.prev_app_tot_target_pred_min,
    x.prev_app_tot_target_pred_max, x.prev_app_tot_target_pred_stddev, x.prev_app_tot_target_pred_cv,
    x.prev_app_seg1_target_pred_excess_risk_sum, x.prev_app_seg1_target_pred_avg, x.prev_app_seg1_target_pred_min,
    x.prev_app_seg1_target_pred_max, x.prev_app_seg1_target_pred_stddev, x.prev_app_seg1_target_pred_cv,
    x.prev_app_seg2_target_pred_excess_risk_sum, x.prev_app_seg2_target_pred_avg, x.prev_app_seg2_target_pred_min,
    x.prev_app_seg2_target_pred_max, x.prev_app_seg2_target_pred_stddev, x.prev_app_seg2_target_pred_cv,
    x.prev_app_seg3_target_pred_excess_risk_sum, x.prev_app_seg3_target_pred_avg, x.prev_app_seg3_target_pred_min,
    x.prev_app_seg3_target_pred_max, x.prev_app_seg3_target_pred_stddev, x.prev_app_seg3_target_pred_cv,
    coalesce(x.prev_app_xgb_model_lt_001_ntile_cnt, 0) as pa_xgb_model_lt_001_ntile_cnt,
    coalesce(x.prev_app_xgb_model_lt_01_ntile_cnt, 0) as pa_xgb_model_lt_01_ntile_cnt,
    coalesce(x.prev_app_xgb_model_lt_05_ntile_cnt, 0) as pa_xgb_model_lt_05_ntile_cnt,
    coalesce(x.prev_app_xgb_model_lt_10_ntile_cnt, 0) as pa_xgb_model_lt_10_ntile_cnt,
    coalesce(x.prev_app_xgb_model_lt_50_ntile_cnt, 0) as pa_xgb_model_lt_50_ntile_cnt,
    coalesce(x.prev_app_xgb_model_gt_90_ntile_cnt, 0) as pa_xgb_model_gt_90_ntile_cnt,
    coalesce(x.prev_app_xgb_model_gt_95_ntile_cnt, 0) as pa_xgb_model_gt_95_ntile_cnt,
    coalesce(x.prev_app_xgb_model_gt_99_ntile_cnt, 0) as pa_xgb_model_gt_99_ntile_cnt,
    coalesce(x.prev_app_xgb_model_gt_999_ntile_cnt, 0) as pa_xgb_model_gt_999_ntile_cnt,
    coalesce(x.prev_app_xgb_model_lt_001_ntile_cnt_1_year, 0) as pa_xgb_model_lt_001_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_lt_01_ntile_cnt_1_year, 0) as pa_xgb_model_lt_01_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_lt_05_ntile_cnt_1_year, 0) as pa_xgb_model_lt_05_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_lt_10_ntile_cnt_1_year, 0) as pa_xgb_model_lt_10_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_lt_50_ntile_cnt_1_year, 0) as pa_xgb_model_lt_50_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_gt_90_ntile_cnt_1_year, 0) as pa_xgb_model_gt_90_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_gt_95_ntile_cnt_1_year, 0) as pa_xgb_model_gt_95_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_gt_99_ntile_cnt_1_year, 0) as pa_xgb_model_gt_99_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_gt_999_ntile_cnt_1_year, 0) as pa_xgb_model_gt_999_ntile_cnt_1_year,
    coalesce(x.prev_app_xgb_model_lt_001_ntile_cnt_90_days, 0) as pa_xgb_model_lt_001_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_lt_01_ntile_cnt_90_days, 0) as pa_xgb_model_lt_01_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_lt_05_ntile_cnt_90_days, 0) as pa_xgb_model_lt_05_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_lt_10_ntile_cnt_90_days, 0) as pa_xgb_model_lt_10_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_lt_50_ntile_cnt_90_days, 0) as pa_xgb_model_lt_50_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_gt_90_ntile_cnt_90_days, 0) as pa_xgb_model_gt_90_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_gt_95_ntile_cnt_90_days, 0) as pa_xgb_model_gt_95_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_gt_99_ntile_cnt_90_days, 0) as pa_xgb_model_gt_99_ntile_cnt_90_days,
    coalesce(x.prev_app_xgb_model_gt_999_ntile_cnt_90_days, 0) as pa_xgb_model_gt_999_ntile_cnt_90_days,
    x.sellerplace_area_risk_avg as pa_sellerplace_area_risk_avg, x.sellerplace_area_risk_min as pa_sellerplace_area_risk_min,
    x.sellerplace_area_risk_max as pa_sellerplace_area_risk_max, x.sellerplace_area_risk_sd as pa_sellerplace_area_risk_sd,
    coalesce(x.sellerplace_area_gte_40_cnt, 0) as pa_sellerplace_area_gte_40_cnt,
    coalesce(x.sellerplace_area_gte_25_cnt, 0) as pa_sellerplace_area_gte_25_cnt,
    coalesce(x.sellerplace_area_gte_18_cnt, 0) as pa_sellerplace_area_gte_18_cnt,
    coalesce(x.sellerplace_area_lte_10_cnt, 0) as pa_sellerplace_area_lte_10_cnt,
    coalesce(x.sellerplace_area_lte_7_cnt, 0) as pa_sellerplace_area_lte_7_cnt,
    coalesce(x.sellerplace_area_lte_1_cnt, 0) as pa_sellerplace_area_lte_1_cnt,
    x.sellerplace_area_risk_avg_1_year as pa_sellerplace_area_risk_avg_1_year, x.sellerplace_area_risk_min_1_year as pa_sellerplace_area_risk_min_1_year,
    x.sellerplace_area_risk_max_1_year as pa_sellerplace_area_risk_max_1_year, x.sellerplace_area_risk_sd_1_year as pa_sellerplace_area_risk_sd_1_year,
    coalesce(x.sellerplace_area_gte_40_cnt_1_year, 0) as pa_sellerplace_area_gte_40_cnt_1_year,
    coalesce(x.sellerplace_area_gte_25_cnt_1_year, 0) as pa_sellerplace_area_gte_25_cnt_1_year,
    coalesce(x.sellerplace_area_gte_18_cnt_1_year, 0) as pa_sellerplace_area_gte_18_cnt_1_year,
    coalesce(x.sellerplace_area_lte_10_cnt_1_year, 0) as pa_sellerplace_area_lte_10_cnt_1_year,
    coalesce(x.sellerplace_area_lte_7_cnt_1_year, 0) as pa_sellerplace_area_lte_7_cnt_1_year,
    coalesce(x.sellerplace_area_lte_1_cnt_1_year, 0) as pa_sellerplace_area_lte_1_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_lt_001_ntile_cnt, 0) as pa_est_int_rate_lt_001_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_lt_01_ntile_cnt, 0) as pa_est_int_rate_lt_01_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_lt_05_ntile_cnt, 0) as pa_est_int_rate_lt_05_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_lt_10_ntile_cnt, 0) as pa_est_int_rate_lt_10_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_lt_50_ntile_cnt, 0) as pa_est_int_rate_lt_50_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_gt_90_ntile_cnt, 0) as pa_est_int_rate_gt_90_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_gt_95_ntile_cnt, 0) as pa_est_int_rate_gt_95_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_gt_99_ntile_cnt, 0) as pa_est_int_rate_gt_99_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_gt_999_ntile_cnt, 0) as pa_est_int_rate_gt_999_ntile_cnt,
    coalesce(x.prev_app_est_int_rate_lt_001_ntile_cnt_90_days, 0) as pa_est_int_rate_lt_001_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_lt_01_ntile_cnt_90_days, 0) as pa_est_int_rate_lt_01_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_lt_05_ntile_cnt_90_days, 0) as pa_est_int_rate_lt_05_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_lt_10_ntile_cnt_90_days, 0) as pa_est_int_rate_lt_10_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_lt_50_ntile_cnt_90_days, 0) as pa_est_int_rate_lt_50_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_gt_90_ntile_cnt_90_days, 0) as pa_est_int_rate_gt_90_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_gt_95_ntile_cnt_90_days, 0) as pa_est_int_rate_gt_95_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_gt_99_ntile_cnt_90_days, 0) as pa_est_int_rate_gt_99_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_gt_999_ntile_cnt_90_days, 0) as pa_est_int_rate_gt_999_ntile_cnt_90_days,
    coalesce(x.prev_app_est_int_rate_lt_001_ntile_cnt_1_year, 0) as pa_est_int_rate_lt_001_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_lt_01_ntile_cnt_1_year, 0) as pa_est_int_rate_lt_01_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_lt_05_ntile_cnt_1_year, 0) as pa_est_int_rate_lt_05_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_lt_10_ntile_cnt_1_year, 0) as pa_est_int_rate_lt_10_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_lt_50_ntile_cnt_1_year, 0) as pa_est_int_rate_lt_50_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_gt_90_ntile_cnt_1_year, 0) as pa_est_int_rate_gt_90_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_gt_95_ntile_cnt_1_year, 0) as pa_est_int_rate_gt_95_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_gt_99_ntile_cnt_1_year, 0) as pa_est_int_rate_gt_99_ntile_cnt_1_year,
    coalesce(x.prev_app_est_int_rate_gt_999_ntile_cnt_1_year, 0) as pa_est_int_rate_gt_999_ntile_cnt_1_year,
    x.approved_pos_rate_down_payment_avg as pa_apprv_pos_rate_down_payment_avg,
    x.approved_pos_rate_down_payment_min as pa_apprv_pos_rate_down_payment_min,
    x.approved_pos_rate_down_payment_max as pa_apprv_pos_rate_down_payment_max,
    x.approved_pos_rate_down_payment_sd as pa_apprv_pos_rate_down_payment_sd,
    -- application variables.

    -- use this to create interactions, etc.

    -- target
    a.target
from
application a
left join (
select
    pa.sk_id_curr,
    count(*) as prev_app_count, count(case when days_decision >= -7 then 1 end) as prev_app_count_7_days,
    count(case when days_decision >= -30 then 1 end) as prev_app_count_30_days, count(case when days_decision >= -90 then 1 end) as prev_app_count_90_days,
    count(case when days_decision >= -180 then 1 end) as prev_app_count_180_days, count(case when days_decision >= -365 then 1 end) as prev_app_count_365_days,
    count(case when days_decision >= -730 then 1 end) as prev_app_count_730_days,
    min(days_decision) as pa_days_decision_min, max(days_decision) as pa_days_decision_max,
    min(case when name_contract_status = 'Approved' then days_decision end) as pa_days_decision_min_approved, max(case when name_contract_status = 'Approved' then days_decision end) as pa_days_decision_max_approved,
    min(case when name_contract_status = 'Refused' then days_decision end) as pa_days_decision_min_refused, max(case when name_contract_status = 'Refused' then days_decision end) as pa_days_decision_max_refused,
    min(case when name_contract_status = 'Canceled' then days_decision end) as pa_days_decision_min_canceled, max(case when name_contract_status = 'Canceled' then days_decision end) as pa_days_decision_max_canceled,
    count(case when name_contract_status = 'Approved' then 1 end) as pa_approved_count,
    count(case when name_contract_status = 'Approved' and days_decision >= -7 then 1 end) as pa_approved_count_7_days, count(case when name_contract_status = 'Approved' and days_decision >= -30 then 1 end) as pa_approved_count_30_days,
    count(case when name_contract_status = 'Approved' and days_decision >= -90 then 1 end) as pa_approved_count_90_days, count(case when name_contract_status = 'Approved' and days_decision >= -180 then 1 end) as pa_approved_count_180_days,
    count(case when name_contract_status = 'Approved' and days_decision >= -365 then 1 end) as pa_approved_count_365_days, count(case when name_contract_status = 'Approved' and days_decision >= -730 then 1 end) as pa_approved_count_730_days,
    count(case when name_contract_status = 'Refused' then 1 end) as pa_refused_count,
    count(case when name_contract_status = 'Refused' and days_decision >= -7 then 1 end) as pa_refused_count_7_days, count(case when name_contract_status = 'Refused' and days_decision >= -30 then 1 end) as pa_refused_count_30_days,
    count(case when name_contract_status = 'Refused' and days_decision >= -90 then 1 end) as pa_refused_count_90_days, count(case when name_contract_status = 'Refused' and days_decision >= -180 then 1 end) as pa_refused_count_180_days,
    count(case when name_contract_status = 'Refused' and days_decision >= -365 then 1 end) as pa_refused_count_365_days, count(case when name_contract_status = 'Refused' and days_decision >= -730 then 1 end) as pa_refused_count_730_days,
    count(case when name_contract_status = 'Canceled' then 1 end) as pa_canceled_count,
    count(case when name_contract_status = 'Canceled' and days_decision >= -7 then 1 end) as pa_canceled_count_7_days, count(case when name_contract_status = 'Canceled' and days_decision >= -30 then 1 end) as pa_canceled_count_30_days,
    count(case when name_contract_status = 'Canceled' and days_decision >= -90 then 1 end) as pa_canceled_count_90_days, count(case when name_contract_status = 'Canceled' and days_decision >= -180 then 1 end) as pa_canceled_count_180_days,
    count(case when name_contract_status = 'Canceled' and days_decision >= -365 then 1 end) as pa_canceled_count_365_days, count(case when name_contract_status = 'Canceled' and days_decision >= -730 then 1 end) as pa_canceled_count_730_days,
    count(case when name_contract_status = 'Unused offer' then 1 end) as pa_unused_offer_count,
    count(case when pa.name_contract_type = 'Consumer loans' then 1 end) as prev_app_count_consumer, count(case when pa.name_contract_type = 'Cash loans' then 1 end) as prev_app_count_cash,
    sum(case when name_contract_status = 'Approved' and coalesce(days_termination, 365243) <> 365243 then amt_annuity else 0 end) as pa_amt_annuity_active_acct_sum,
    case when sum(case when name_contract_status = 'Approved' and coalesce(days_termination, 365243) <> 365243 then amt_credit else 0 end) = 0 then null
        else sum(case when name_contract_status = 'Approved' and coalesce(days_termination, 365243) <> 365243 then amt_annuity else 0 end)
            / sum(case when name_contract_status = 'Approved' and coalesce(days_termination, 365243) <> 365243 then amt_credit else 0 end)
        end as pa_active_acct_amt_annuity_to_credit_ratio,
    sum(case when name_contract_status = 'Approved' then amt_credit else 0 end) as pa_amt_credit_approved_sum,
    sum(case when name_contract_status = 'Approved' and days_decision >= -90 then amt_credit else 0 end) as pa_amt_credit_approved_sum_90_days,
    sum(case when name_contract_status = 'Approved' and days_decision >= -365 then amt_credit else 0 end) as pa_amt_credit_approved_sum_365_days,
    -- estimated interest rate is kind of mathy. assumes monthly repayments. weight it by amt_credit on all approved accounts
    case when sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Approved' then 0 else pa.amt_credit end) = 0 then null
    else sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Approved' then 0
            else pa.estimated_annual_interest_rate * pa.amt_credit end)
        /
        sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Approved' then 0
            else pa.amt_credit end)
        end as pa_est_annual_int_rate_approved_accts_weighted,
    case when sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Canceled' then 0 else pa.amt_credit end) = 0 then null
    else sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Canceled' then 0
            else pa.estimated_annual_interest_rate * pa.amt_credit end)
        /
        sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Canceled' then 0
            else pa.amt_credit end)
        end as pa_est_annual_int_rate_canceled_accts_weighted,
    case when sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Refused' then 0 else pa.amt_credit end) = 0 then null
    else sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Refused' then 0
            else pa.estimated_annual_interest_rate * pa.amt_credit end)
        /
        sum(case when coalesce(pa.estimated_annual_interest_rate, 0) = 0 or name_contract_status <> 'Refused' then 0
            else pa.amt_credit end)
        end as pa_est_annual_int_rate_refused_accts_weighted,
    max(case when pa.name_contract_status = 'Approved' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_approved_max,
    min(case when pa.name_contract_status = 'Approved' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_approved_min,
    stddev(case when pa.name_contract_status = 'Approved' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_approved_stddev,
    max(case when pa.name_contract_status = 'Canceled' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_canceled_max,
    min(case when pa.name_contract_status = 'Canceled' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_canceled_min,
    max(case when pa.name_contract_status = 'Refused' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_refused_max,
    min(case when pa.name_contract_status = 'Refused' and pa.estimated_annual_interest_rate <> 0 then pa.estimated_annual_interest_rate end) as estimated_annual_interest_rate_refused_min,
    avg(case when pa.name_contract_status = 'Approved' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_approved_avg,
    max(case when pa.name_contract_status = 'Approved' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_approved_max,
    min(case when pa.name_contract_status = 'Approved' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_approved_min,
    stddev(case when pa.name_contract_status = 'Approved' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_approved_stddev,
    max(case when pa.name_contract_status = 'Canceled' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_canceled_max,
    min(case when pa.name_contract_status = 'Canceled' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_canceled_min,
    max(case when pa.name_contract_status = 'Refused' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_refused_max,
    min(case when pa.name_contract_status = 'Refused' and pa.anty_x_cnt_pmt_to_amt_cred_ratio <> 0 then pa.anty_x_cnt_pmt_to_amt_cred_ratio end) as anty_x_cnt_pmt_to_amt_cred_ratio_refused_min,

    count(case when name_contract_type = 'walk-in' then 1 end) as prev_app_count_walk_in, count(case when name_payment_type = 'XNA' then 1 end) as prev_app_count_name_pmt_type_xna,
    count(case when name_cash_loan_purpose not in ('XAP', 'XNA') then 1 end) as prev_app_count_purpose_not_xap_xna,
    count(case when name_portfolio = 'POS' then 1 end) as prev_app_count_name_portf_pos, count(case when name_portfolio = 'Cash' then 1 end) as prev_app_count_name_portf_cash,
    count(case when name_portfolio = 'XNA' then 1 end) as prev_app_count_name_portf_xna, count(case when name_portfolio = 'Cards' then 1 end) as prev_app_count_name_portf_cards,
    count(case when name_contract_status = 'Approved' and amt_credit < 25000 then 1 end) as pa_count_approved_credit_lt_25000,
    count(case when name_contract_status = 'Approved' and amt_credit > 250000 then 1 end) as pa_count_approved_credit_gt_250000,
    count(case when name_contract_status = 'Approved' and amt_down_payment > 0 then 1 end) as pa_count_approved_down_pmt_gt_0,
    sum(case when name_contract_status = 'Approved' and coalesce(days_termination, 365243) <> 365243 then 1 else 0 end) as pa_count_active_acct,
    count(case when name_client_type = 'Repeater' then 1 end) as pa_count_client_type_repeater, count(case when name_client_type = 'New' then 1 end) as pa_count_client_type_new,
    count(case when name_client_type = 'Refreshed' then 1 end) as pa_count_client_type_refreshed,

    sum(pa.ccb_xgb_target_pred - 0.08962576911804400144) as ccb_xgb_target_pred_excess_risk_sum,
    avg(pa.ccb_xgb_target_pred) as ccb_xgb_target_pred_avg,
    min(pa.ccb_xgb_target_pred) as ccb_xgb_target_pred_min,
    max(pa.ccb_xgb_target_pred) as ccb_xgb_target_pred_max,
    stddev(pa.ccb_xgb_target_pred) as ccb_xgb_target_pred_stddev,
    stddev(pa.ccb_xgb_target_pred) / avg(pa.ccb_xgb_target_pred) as ccb_xgb_target_pred_cv,
    sum(pa.icc_xgb_target_pred - 0.10718097346796083023) as icc_xgb_target_pred_excess_risk_sum,
    avg(pa.icc_xgb_target_pred) as icc_xgb_target_pred_avg,
    min(pa.icc_xgb_target_pred) as icc_xgb_target_pred_min,
    max(pa.icc_xgb_target_pred) as icc_xgb_target_pred_max,
    stddev(pa.icc_xgb_target_pred) as icc_xgb_target_pred_stddev,
    stddev(pa.icc_xgb_target_pred) / avg(pa.icc_xgb_target_pred) as icc_xgb_target_pred_cv,
    sum(pa.incc_xgb_target_pred - 0.07375363175343605433) as incc_xgb_target_pred_excess_risk_sum,
    avg(pa.incc_xgb_target_pred) as incc_xgb_target_pred_avg,
    min(pa.incc_xgb_target_pred) as incc_xgb_target_pred_min,
    max(pa.incc_xgb_target_pred) as incc_xgb_target_pred_max,
    stddev(pa.incc_xgb_target_pred) as incc_xgb_target_pred_stddev,
    stddev(pa.incc_xgb_target_pred) / avg(pa.icc_xgb_target_pred) as incc_xgb_target_pred_cv,
    sum(pa.pos_xgb_target_pred - 0.0740704501115607262) as pos_xgb_target_pred_excess_risk_sum,
    avg(pa.pos_xgb_target_pred) as pos_xgb_target_pred_avg,
    min(pa.pos_xgb_target_pred) as pos_xgb_target_pred_min,
    max(pa.pos_xgb_target_pred) as pos_xgb_target_pred_max,
    stddev(pa.pos_xgb_target_pred) as pos_xgb_target_pred_stddev,
    stddev(pa.pos_xgb_target_pred) / avg(pa.pos_xgb_target_pred) as pos_xgb_target_pred_cv,

    sum(pa.prev_app_xgb_model_response - 0.4910705957764651123) as prev_app_tot_target_pred_excess_risk_sum,
    avg(pa.prev_app_xgb_model_response) as prev_app_tot_target_pred_avg,
    min(pa.prev_app_xgb_model_response) as prev_app_tot_target_pred_min,
    max(pa.prev_app_xgb_model_response) as prev_app_tot_target_pred_max,
    stddev(pa.prev_app_xgb_model_response) as prev_app_tot_target_pred_stddev,
    stddev(pa.prev_app_xgb_model_response) / avg(pa.pos_xgb_target_pred) as prev_app_tot_target_pred_cv,
    sum(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end - 0.50493877066759989394) as prev_app_seg1_target_pred_excess_risk_sum,
    avg(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end) as prev_app_seg1_target_pred_avg,
    min(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end) as prev_app_seg1_target_pred_min,
    max(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end) as prev_app_seg1_target_pred_max,
    stddev(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end) as prev_app_seg1_target_pred_stddev,
    stddev(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end)
        / avg(case when pa.prev_app_xgb_segment_num = 1 then pa.prev_app_xgb_model_response end) as prev_app_seg1_target_pred_cv,
    sum(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end - 0.4354932280019993161) as prev_app_seg2_target_pred_excess_risk_sum,
    avg(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end) as prev_app_seg2_target_pred_avg,
    min(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end) as prev_app_seg2_target_pred_min,
    max(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end) as prev_app_seg2_target_pred_max,
    stddev(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end) as prev_app_seg2_target_pred_stddev,
    stddev(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end)
        / avg(case when pa.prev_app_xgb_segment_num = 2 then pa.prev_app_xgb_model_response end) as prev_app_seg2_target_pred_cv,
    sum(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end - 0.48398169691181959885) as prev_app_seg3_target_pred_excess_risk_sum,
    avg(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end) as prev_app_seg3_target_pred_avg,
    min(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end) as prev_app_seg3_target_pred_min,
    max(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end) as prev_app_seg3_target_pred_max,
    stddev(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end) as prev_app_seg3_target_pred_stddev,
    stddev(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end)
        / avg(case when pa.prev_app_xgb_segment_num = 3 then pa.prev_app_xgb_model_response end) as prev_app_seg3_target_pred_cv,

    count(case when pa.prev_app_xgb_model_response < .09218878 then 1 end) as prev_app_xgb_model_lt_001_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response < .17710304 then 1 end) as prev_app_xgb_model_lt_01_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response < .29412484 then 1 end) as prev_app_xgb_model_lt_05_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response < .34699005 then 1 end) as prev_app_xgb_model_lt_10_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response < .48867905 then 1 end) as prev_app_xgb_model_lt_50_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response > .63565894 then 1 end) as prev_app_xgb_model_gt_90_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response > .68607877 then 1 end) as prev_app_xgb_model_gt_95_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response > .76784031 then 1 end) as prev_app_xgb_model_gt_99_ntile_cnt,
    count(case when pa.prev_app_xgb_model_response > .86299391 then 1 end) as prev_app_xgb_model_gt_999_ntile_cnt,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response < .09218878 then 1 end) as prev_app_xgb_model_lt_001_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response < .17710304 then 1 end) as prev_app_xgb_model_lt_01_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response < .29412484 then 1 end) as prev_app_xgb_model_lt_05_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response < .34699005 then 1 end) as prev_app_xgb_model_lt_10_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response < .48867905 then 1 end) as prev_app_xgb_model_lt_50_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response > .63565894 then 1 end) as prev_app_xgb_model_gt_90_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response > .68607877 then 1 end) as prev_app_xgb_model_gt_95_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response > .76784031 then 1 end) as prev_app_xgb_model_gt_99_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.prev_app_xgb_model_response > .86299391 then 1 end) as prev_app_xgb_model_gt_999_ntile_cnt_1_year,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response < .09218878 then 1 end) as prev_app_xgb_model_lt_001_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response < .17710304 then 1 end) as prev_app_xgb_model_lt_01_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response < .29412484 then 1 end) as prev_app_xgb_model_lt_05_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response < .34699005 then 1 end) as prev_app_xgb_model_lt_10_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response < .48867905 then 1 end) as prev_app_xgb_model_lt_50_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response > .63565894 then 1 end) as prev_app_xgb_model_gt_90_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response > .68607877 then 1 end) as prev_app_xgb_model_gt_95_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response > .76784031 then 1 end) as prev_app_xgb_model_gt_99_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.prev_app_xgb_model_response > .86299391 then 1 end) as prev_app_xgb_model_gt_999_ntile_cnt_90_days,
    avg(pa.sellerplace_area_risk_ranking) as sellerplace_area_risk_avg,
    min(pa.sellerplace_area_risk_ranking) as sellerplace_area_risk_min,
    max(pa.sellerplace_area_risk_ranking) as sellerplace_area_risk_max,
    stddev(pa.sellerplace_area_risk_ranking) as sellerplace_area_risk_sd,
    count(case when pa.sellerplace_area_risk_ranking >= 40 then 1 end) as sellerplace_area_gte_40_cnt,
    count(case when pa.sellerplace_area_risk_ranking >= 25 then 1 end) as sellerplace_area_gte_25_cnt,
    count(case when pa.sellerplace_area_risk_ranking >= 18 then 1 end) as sellerplace_area_gte_18_cnt,
    count(case when pa.sellerplace_area_risk_ranking <= 10 then 1 end) as sellerplace_area_lte_10_cnt,
    count(case when pa.sellerplace_area_risk_ranking <= 7 then 1 end) as sellerplace_area_lte_7_cnt,
    count(case when pa.sellerplace_area_risk_ranking <= 1 then 1 end) as sellerplace_area_lte_1_cnt,
    avg(case when pa.days_decision >= -365 then pa.sellerplace_area_risk_ranking end) as sellerplace_area_risk_avg_1_year,
    min(case when pa.days_decision >= -365 then pa.sellerplace_area_risk_ranking end) as sellerplace_area_risk_min_1_year,
    max(case when pa.days_decision >= -365 then pa.sellerplace_area_risk_ranking end) as sellerplace_area_risk_max_1_year,
    stddev(case when pa.days_decision >= -365 then pa.sellerplace_area_risk_ranking end) as sellerplace_area_risk_sd_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking >= 40 then 1 end) as sellerplace_area_gte_40_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking >= 25 then 1 end) as sellerplace_area_gte_25_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking >= 18 then 1 end) as sellerplace_area_gte_18_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking <= 10 then 1 end) as sellerplace_area_lte_10_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking <= 7 then 1 end) as sellerplace_area_lte_7_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.sellerplace_area_risk_ranking <= 1 then 1 end) as sellerplace_area_lte_1_cnt_1_year,

    count(case when pa.estimated_annual_interest_rate < 0.03980569 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_001_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate < 0.04038337 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_01_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate < 0.09618842 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_05_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate < 0.11451389 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_10_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate < 0.22728550 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_50_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate > 0.45136754 then 1 end) as prev_app_est_int_rate_gt_90_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate > 0.49319427 then 1 end) as prev_app_est_int_rate_gt_95_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate > 0.55600142 then 1 end) as prev_app_est_int_rate_gt_99_ntile_cnt,
    count(case when pa.estimated_annual_interest_rate > 0.65652387 then 1 end) as prev_app_est_int_rate_gt_999_ntile_cnt,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate < 0.03980569 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_001_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate < 0.04038337 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_01_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate < 0.09618842 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_05_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate < 0.11451389 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_10_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate < 0.22728550 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_50_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate > 0.45136754 then 1 end) as prev_app_est_int_rate_gt_90_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate > 0.49319427 then 1 end) as prev_app_est_int_rate_gt_95_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate > 0.55600142 then 1 end) as prev_app_est_int_rate_gt_99_ntile_cnt_90_days,
    count(case when pa.days_decision >= -90 and pa.estimated_annual_interest_rate > 0.65652387 then 1 end) as prev_app_est_int_rate_gt_999_ntile_cnt_90_days,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate < 0.03980569 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_001_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate < 0.04038337 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_01_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate < 0.09618842 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_05_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate < 0.11451389 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_10_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate < 0.22728550 and pa.estimated_annual_interest_rate <> 0 then 1 end) as prev_app_est_int_rate_lt_50_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate > 0.45136754 then 1 end) as prev_app_est_int_rate_gt_90_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate > 0.49319427 then 1 end) as prev_app_est_int_rate_gt_95_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate > 0.55600142 then 1 end) as prev_app_est_int_rate_gt_99_ntile_cnt_1_year,
    count(case when pa.days_decision >= -365 and pa.estimated_annual_interest_rate > 0.65652387 then 1 end) as prev_app_est_int_rate_gt_999_ntile_cnt_1_year,
    -- credit card utilization
    max(ccb.amt_balance_last) as ccb_amt_balance_last,
    max(ccb.amt_credit_limit_last) as ccb_amt_credit_limit_last,
    case when max(ccb.amt_credit_limit_last) = 0 then null
        else max(ccb.amt_balance_last) / max(ccb.amt_credit_limit_last)
        end as ccb_utilization_pct_last,
    max(ccb.amt_inst_regularity_last) as ccb_amt_inst_regularity_last,
    max(ccb.amt_balance_3_months) as ccb_amt_balance_3_months,
    max(ccb.amt_credit_limit_3_months) as ccb_amt_credit_limit_3_months,
    case when max(ccb.amt_credit_limit_3_months) = 0 then null
        else max(ccb.amt_balance_3_months) / max(ccb.amt_credit_limit_3_months)
        end as ccb_utilization_pct_3_months,
    max(ccb.amt_inst_regularity_3_months) as ccb_amt_inst_regularity_3_months,
    max(ccb.amt_balance_12_months) as ccb_amt_balance_12_months,
    max(ccb.amt_credit_limit_12_months) as ccb_amt_credit_limit_12_months,
    case when max(ccb.amt_credit_limit_12_months) = 0 then null
        else max(ccb.amt_balance_12_months) / max(ccb.amt_credit_limit_12_months)
        end as ccb_utilization_pct_12_months,
    max(ccb.amt_inst_regularity_12_months) as ccb_amt_inst_regularity_12_months,

    avg(case when pa.prev_app_xgb_segment_num = 3 then pa.rate_down_payment end) as approved_pos_rate_down_payment_avg,
    min(case when pa.prev_app_xgb_segment_num = 3 then pa.rate_down_payment end) as approved_pos_rate_down_payment_min,
    max(case when pa.prev_app_xgb_segment_num = 3 then pa.rate_down_payment end) as approved_pos_rate_down_payment_max,
    stddev(case when pa.prev_app_xgb_segment_num = 3 then pa.rate_down_payment end) as approved_pos_rate_down_payment_sd
from
    previous_application_scored pa
    left outer join temp_credit_card_balances ccb
        on ccb.sk_id_curr = pa.sk_id_curr

group by 1
) x on a.sk_id_curr = x.sk_id_curr
order by 1
;


select pa_xgb_model_gt_95_ntile_cnt, count(*), avg(target)
from previous_application_aggregated
where target is not null
group by 1
order by 1


select case when incc_xgb_target_pred_excess_risk_sum is null then null
    else greatest(least(floor(incc_xgb_target_pred_excess_risk_sum * 100) / 100, .15), -.15)
    end, count(*), avg(target)
from previous_application_aggregated
where target is not null
group by 1
order by 1

select case when prev_app_tot_target_pred_excess_risk_sum is null then null
    else greatest(least(floor(prev_app_tot_target_pred_excess_risk_sum * 50) / 50, .25), -.25)
    end, count(*), avg(target)
from previous_application_aggregated
where target is not null
group by 1
order by 1

select case when prev_app_tot_target_pred_avg is null then null
    else floor(prev_app_tot_target_pred_avg * 20) / 20
    end, count(*), avg(target)
from previous_application_aggregated
where target is not null
group by 1
order by 1


select case when incc_xgb_target_pred_avg is null then null
    else least(floor(incc_xgb_target_pred_avg * 100) / 100, .20)
    end, count(*), avg(target)
from previous_application_aggregated
where target is not null
group by 1
order by 1


select case when prev_app_tot_target_pred_avg is null then null
    else floor(prev_app_tot_target_pred_avg * 20) / 20
    end, case when a.ext_source_2 > .55 then 1 else 0 end, count(*), avg(pa.target)
from previous_application_aggregated pa inner join application a on a.sk_id_curr = pa.sk_id_curr
where pa.target is not null
group by 1,2
order by 1,2


select case when prev_app_tot_target_pred_avg is null then null
    else floor(prev_app_tot_target_pred_avg * 20) / 20
    end, case when prev_app_tot_target_pred_stddev > .075 then 1 else 0 end,
    case when a.ext_source_2 > .55 then 1 else 0 end,
    count(*), avg(pa.target)
from previous_application_aggregated pa inner join application a on a.sk_id_curr = pa.sk_id_curr
where pa.target is not null
group by 1,2,3 having count(*) > 200
order by 1,2,3


    pa.pa_apprv_pos_rate_down_payment_avg, pa.pa_apprv_pos_rate_down_payment_min, pa.pa_apprv_pos_rate_down_payment_max, pa.pa_apprv_pos_rate_down_payment_sd,

select least(floor(pa_apprv_pos_rate_down_payment_sd * 50) / 50, .2), count(*), avg(pa.target)
from previous_application_aggregated pa
where pa.target is not null
group by 1
order by 1



select * from previous_application_scored where sk_id_curr = 100077

select estimated_annual_interest_Rate from previous_application_scored where coalesce(estimated_annual_interest_Rate, 0) <> 0

select * from credit_card_balance where sk_id_curr = 245155 limit 500

select * from bureau limit 100

-273, 180000,71017.38,108982.62
select * from previous_application_scored where sk_id_curr = 215354

from previous_application_scored where sk_id_curr = 245155 limit 200

select floor(sellerplace_area_risk_avg), count(target), avg(target) from temp_app_list group by 1 order by 1;


select floor(sellerplace_area_risk_avg), count(*)
from
    previous_application_scored pa
group by 1 order by 1


select * from temp_app_list limit 100

select * from previous_application limit 1000

-- Overall, there are 307,511 scored apps (w target)
-- 16,454 out of these have no previous_application, or only 5-6%.
-- A few previous apps is good. A lot is bad.
select previous_application_count, count(target), count(case when target is not null then 1 end), avg(target)
from (
select
    a.sk_id_curr, a.target, count(pa.*) as previous_application_count
from
    application a
    left outer join previous_application pa
        on pa.sk_id_curr = a.sk_id_curr
group by 1,2
) a
group by 1 order by 1
;







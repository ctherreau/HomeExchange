{{ config(materialized='table')}}

WITH clean_subscriptions AS (SELECT * FROM {{ ref('stg_subscriptions') }} )

SELECT pk
    ,subscription_date
    ,user_id
    ,renew
    ,first_subscription_date
    ,first_subscription
    ,is_zombie
    ,previous_inscription as previous_inscription_date
    ,referral
    ,promotion
    ,payment3x
    ,payment2
    ,payment3
    ,country
    ,region
    ,department
    ,city
    ,inscription_diff_year
    ,nb_of_inscription_by_users
    --,inscription_diff_day
FROM clean_subscriptions
--WHERE user_id= 3655598
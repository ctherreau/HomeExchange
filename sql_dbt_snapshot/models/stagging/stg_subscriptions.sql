with add_pk as (
    SELECT  
    CONCAT(e.subscription_date, '_',e.user_id) as pk, *
    FROM `data.subscriptions` as e
) 
, clean_exchanges AS (SELECT * FROM {{ ref('stg_exchanges') }} )
, add_missing_country as (
    SELECT s.pk
    , s.subscription_date
    , s.user_id
    , s.renew
    , s.first_subscription_date
    , s.first_subscription
    , s.referral
    , s.promotion
    , s.payment3x
    , s.payment2
    , s.payment3
    , COALESCE(s.country, e.country) as country
    , COALESCE(s.region, e.region) as region
    , COALESCE(s.department, e.department) as department
    , COALESCE(s.city, e.city) as city
    FROM add_pk as s
    INNER JOIN clean_exchanges as e 
    ON s.user_id = e.host_user_id
)
, subscription_remove_duplicate  as
(
    SELECT DISTINCT *,
    ROW_NUMBER() OVER(PARTITION BY user_id, subscription_date) as k
    ,COUNT(DISTINCT pk) OVER(PARTITION BY user_id) as nb_of_inscription_by_users
    FROM add_missing_country
)
, subscription_remove_duplicate_action  as
(
    SELECT * from subscription_remove_duplicate
    WHERE  k<=1
)
, add_previous_date as (
  SELECT *
  , LAG(subscription_date) OVER(PARTITION BY user_id ORDER BY subscription_date) previous_inscription
  FROM subscription_remove_duplicate_action
  ORDER BY user_id
  )
,add_zombie_info  as (
  SELECT *
      ,DATE_DIFF(subscription_date, previous_inscription, YEAR) as inscription_diff_year
      --,DATE_DIFF(subscription_date, previous_inscription, DAY) as inscription_diff_day
  FROM add_previous_date
  )
SELECT 
  *, 
  CASE
    WHEN inscription_diff_year >=1.9 THEN 1
    ELSE 0
  END AS is_zombie
FROM add_zombie_info
WHERE nb_of_inscription_by_users <=3 
-- 3 years of annual subscription = more than 4 subscription in 3 years is strange
-- add info about user that come back after not renewing and delete inscription with two or more in the same year (which is strange for a annual subscription)
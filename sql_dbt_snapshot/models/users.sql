{{ config(materialized='table')}}

-- Find users infos in exchange tables, users can be either host or guest or both (reciprocal). 
-- In this case, two exchanges (two line in table) are created 
-- Need to separe nb of exchanges as host, as guest, as both (count only in one case for example here as user is host (if guest were chosen, same result)
WITH exchanges_host AS  
(SELECT 
    host_user_id as user_id
    , MIN(country) as country
    , SUM(CASE WHEN exchange_type = 'NON_RECIPROCAL' THEN 1 ElSE 0 END ) as nb_of_conversation_as_host --count the total number of conversation created were the user is host
    , SUM(CASE WHEN (finalized_at IS NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_conversation_as_host_notFinalized --count the total number of conversation that DID not become an exchange, were the user is host
    , SUM(CASE WHEN exchange_type = 'RECIPROCAL' THEN 1 ElSE 0 END ) as nb_of_conversation_for_exchange --count the total number of conversation created for reciprocal exchange (user is both guest and host)
    , SUM(CASE WHEN (finalized_at IS NULL AND exchange_type = 'RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_conversation_for_exchange_notFinalized --count the total number of conversation that DID NOT become an exchange for reciprocal exchange (user is both guest and host)
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_host_done --count the total number of conversation that DID become a exchange and was NOT cancel, were the user is host
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NOT NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_host_canceled --count the total number of conversation that DID become a exchange and was cancel, were the user is host
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NULL AND exchange_type = 'RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_exchange_done --count the total number of conversation that DID become an exchange and was NOT cancel for reciprocal exchange (user is both guest and host)
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NOT NULL AND exchange_type = 'RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_exchange_canceled --count the total number of conversation that DID become an exchange and was cancel for reciprocal exchange (user is both guest and host)
FROM {{ ref('exchanges') }} 
GROUP BY host_user_id
), 
exchanges_guest AS 
(SELECT 
    guest_user_id as user_id
    , SUM(CASE WHEN exchange_type = 'NON_RECIPROCAL' THEN 1 ElSE 0 END ) as nb_of_conversation_as_guest --count the total number of conversation created were the user is guest
    , SUM(CASE WHEN (finalized_at IS NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_conversation_as_guest_notFinalized --count the total number of conversation that DID not become an exchange, were the user is guest
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_guest_done --count the total number of conversation that DID become an exchange and WAS not cancel, were the user is host
    , SUM(CASE WHEN (finalized_at IS NOT NULL AND canceled_at IS NOT NULL AND exchange_type = 'NON_RECIPROCAL') THEN 1 ELSE 0 END) as nb_of_exchange_as_guest_canceled --count the total number of conversation that DID become an exchange and WAS cancel, were the user is host
FROM {{ ref('exchanges') }} 
GROUP BY guest_user_id
), 
exchanges_user as (
    SELECT *
    FROM exchanges_guest
    FULL OUTER JOIN exchanges_host using (user_id)
    ),
subscription AS
(SELECT 
    user_id
    ,min(first_subscription_date) as first_subscription_date
    ,max(subscription_date) as last_subscription_date
    ,avg(nb_of_inscription_by_users) as nb_of_inscription
    ,1-avg(renew) as mean_churn_rate --for the last two years, give the average churn rate for on user (for example, 3 subscription but only 2 renew, churn rate = 1 - 2/3 = 0.33)
    ,min(country) as country
    ,max(referral) as referall -- referall is 1 or 0, here want to know if the user were at least referall once
    ,max(promotion) as promotion -- promotion is 1 or 0, here want to know if the user used at least one promotion
FROM {{ ref('subscriptions')}}
GROUP BY user_id 
)

SELECT 
     COALESCE(s.user_id, e.user_id) as user_id
    ,s.first_subscription_date
    ,s.last_subscription_date
    ,s.nb_of_inscription
    ,s.mean_churn_rate
    ,s.referall
    ,s.promotion
    ,COALESCE(s.country, e.country) as country
    ,e.nb_of_conversation_as_host
    ,e.nb_of_conversation_as_host_notFinalized
    ,e.nb_of_exchange_as_host_done
    ,e.nb_of_exchange_as_host_canceled
    ,e.nb_of_conversation_as_guest
    ,e.nb_of_conversation_as_guest_notFinalized
    ,e.nb_of_exchange_as_guest_done
    ,e.nb_of_exchange_as_guest_canceled
    ,e.nb_of_conversation_for_exchange
    ,e.nb_of_conversation_for_exchange_notFinalized
    ,e.nb_of_exchange_as_exchange_done
    ,e.nb_of_exchange_as_exchange_canceled
FROM subscription as s
FULL OUTER JOIN exchanges_user as e using(user_id)
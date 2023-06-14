WITH exchanges_remove_duplicate  as
(
    SELECT DISTINCT *,
    ROW_NUMBER() OVER(PARTITION BY conversation_id, guest_user_id, host_user_id) as k
    FROM `data.exchanges`
)
,exchanges_remove_guestequalhost as 
( 
    SELECT *
    FROM exchanges_remove_duplicate
    WHERE host_user_id != guest_user_id
)
SELECT * FROM exchanges_remove_guestequalhost
WHERE k<=1
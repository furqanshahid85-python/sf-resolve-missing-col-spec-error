
create view user_payments_report as (

SELECT 
     u.country_code,
     COUNT(DISTINCT u.user_id) registered_users,
     COUNT(DISTINCT t.user_id) first_3_days_payment,
     (CAST(COUNT(DISTINCT t.user_id) AS REAL)  / count(DISTINCT u.user_id)) * 100 
FROM 
     Users u 
LEFT join (
            SELECT 
                u.user_id,
                u.joined_at joined_at,
                p.created_at created_at,
                Rank() OVER (partition by u.user_id ORDER BY p.created_at ASC) as payment_rank
            FROM
                Users u
                JOIN Payments p on u.user_id = p.user_id
                WHERE p.created_at >= u.joined_at
        )t
ON u.user_id = t.user_id 
AND t.created_at - t.joined_at  <= 3  
AND payment_rank = 1
GROUP BY
u.country_code
)

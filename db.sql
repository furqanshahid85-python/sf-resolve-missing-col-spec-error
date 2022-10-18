-- DDL for creating warehouse
CREATE OR REPLACE WAREHOUSE DEV_WAREHOUSE1 
WITH WAREHOUSE_SIZE ='XSMALL'
AUTO_SUSPEND        = 60
AUTO_RESUME         = TRUE
INITIALLY_SUSPENDED = TRUE
COMMENT = 'Warehouse for DEV purposes';

USE WAREHOUSE DEV_WAREHOUSE;




-- DDL for Database creation
CREATE DATABASE IF NOT EXISTS ANALYTICALDB;

USE DATABASE ANALYTICALDB;



-- DDL for schema
CREATE SCHEMA IF NOT EXISTS PUBLIC;
USE SCHEMA PUBLIC




-- DDL for tables
CREATE OR REPLACE TABLE ANALYTICALDB.PUBLIC.USERS (
	USER_ID NUMBER(38,0),
	JOINED_AT DATE,
	COUNTRY_CODE VARCHAR(16777216)
);

CREATE OR REPLACE TABLE ANALYTICALDB.PUBLIC.BOOKINGS (
	ID NUMBER(38,0),
	STARTTIME DATE,
	DURATION_HOURS NUMBER(38,0),
	USER_ID NUMBER(38,0),
	STATUS VARCHAR(16777216)
);

CREATE OR REPLACE TABLE ANALYTICALDB.PUBLIC.PAYMENTS (
	ID NUMBER(38,0),
	CREATED_AT DATE,
	PAYMENT_AMOUNT FLOAT,
	USER_ID NUMBER(38,0)
);



-- DDL for copying csv files

CREATE OR REPLACE STAGE USERS_STAGE;

CREATE OR REPLACE FILE FORMAT USERS_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',';

PUT file:///tmp/data/Users.csv @USERS_STAGE;


CREATE OR REPLACE STAGE BOOKINGS_STAGE;

CREATE OR REPLACE FILE FORMAT BOOKINGS_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',';

PUT file:///tmp/data/Bookings.csv @BOOKINGS_STAGE;


CREATE OR REPLACE STAGE PAYMENTS_STAGE;

CREATE OR REPLACE FILE FORMAT PAYMENTS_FORMAT TYPE = 'CSV' FIELD_DELIMITER = ',';

PUT file:///tmp/data/Payments.csv @PAYMENTS_STAGE;


COPY INTO ANALYTICALDB.PUBLIC.USERS FROM @USERS_STAGE;
COPY INTO ANALYTICALDB.PUBLIC.BOOKINGS FROM @BOOKINGS_STAGE;
COPY INTO ANALYTICALDB.PUBLIC.PAYMENTS FROM @PAYMENTS_STAGE;



-- DDL for view
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

DROP TABLE IF EXISTS ecommerce_raw;

//RAW table
CREATE TABLE ecommerce_raw (
    customer_id TEXT,
	purchase_date TEXT,
	product_category TEXT,
	product_price TEXT,
	quantity TEXT,
	total_purchase_amount TEXT,
	payment_method TEXT,
    customer_age TEXT,
	returned TEXT,
	customer_name TEXT,
	age TEXT,
    gender TEXT,
    churn TEXT
);

//Total records
select count(*) as total_rows from ecommerce_raw;

//Preview data
select * from ecommerce_raw limit 5;

//create new cleaned data table
drop table if exists ecommerce_clean;
create table  ecommerce_clean(
    customer_id int,
	purchase_date date,
	product_category TEXT,
	product_price numeric(10,2),
	quantity int,
	total_purchase_amount numeric(10,2),
	payment_method TEXT,
    customer_age int,
	returned boolean,
	customer_name TEXT,
	age int,
    gender TEXT,
    churn boolean
);

INSERT INTO ecommerce_clean (
    customer_id,
    purchase_date,
    product_category,
    product_price,
    quantity,
    total_purchase_amount,
    payment_method,
    customer_age,
    returned,
    customer_name,
    age,
    gender,
    churn
)
SELECT
    customer_id::INT,

    purchase_date::DATE,

    product_category,

    product_price::NUMERIC(10,2),

    quantity::INT,

    total_purchase_amount::NUMERIC(10,2),

    payment_method,

    NULLIF(customer_age, '')::INT,

    CASE
        WHEN returned IN ('1', 'Yes', 'yes', 'TRUE', 'true') THEN TRUE
        ELSE FALSE
    END AS returned,

    customer_name,

    NULLIF(age, '')::INT,

    CASE
        WHEN LOWER(gender) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(gender) IN ('f', 'female') THEN 'Female'
        ELSE 'Other'
    END AS gender,

    CASE
        WHEN churn IN ('1', 'Yes', 'yes', 'TRUE', 'true') THEN TRUE
        ELSE FALSE
    END AS churn

FROM ecommerce_raw
WHERE customer_id IS NOT NULL;

//Row count check
select count(*) from ecommerce_clean;

//Preview clean data
select * from ecommerce_clean limit 5;

//Gender standardization check
select distinct gender from ecommerce_clean;

//Returned values check
select distinct returned from ecommerce_clean;

//BASIC DATA QUALITY CHECKS
//Missing age
select count(*) from ecommerce_clean where age is null ;

//Negative price
select count(*) from ecommerce_clean where product_price < 0;



//ANALYSIS QUERIES

//1.overall return Rate

select 
  Round(
       100.0 * sum(case when returned then 1 else 0 end) / count(*),
	   2
  )as overall_return_rate
from ecommerce_clean;


//2.Churn Rate

select 
  Round(
       100.0 * sum(case when churn then 1 else 0 end) / count(*),
	   2
  )as churn_rate
from ecommerce_clean;


//3.Average Order Value

select
  round(avg(total_purchase_amount),2) as avg_order_value
from ecommerce_clean;


//4.Return Rate by Product Category

select 
  product_category,
  count(*) as total_orders,
  sum(case when returned then 1
      else 0
	  end) as returned_orders,
  ROUND(
    100.0 * sum(case when returned then 1 else 0 end) / count(*),
	2
       ) as  return_rate_percentage
from ecommerce_clean
group by product_category
order by return_rate_percentage DESC;


//5.Return Rate by Price Range

SELECT
    CASE
        WHEN product_price < 50 THEN 'Low Price'
        WHEN product_price BETWEEN 50 AND 100 THEN 'Mid Price'
        ELSE 'High Price'
    END AS price_segment,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN returned THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(
        100.0 * SUM(CASE WHEN returned THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS return_rate
FROM ecommerce_clean
GROUP BY price_segment
ORDER BY return_rate DESC;

//6.Top Returned Products

select product_category,
count(*) as return_count
from ecommerce_clean
where returned = true
group by product_category
order by return_count DESC;


//7.Customer Age Group vs Returns

select
 case
   when age < 25 then 'Below 25'
   when age between 25 and 35 then '25-35'
   when age between 36 and 50 then '36-50'
   else '50+'
 end as age_group,
 count(*) as total_orders,
 sum(case when returned then 1 else 0 end )as returns
from ecommerce_clean
group by age_group
ORDER BY returns DESC;


//8.Payment Method vs Returns

SELECT
    payment_method,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN returned THEN 1 ELSE 0 END) AS returned_orders
FROM ecommerce_clean
GROUP BY payment_method
ORDER BY returned_orders DESC;


//9.Churned Customers Analysis

select churn,
count(*) as customer_count
from ecommerce_clean
group by churn;


//10.Repeat Customers vs Churn

SELECT
    customer_id,
    COUNT(*) AS total_orders,
    MAX(churn::INT) AS churn_status
FROM ecommerce_clean
GROUP BY customer_id
HAVING COUNT(*) > 1;


//11.Gender vs Return Behavior

SELECT
    gender,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN returned THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(
        100.0 * SUM(CASE WHEN returned THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS return_rate
FROM ecommerce_clean
GROUP BY gender;



//12.REPEAT VS NON-REPEAT

SELECT
    CASE 
        WHEN order_count > 1 THEN 'Repeat Customer'
        ELSE 'One-Time Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    SUM(churn::INT) AS churned_customers,
    ROUND(
        100.0 * SUM(churn::INT) / COUNT(*),
        2
    ) AS churn_rate_percentage
FROM (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        MAX(churn::INT) AS churn
    FROM ecommerce_clean
    GROUP BY customer_id
) t
GROUP BY customer_type;


//13.Return Impact on Revenue

select
   round(sum(total_purchase_amount),2)as total_revenue,
   round(sum(case when returned then total_purchase_amount else 0 End),2)as revenue_lost_due_to_returns
from ecommerce_clean;


//14. Returns Trend Over Time (MONTHLY)

SELECT
    TO_CHAR(purchase_date, 'YYYY-MM') AS year_month,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN returned = TRUE THEN 1 ELSE 0 END) AS returned_orders
FROM ecommerce_clean
GROUP BY TO_CHAR(purchase_date, 'YYYY-MM')
ORDER BY year_month;





//new churn table

SELECT MAX(purchase_date) FROM ecommerce_clean;

WITH max_date AS (
    SELECT MAX(purchase_date) AS max_purchase_date
    FROM ecommerce_clean
)
SELECT
    e.customer_id,
    COUNT(*) AS total_orders,
    MAX(e.purchase_date) AS last_purchase_date,
    CASE
        WHEN MAX(e.purchase_date) < (SELECT max_purchase_date FROM max_date) - INTERVAL '90 days'
        THEN 1
        ELSE 0
    END AS churn
FROM ecommerce_clean e
GROUP BY e.customer_id;


/*
=============================================================================
Customer Report: Create a report based on customer data 
=============================================================================
*/
CREATE VIEW gold.report_customers AS
WITH base_query AS
( -- CTE - Base query: Retrieves core columns from tables
SELECT
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) customer_name,
	DATEDIFF(year, birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_id = c.customer_id
WHERE order_date IS NOT NULL
), customer_aggregations as
( -- CTE - Perform aggregations on customer data
SELECT
	customer_key,
	customer_number,
	customer_name,
	age,
	COUNT(DISTINCT order_number) orders,
	SUM(sales) sales,
	SUM(quantity) quantity,
	COUNT(DISTINCT product_key) products,
	MAX(order_date) last_order,
	DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan
FROM base_query
GROUP BY customer_key, customer_number, customer_name, age
)
-- Final query combines all results into one output
SELECT 
	customer_key,
	customer_number,
	customer_name,
	age,
	orders,
	sales,
	quantity,
	-- Average value of orders
	CASE WHEN sales = 0 THEN 0
		 ELSE sales / orders
	END AS average_order_value,
	-- Average monthly spending
	CASE WHEN lifespan < 1 THEN sales
		 ELSE sales / lifespan
	END AS average_monthly_spending,
	products,
	last_order,
	lifespan,
	CASE WHEN lifespan > 11 AND sales > 5000 THEN 'VIP'
		 WHEN lifespan > 11 AND sales < 5000 THEN 'REGULAR'
		 ELSE 'NEW'
	END account_type
FROM customer_aggregations

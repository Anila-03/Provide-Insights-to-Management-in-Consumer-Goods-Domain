Request 1
## Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region. 
SELECT 
	distinct(market)
FROM 
	dim_customer
WHERE customer = 'Atliq Exclusive' and region = 'APAC';

Request 2
## What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg 
WITH 
	cte_2020 as
		(SELECT count(distinct p.product_code) as unique_products_2020
			FROM dim_product p 
			JOIN fact_sales_monthly s 
			USING (product_code)
            WHERE fiscal_year = 2020
		),
	cte_2021 as
		(SELECT count(distinct p.product_code) as unique_products_2021
			FROM dim_product p
			JOIN fact_sales_monthly s
            USING (product_code)
            WHERE fiscal_year = 2021
		)
    SELECT   
			cte_2020.unique_products_2020,
			cte_2021.unique_products_2021,
			ROUND(((cte_2021.unique_products_2021 - cte_2020.unique_products_2020) * 100.0) / cte_2020.unique_products_2020, 2) AS percentage_chg
	FROM 
			cte_2020, cte_2021;
            
Request 3     
## Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts. The final output contains 2 fields, segment product_count 
SELECT segment, count(distinct product_code) as product_count from dim_product group by segment order by product_count desc;

Request 4
## Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment product_count_2020 product_count_2021 difference
WITH cte1 as
	(
		SELECT p.segment as A, count(distinct p.product_code) as C
		FROM dim_product p
		JOIN fact_sales_monthly s
        USING (product_code)
		WHERE fiscal_year = 2020
        GROUP BY p.segment
	),
    cte2 as 
    ( 
		SELECT p.segment as B, count(distinct p.product_code) as D
        FROM dim_product p
        JOIN fact_sales_monthly s
        USING (product_code)
        WHERE fiscal_year = 2021
        GROUP BY p.segment
	)
    SELECT 
			cte1.A as segment,
			cte1.C as product_count_2020,
			cte2.D as product_count_2021,
            (cte2.D - cte1.C) as difference
	FROM cte1,cte2
    WHERE cte1.A=cte2.B;
            
Request 5            
## Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, product, manufacturing_cost 
SELECT p.product_code, p.product, m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
USING (product_code)
WHERE manufacturing_cost in ((SELECT max(manufacturing_cost) from fact_manufacturing_cost), 
								(SELECT min(manufacturing_cost) from fact_manufacturing_cost))
ORDER BY manufacturing_cost Desc;

Request 6
## Generate a report which contains the top 5 customers who received an average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the Indian  market. The final output contains these fields, customer_code customer average_discount_percentage 
SELECT c.customer_code, c.customer, round(avg(pre_invoice_discount_pct),4) as average_discount_percentage 
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
USING (customer_code)
WHERE p.fiscal_year = 2021 and market = 'India'
GROUP BY c.customer_code, c.customer
ORDER BY average_discount_percentage desc
limit 5;

Request 7
## Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month  .  This analysis helps to  get an idea of low and high-performing months and take strategic decisions. 
The final report contains these columns: Month Year Gross sales Amount
SELECT concat(monthname(s.date),'(',year(s.date),')') as Month, s.fiscal_year, round(sum(g.gross_price * s.sold_quantity),2) as Gross_sales_Amount
FROM dim_customer c
JOIN fact_sales_monthly s ON c.customer_code = s.customer_code
JOIN fact_gross_price g ON g.product_code = s.product_code
WHERE customer = 'Atliq Exclusive'
GROUP BY Month, s.fiscal_year;

Request 8
## In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity 
select * from fact_sales_monthly;
WITH qtr_tab as 
	(
		SELECT date, month(date_add(date, interval 4 month)) as period, fiscal_year, sold_quantity
        FROM fact_sales_monthly 
	)
	SELECT 
		CASE 
			WHEN period/3 <= 1 then "Q1"
			WHEN period/3 <= 2 and period/3 > 1 then "Q2"
			WHEN period/3 <= 3 and period/3 > 2 then "Q3"
			WHEN period/3 <= 4 and period/3 > 3 then "Q4"
			END as qtr,
		 	sum(sold_quantity) as total_sold_quantity FROM qtr_tab
        WHERE fiscal_year = 2020
        GROUP BY qtr;

Request 9
## Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?  The final output  contains these fields, channel, gross_sales_mln, percentage 
SELECT c.channel, round(sum(g.gross_price*s.sold_quantity)/1000000,2) as gross_sales_mln
FROM dim_customer c
JOIN fact_sales_monthly s ON c.customer_code = s.customer_code
JOIN fact_gross_price g ON s.product_code = g.product_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
ORDER BY gross_sales_mln desc;

or 

with cte1 as
	(
		SELECT c.channel, sum(g.gross_price*s.sold_quantity) as gross_sales
		FROM dim_customer c
		JOIN fact_sales_monthly s ON c.customer_code = s.customer_code
		JOIN fact_gross_price g ON s.product_code = g.product_code
		WHERE s.fiscal_year = 2021
		GROUP BY c.channel
		ORDER BY gross_sales desc
	)
		SELECT channel, concat(round(gross_sales/1000000,2),' M') as gross_sales_mln, concat(round(gross_sales/(sum(gross_sales) over())*100,2),' %') as pct
        FROM cte1;

Request 10
## Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division, product_code, product, total_sold_quantity, rank_order 
with cte1 as 
	(
		SELECT division, p.product_code, concat(p.product," [",p.variant,"]") as product, sum(s.sold_quantity) as total_sold_quantity,
        rank() over(partition by division order by sum(sold_quantity) desc) as rank_order
		FROM dim_product p
		JOIN fact_sales_monthly s ON p.product_code = s.product_code
		WHERE fiscal_year = 2021
        GROUP BY p.product_code
	)
SELECT * FROM cte1 WHERE rank_order IN (1,2,3);



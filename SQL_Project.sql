/* 
ATLIQ HARDWARE'S MANAGEMENT WANTS TO GET SOME INSIGHTS IN THE SALES OF ITS PRODUCTS. 
AS A DATA ANALYST MY TASK IS TO RESPOND TO 10 AD-HOC QUERIES ASSIGNED TO ME. 
*/

SELECT distinct customer
from dim_customer;

-- 1. List of markets in which customer "Atliq Exlcusive" operates business in the APAC region
SELECT distinct market FROM dim_customer
where region = "APAC" and customer="Atliq Exclusive";

-- 2. What is the percentage of unique product increase in 2021 vs 2020?

select 
    A.total_product as unique_product_2020,
    B.total_product as unique_product_2021,
    round((B.total_product - A.total_product) * 100.0 / A.total_product, 2) as percentage_chg
from 
    (select count(distinct(product_code)) as total_product 
     from fact_sales_monthly 
     where fiscal_year = 2020) A,
    (select count(distinct(product_code)) as total_product 
     from fact_sales_monthly 
     where fiscal_year = 2021) B;
     
-- 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains

SELECT segment, count(distinct(product_code) ) as Product_Count
FROM dim_product
group by segment
order by Product_Count desc

-- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
WITH cte1 AS (
    SELECT  
        P.segment, 
        COUNT(DISTINCT S.product_code) AS product_count_2020
    FROM fact_sales_monthly S
    JOIN dim_product P ON S.product_code = P.product_code
    WHERE fiscal_year = 2020
    GROUP BY P.segment
),
cte2 AS (
    SELECT  
        P.segment, 
        COUNT(DISTINCT S.product_code) AS product_count_2021
    FROM fact_sales_monthly S
    JOIN dim_product P ON S.product_code = P.product_code
    WHERE fiscal_year = 2021
    GROUP BY P.segment
)
SELECT 
    cte1.segment, 
    cte1.product_count_2020, 
    cte2.product_count_2021,
    cte2.product_count_2021-cte1.product_count_2020 as difference
FROM 
    cte1
JOIN 
    cte2 
ON 
    cte1.segment = cte2.segment;

-- 5. Get the products that have the highest and lowest manufacturing costs.
SELECT m.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost m
join dim_product p
on m.product_code=p.product_code
where m.manufacturing_cost =( select max(manufacturing_cost) from fact_manufacturing_cost)
union
SELECT m.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost m
join dim_product p
on m.product_code=p.product_code
where m.manufacturing_cost =(select min(manufacturing_cost) from fact_manufacturing_cost)

-- 6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 

SELECT p.customer_code, c.customer, round(AVG(p.pre_invoice_discount_pct),4) AS average_discount_percentage
FROM fact_pre_invoice_deductions p
join dim_customer c
on p.customer_code=c.customer_code
where market="India" and fiscal_year = 2021
group by p.customer_code, c.customer
order by average_discount_percentage desc
limit 5	

-- 7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions.


with cte as(
SELECT 
 monthname(s.date) as Months,
 year(s.date) as years,
 s.sold_quantity*g.gross_price as total_gross_price,
 s.fiscal_year
FROM fact_sales_monthly s
join fact_gross_price g 
on s.product_code=g.product_code
and s.fiscal_year = g.fiscal_year
join dim_customer c
on s.customer_code=c.customer_code
where c.customer = "Atliq Exclusive")

select Months,years,
 concat(round(sum(total_gross_price)/1000000,1),'Milion')as Gross_sales_Amount from cte
group by Months,years
order by Gross_sales_Amount desc


-- 8. In which quarter of 2020, got the maximum total_sold_quantity?

SELECT 
case 
     when month(date) between 9 and 11 then'Q1' 
     when month(date) in( 12 ,1 ,2) then'Q2'
     when month(date) between 3 and 5 then 'Q3'
     when month(date) between 6 and 8 then 'Q4'
	end as Quarters,
    concat(round(sum(sold_quantity)/1000000,2), ' Milions') as total_sold_quantity
 FROM fact_sales_monthly
where fiscal_year = 2020
group by quarters

-- 9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

with cte as (
SELECT 
channel,
 round(sum((sold_quantity*gross_price)/1000000),2) as gross_sales_mln
 FROM fact_sales_monthly s
 join fact_gross_price g
 on s.product_code =g.product_code
 and s.fiscal_year = g.fiscal_year
 join dim_customer c
 on s.customer_code=c.customer_code
 where s.fiscal_year=2021
 group by channel)
 select * ,
 round(gross_sales_mln/(select sum(gross_sales_mln) from cte)*100,2) as percentage
 from cte
 
 -- 10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
with cte as(
SELECT division,
s.product_code,
product,
sum(sold_quantity) as total_sold_quantity,
dense_rank() over(partition by  division order by sum(sold_quantity) desc) as rnk
FROM fact_sales_monthly s
join dim_product p
on s.product_code=p.product_code
where fiscal_year = 2021
group by division,s.product_code,product)

select * from cte
where rnk <=3



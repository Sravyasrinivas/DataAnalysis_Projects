-- using the table df_orders after cleaning:

--Find top 10 highest revnue generating products:

select top 10 sum(sale_price) as revenue,product_id
from df_orders
group by product_id
order by 1 desc,2

-- Find top 10 highest selling products in each region 
with cte as (
select 
sum(sale_price) as revenue,product_id,region
from df_orders
group by product_id,region
--order by 3,1 desc
)select * from (
select *, ROW_NUMBER() over (partition by region order by revenue desc) as rn
from cte)t where rn <=5

-- find month over month growth comparison for 2022 and 2023 sales (eg : jan 2022 vs jan 2023)

with cte as(select year(order_date) as order_year,month(order_Date) as order_month,
sum(sale_price) as revenue from df_orders
group by year(order_date),month(order_date)
)
select (sum(sales2023-sales2022))/sum(sales2023) * 100.0 as growth,order_month from ( 
select order_year,order_month,
case when order_year = 2022 then revenue else 0 end as sales2022,
case when order_year = 2023 then revenue else 0 end  as sales2023
from cte
--where order_month =1
)t
group by order_month 
order by order_month


--for each category which month has highest sales:

select category,sales,month from (
select *,rank() over(partition by category order by sales desc) as rn from(
select sum(sale_price) as sales,
format(order_date,'yyyyMM') as month,category from df_orders
group by category,format(order_date,'yyyyMM'))t)cte2
where rn = 1

--which sub_category had the highest growth by profit in 2023 compared to 2022

with cte as(select year(order_date) as order_year,sub_category,
sum(sale_price) as revenue from df_orders
group by year(order_date),sub_category
) select top 1 sub_category,sales2022,sales2023,(sales2023-sales2022)/sales2022 * 100 from (
select sub_category,
sum(case when order_year = 2022 then revenue else 0 end) as sales2022,
sum(case when order_year = 2023 then revenue else 0 end ) as sales2023
from cte
group by sub_category)t
order by 4 desc
--where order_month =1

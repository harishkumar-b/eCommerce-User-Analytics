--Create Database E_Retail_Analysis;
--Use E_Retail_Analysis
select * from login_logs;
select * from sales_orders;
select * from sales_orders_items;

---1. Make a dataset (Using SQL) named “daily_logins” which contains the number of logins on a daily basis.
	--SELECT * INTO daily_logins FROM (Select cast(login_time as date) as 'Date', count(login_log_id) as total_logins from login_logs 
	--group by cast(login_time as date))Q;

---2. Daily trend of logins and trend of conversion rate (Number of orders placed per login)

--Daily trend of logins
	Select * from daily_logins order by Date;

--Daily trend of conversion rate
	--Create View daily_orders as
	--select cast(creation_time as date) as Date, count(distinct order_id) as Number_of_Orders 
	--from sales_orders group by cast(creation_time as date);

	--Create View Login_order_conversion as 
	--	Select l.Date, Number_of_Orders*100.0/total_logins as 'login_order_conversion%'
	--	from daily_logins as l join daily_orders as o on l.Date=o.Date;

	select * from login_order_conversion order by Date;

---3. Which KPIs would you use to measure the performance of our app?
	-- Logins to Order Conversion Rate
		Select year(Date) as Year, avg([login_order_conversion%]) as Logins_to_Orders_Rate from login_order_conversion 
		group by year(Date) order by Year;

	-- Daily Active Users
		--CREATE VIEW Daily_Active_Users as 
		--Select cast(login_time as date) as 'Date', count(distinct user_id) as daily_active_users from login_logs 
		--group by cast(login_time as date);
		--select * from Daily_Active_Users order by Date;
		--Select year(Date) as Year, avg(daily_active_users) as average_DAU from Daily_Active_Users 
		--group by year(Date) order by Year;

	-- Monthly Active Users
		--CREATE VIEW Monthly_Active_Users as 
		--Select month(cast(login_time as date)) as 'Month', 
		--year(cast(login_time as date)) as 'Year', 
		--count(distinct user_id) as monthly_active_users from login_logs 
		--group by month(cast(login_time as date)),year(cast(login_time as date));
		
		--Select Year, avg(monthly_active_users) as Avg_MAU from Monthly_Active_Users 
		--group by Year order by Year;

	--Avg MAU & Avg DAU in both the Years.
		With Q1 as(Select year(Date) as Year, avg(daily_active_users) as average_DAU from Daily_Active_Users 
		group by year(Date)),
		Q2 as (Select Year, avg(monthly_active_users) as average_MAU from Monthly_Active_Users 
		group by Year)
		select a.Year, average_DAU, average_MAU  from Q1 a join Q2 b on a.Year=b.Year order by Year;

	--Stickiness
		With Average_DAU as(
		Select month(Date) as Month, year(Date) as Year, avg(daily_active_users) as Avg_DAU
		from Daily_Active_Users group by month(Date), year(Date))
		--select * from Average_DAU;
		select m.Year, Avg_DAU*100.0/monthly_active_users as Stickiness_Ratio from Average_DAU as d join Monthly_Active_Users as m
		on d.Month=m.Month and d.Year=m.Year order by m.Year;
		--Stickiness standard rate in Industry is 10-20%.
		--20% stickiness is good, while anything above 25% is exceptional.

	--User growth rate:
		With CTE as (
		select year(login_time) as Year,count(distinct user_id) as No_of_Users from login_logs group by year(login_time))
		Select ((select No_of_Users from CTE where Year=2022)-(select No_of_Users from CTE where Year=2021))*100.0/(select No_of_Users from CTE where Year=2021)
		as 'User Growth Rate';
	
	-- Average Order Value(AOV)
		-- Total revenue / number of orders
		With actual_sales as(
		select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id 
		where sales_order_status='Shipped' and order_quantity_accepted>0)
		select Year(creation_time) as Year, sum(order_quantity_accepted*rate)/count(distinct order_id) as AOV from actual_sales
		group by Year(creation_time);
		
	-- Average Revenue Per User(ARPU)
		With actual_sales as(
		select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id 
		where sales_order_status='Shipped' and order_quantity_accepted>0)
		select Year(creation_time) as Year, sum(order_quantity_accepted*rate)/count(distinct fk_buyer_id) as ARPU from actual_sales
		group by Year(creation_time);


---4. Prepare a report regarding our growth between the 2 years. Please try to answer the following questions:
    --1. Did our business grow?
        -- Revenue difference answers.
		With actual_sales as(
		select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id 
		where sales_order_status='Shipped' and order_quantity_accepted>0)
		select Year(creation_time) as Year, sum(order_quantity_accepted*rate) as GMV from actual_sales
		group by Year(creation_time);
    --2. Does our app perform better now?
        -- No_of_Logins difference
			Select year(login_time) as Year,count(distinct login_log_id) as No_of_Logins from login_logs 
			group by year(login_time) order by Year;
        -- No_of_Orders difference
			Select year(creation_time) as Year,count(distinct order_id) as No_of_Order from sales_orders 
			group by year(creation_time) order by Year;

    --3. Did our user base grow?
        -- user_id differences
		Select year(login_time) as Year,count(distinct user_id) as No_of_Users from login_logs 
		group by year(login_time) order by Year;

---5.What are our top-selling products in each of the two years? 
--Can you draw some insight from this?
	With actual_sales as(
		select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id 
		where sales_order_status='Shipped' and order_quantity_accepted>0)
	Select top 5 fk_product_id, sum(ordered_quantity) as Order_Volume, avg(rate) as avg_sell_price from actual_sales 
	where year(creation_time)= 2021 group by fk_product_id order by Order_Volume desc;
	
	With actual_sales as(
		select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id 
		where sales_order_status='Shipped' and order_quantity_accepted>0)
	Select top 5 fk_product_id, sum(ordered_quantity) as Order_Volume, avg(rate) as avg_sell_price from actual_sales 
	where year(creation_time)= 2022 group by fk_product_id order by Order_Volume desc;

---6.Looking at July 2021 data, what do you think is our biggest problem
--and how would you recommend fixing it?
	select sales_order_status, Year(creation_time) as Year, count(distinct order_id) as Number_of_Orders 
	from sales_orders group by sales_order_status, Year(creation_time) order by Year;

	--Create View Q6 as select * from sales_orders as s join sales_orders_items as o on s.order_id=o.fk_order_id;

	select top 3 fk_depot_id, Year(creation_time) as Year, count(distinct order_id) as Number_of_Orders from Q6 
	where sales_order_status = 'Rejected' group by fk_depot_id, Year(creation_time) order by Year, Number_of_Orders desc;
	
	select top 3 fk_depot_id, Year(creation_time) as Year, count(distinct order_id) as Number_of_Orders from Q6 
	where sales_order_status = 'Rejected' group by fk_depot_id, Year(creation_time) order by Year desc, Number_of_Orders desc;

	select top 5 fk_product_id, Year(creation_time) as Year, count(distinct order_id) as Number_of_Orders from Q6 
	where sales_order_status = 'Rejected' group by fk_product_id, Year(creation_time) order by Year, Number_of_Orders desc;

	select top 5 fk_product_id, Year(creation_time) as Year, count(distinct order_id) as Number_of_Orders from Q6 
	where sales_order_status = 'Rejected' group by fk_product_id, Year(creation_time) order by Year, Number_of_Orders desc;

---7.Does the login frequency affect the number of orders made?
	With Logins as (
	select * from daily_logins),
	Orders as (
	select * from daily_orders)
	Select l.Date, total_logins as Number_of_Logins, Number_of_Orders 
	from Logins as l join Orders as o on l.Date=o.Date
	order by l.Date;

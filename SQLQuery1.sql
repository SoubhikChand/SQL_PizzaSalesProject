select * from pizza_price

--//Top 10 pizzas based on sales//-- 

SELECT TOP 10 p1.name, SUM(p1.sales) as total_sales
FROM (
    SELECT c.name, b.size, (COUNT(a.pizza_id) * a.quantity * b.price) as sales
    FROM order_details a
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
	join pizza_types c ON c.pizza_type_id = b.pizza_type_id
    GROUP BY c.name, b.size, a.quantity, b.price
) p1
GROUP BY p1.name
ORDER BY total_sales DESC;


--//Top 5 Most ordered pizza//--

select c.name, count(a.pizza_id) most_ordered
from order_details a
join pizza_price b on a.pizza_id = b.pizza_id
join pizza_types c on c.pizza_type_id = b.pizza_type_id
group by c.name
order by most_ordered desc 
offset 0 rows
fetch next 5 rows only;

--//Which pizzas are ordered most and generated more sales in each size?//--

----for size 'L'--
SELECT Top 5 p1.name , SUM(p1.sales) as total_sales
FROM (
    SELECT c.name, b.size, (COUNT(a.pizza_id) * a.quantity * b.price) as sales
    FROM order_details a
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
	join pizza_types c on c.pizza_type_id = b.pizza_type_id
    GROUP BY c.name, b.size, a.quantity, b.price
) p1
WHERE p1.size='L'
GROUP BY p1.name
ORDER BY total_sales desc;

----for size 'S'--
SELECT Top 5 p1.name , SUM(p1.sales) as total_sales
FROM (
    SELECT c.name, b.size, (COUNT(a.pizza_id) * a.quantity * b.price) as sales
    FROM order_details a
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
	join pizza_types c on c.pizza_type_id = b.pizza_type_id
    GROUP BY c.name, b.size, a.quantity, b.price
) p1
WHERE p1.size='S'
GROUP BY p1.name
ORDER BY total_sales desc;

----for size 'M'--
SELECT Top 5 p1.name , SUM(p1.sales) as total_sales
FROM (
    SELECT c.name, b.size, (COUNT(a.pizza_id) * a.quantity * b.price) as sales
    FROM order_details a
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
	join pizza_types c on c.pizza_type_id = b.pizza_type_id
    GROUP BY c.name, b.size, a.quantity, b.price
) p1
WHERE p1.size='M'
GROUP BY p1.name
ORDER BY total_sales desc;

----//Month wise sales//----

SELECT
    CASE unique_month
        WHEN 1 THEN 'Jan'
        WHEN 2 THEN 'Feb'
        WHEN 3 THEN 'Mar'
        WHEN 4 THEN 'Apr'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'Jun'
        WHEN 7 THEN 'Jul'
        WHEN 8 THEN 'Aug'
        WHEN 9 THEN 'Sep'
        WHEN 10 THEN 'Oct'
        WHEN 11 THEN 'Nov'
        WHEN 12 THEN 'Dec'
    END AS month_order, 
    SUM(sales) AS total_sales
FROM
    (SELECT DISTINCT MONTH(c.date) unique_month, (COUNT(a.pizza_id) * a.quantity * b.price) AS sales
     FROM order_details a
     JOIN orders c ON c.order_id = a.order_id
     JOIN pizza_price b ON a.pizza_id = b.pizza_id
     GROUP BY b.size, a.quantity, b.price, c.date) p2
GROUP BY unique_month
ORDER BY unique_month;


----//Weekday wise average orders value//----

select unique_day, avg(sales) average_sales
from
(SELECT distinct datename(WEEKDAY,c.date) unique_day, (COUNT(a.pizza_id) * a.quantity * b.price) as sales
    FROM order_details a
	join orders c on c.order_id=a.order_id
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
    GROUP BY datename(WEEKDAY,c.date),b.size, a.quantity, b.price) p1
	group by unique_day;


------- #Orderby Weekday sequence 
WITH WeekdaySales AS (
    SELECT DISTINCT
        DATENAME(WEEKDAY, c.date) AS week_day,
        (COUNT(a.pizza_id) * a.quantity * b.price) AS sales
    FROM
        order_details a
        JOIN orders c ON c.order_id = a.order_id
        JOIN pizza_price b ON a.pizza_id = b.pizza_id
    GROUP BY
        DATENAME(WEEKDAY, c.date), a.quantity, b.price
)

SELECT
    CASE week_day
        WHEN 'Sunday' THEN 1
        WHEN 'Monday' THEN 2
        WHEN 'Tuesday' THEN 3
        WHEN 'Wednesday' THEN 4
        WHEN 'Thursday' THEN 5
        WHEN 'Friday' THEN 6
        WHEN 'Saturday' THEN 7
    END AS day_order,
    week_day,
    AVG(sales) AS average_sales
FROM
    WeekdaySales
GROUP BY
    week_day
ORDER BY
    day_order;


-----//Time wise sales//----

WITH timesales AS (
    SELECT DISTINCT 
        DATEPART(HOUR, c.time) AS stime,
        (COUNT(a.pizza_id) * a.quantity * b.price) AS sales
    FROM
        order_details a
        JOIN orders c ON c.order_id = a.order_id
        JOIN pizza_price b ON a.pizza_id = b.pizza_id
    GROUP BY
        DATEPART(HOUR, c.time), a.pizza_id, a.quantity, b.price
)

SELECT
    CASE
        WHEN stime > 12 THEN CAST(stime - 12 AS VARCHAR) + ' PM'
        WHEN stime = 12 THEN '12 PM'
        ELSE CAST(stime AS VARCHAR) + ' AM'
    END AS formatted_time,
    AVG(sales) AS average_sales
FROM
    timesales
GROUP BY
    stime
ORDER BY
    min(stime);


-----//Category wise total sales with percentage of total_sales//------

WITH CategoryWiseSales AS (
SELECT DISTINCT 
        d.category AS unique_category,
        (COUNT(a.pizza_id) * a.quantity * b.price) AS sales
    FROM
        order_details a
        JOIN orders c ON c.order_id = a.order_id
        JOIN pizza_price b ON a.pizza_id = b.pizza_id
		JOIN pizza_types d ON d.pizza_type_id = b.pizza_type_id
	GROUP BY d.category, a.pizza_id, a.quantity, b.price
	)

SELECT unique_category, 
       SUM(sales) total_sales,
       (SUM(sales) / SUM(SUM(sales)) OVER ()) * 100 AS percentage_of_total_sales
       FROM CategoryWiseSales
	GROUP BY unique_category
	ORDER BY total_sales DESC;


------//Average order value//------

SELECT ROUND(AVG(total_order_value), 2) AS average_order_value
FROM (
    SELECT c.order_id, SUM(a.quantity * b.price) AS total_order_value
    FROM order_details a
    JOIN orders c ON c.order_id = a.order_id
    JOIN pizza_price b ON a.pizza_id = b.pizza_id
    GROUP BY c.order_id
) AS order_values;

-----//Total Revenue//----

SELECT SUM(a.quantity * b.price) AS total_revenue
FROM order_details a
JOIN orders c ON c.order_id = a.order_id
JOIN pizza_price b ON a.pizza_id = b.pizza_id;

------//Weekday how many orders//------count order

WITH WeekdayOrders AS (
    SELECT DISTINCT
        DATENAME(WEEKDAY, a.date) AS week_day,
        COUNT(a.order_id) AS orders_count
    FROM
        orders a
         
    GROUP BY
        DATENAME(WEEKDAY, a.date)
)

SELECT
    CASE week_day
        WHEN 'Sunday' THEN 1
        WHEN 'Monday' THEN 2
        WHEN 'Tuesday' THEN 3
        WHEN 'Wednesday' THEN 4
        WHEN 'Thursday' THEN 5
        WHEN 'Friday' THEN 6
        WHEN 'Saturday' THEN 7
    END AS day_order,
    week_day,
    SUM(orders_count) AS total_orders_count
FROM
    WeekdayOrders
GROUP BY
    week_day
ORDER BY
    day_order;

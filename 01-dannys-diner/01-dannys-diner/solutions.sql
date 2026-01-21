-- Danny's Diner — Solutions (MySQL)
-- Author: Saisushmitha Reddy
-- Database: dannys_diner

/* --------------------------------------------------
   Q1. What is the total amount each customer spent at the restaurant
-------------------------------------------------- */  
  select s.customer_id, sum(m.price) as amount
  from sales as s
  join menu m on s.product_id = m.product_id group by s.customer_id;

/* --------------------------------------------------
   Q #2. How many days has each customer visited the restaurant?
-------------------------------------------------- */  

select customer_id, count( distinct order_date) as days_visited
  from sales
group by customer_id;

/* --------------------------------------------------
   Q#3. How many total items has each customer purchased?
-------------------------------------------------- */  

  select customer_id, count(product_id) as total_items
  from sales
group by customer_id;


/* --------------------------------------------------
   Q3. What was the first item from the menu purchased by each customer?
-------------------------------------------------- */  
select customer_id, product_name
	from (select s.customer_id, s.order_date, m.product_name,
			dense_rank() over(partition by customer_id 
								order by order_date asc) as item_rank
    from sales as s join menu m on s.product_id = m.product_id) as first_item 
    where item_rank=1 
    group by customer_id, product_name;


/* --------------------------------------------------
   Q#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-------------------------------------------------- */  

Select m.product_name, count(s.product_id) as times_Ordered
	from sales as s 
    join menu as m on s.product_id = m.product_id
    group by product_name
    order by count(s.product_id) desc limit 1;


/* --------------------------------------------------
   Q#5.Which item was the most popular for each customer?
-------------------------------------------------- */  

-- using window functions
SELECT customer_id, product_name, cnt AS times_ordered
FROM (
  SELECT s.customer_id, m.product_name, COUNT(*) AS cnt,
    DENSE_RANK() OVER ( PARTITION BY s.customer_id
						ORDER BY COUNT(*) DESC) AS rnk
  FROM sales s JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
) ranked
WHERE rnk = 1 ORDER BY customer_id, product_name;
    
-- without window functions
SELECT
  t.customer_id,
  t.product_name,
  t.cnt AS times_ordered
FROM (
  SELECT
    s.customer_id,
    m.product_name,
    COUNT(*) AS cnt
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
) t
JOIN (
  SELECT
    customer_id,
    MAX(cnt) AS max_cnt
  FROM (
    SELECT
      s.customer_id,
      m.product_name,
      COUNT(*) AS cnt
    FROM sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
  ) x
  GROUP BY customer_id
) mx
  ON t.customer_id = mx.customer_id
 AND t.cnt = mx.max_cnt
ORDER BY t.customer_id, t.product_name;


/* --------------------------------------------------
   Q#6. Which item was purchased first by the customer after they became a member?
-------------------------------------------------- */  

Select * from ( Select  m.customer_id, s.order_date, me.product_name, 
	dense_rank() over( partition by m.customer_id
						order by s.order_date) as rnk
	from members as m join sales as s on m.customer_id = s.customer_id 
	join menu as me on s.product_id = me.product_id 
    where s.order_date>= m.join_date) ranked
	where rnk =1
    order by customer_id, product_name;


/* --------------------------------------------------
   Q#7. Which item was purchased just before the customer became a member?
-------------------------------------------------- */  

Select * from ( Select  m.customer_id, s.order_date, me.product_name, 
	dense_rank() over( partition by m.customer_id
						order by s.order_date desc) as rnk
	from members as m join sales as s on m.customer_id = s.customer_id 
	join menu as me on s.product_id = me.product_id 
    WHERE m.join_date > s.order_date)  ranked
	where rnk =1
    order by customer_id, product_name;


/* --------------------------------------------------
   Q#8. What is the total items and amount spent for each member before they became a member?
-------------------------------------------------- */  

SELECT m.customer_id, COUNT(*) AS total_items, SUM(me.price) AS total_amount
	FROM members m JOIN sales s ON m.customer_id = s.customer_id
	JOIN menu me ON s.product_id = me.product_id
	WHERE m.join_date > s.order_date
	GROUP BY m.customer_id
    ORDER BY m.customer_id;


/* --------------------------------------------------
   Q#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-------------------------------------------------- */  

Select s.customer_id, 
	SUM(
		case 
			when Product_name = 'sushi' then m.price*20
            Else m.price*10
		End) as points
	from menu m join sales s on m.product_id = s.product_id group by s.customer_id;

/* --------------------------------------------------
   Q#10. In the first week after a customer joins the program (including their join date) they earn 2x points
on all items, not just sushi - how many points do customer A and B have at the end of January
-------------------------------------------------- */  
?
Select s.customer_id,
	SUM(
		case
        when s.order_date >= mem.join_date
        and  s.order_date <= DATE_ADD(mem.join_date, INTERVAL 6 DAY)
        then m.price*20
		
         WHEN m.product_name = 'sushi'
        THEN m.price * 20
        
        ELSE m.price * 10
    END
  ) AS points
from sales s join members mem on s.customer_id = mem.customer_id
join menu m on s.product_id = m.product_id
where s.order_date <='2021-01-31'
AND s.customer_id IN ('A','B')
GROUP BY s.customer_id
ORDER BY s.customer_id;


/* --------------------------------------------------
   Q#11. Total items purchased by each customer
-------------------------------------------------- */  

Select customer_id, count(product_id) as items
	from sales group by customer_id;

/* --------------------------------------------------
   Q#12. Total amount spent by each customer on curry only
-------------------------------------------------- */  

Select s.customer_id, sum(m.price) as amount
    from menu m join sales s on m.product_id = s.product_id
    where m.product_name = 'curry' group by customer_id;


/* --------------------------------------------------
   Q#13. Total amount spent by each customer after 2021-01-07
-------------------------------------------------- */  

Select s.customer_id, sum(m.price)  as amount
    from menu m join sales s on m.product_id = s.product_id 
    where order_date >='2021-01-07' 
    group by s.customer_id
    order by s.customer_id;

/* --------------------------------------------------
   Q#14. Average spend per visit for each customer
-------------------------------------------------- */  

Select customer_id, avg(daily_spend) from
	(select s.customer_id, s.order_date, sum(m.price) as daily_spend
	from sales s join menu m on s.product_id = m.product_id
    group by s.customer_id, s.order_date) visits
group by customer_id
order by customer_id;

/* --------------------------------------------------
   Q#15. Total revenue generated per day
-------------------------------------------------- */  

SELECT s.order_date, SUM(m.price) AS revenue
	FROM sales s JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.order_date
	ORDER BY s.order_date;

/* --------------------------------------------------
   Q#16. Total revenue generated per product
-------------------------------------------------- */  

SELECT m.product_name, SUM(m.price) AS revenue
	FROM sales s JOIN menu m ON s.product_id = m.product_id
	GROUP BY m.product_name
	ORDER BY product_name;

/* --------------------------------------------------
   Q#17. Percentage contribution of each customer to total revenue
-------------------------------------------------- */  

SELECT s.customer_id, SUM(m.price) AS revenue,
	Round((Sum(m.price) * 100.0 / Sum(sum(m.price)) over()),2) as prcnt_contri
	FROM sales s JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id
	ORDER BY s.customer_id;
    
#or 
Select customer_id, round(prcnt_contri,2) as percentage 
from (SELECT s.customer_id, SUM(m.price) AS revenue,
	(Sum(m.price) * 100.0 / Sum(sum(m.price)) over()) as prcnt_contri
	FROM sales s JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id) temp
	ORDER BY customer_id;

/* --------------------------------------------------
   Q#18. Highest single-day spend by any customer
-------------------------------------------------- */  

Select s.customer_id, s.order_date, sum(m.price) as spend
	FROM sales s JOIN menu m ON s.product_id = m.product_id 
	group by s.order_date, s.customer_id
    order by spend desc limit 1;

/* --------------------------------------------------
   Q#19. Rank customers by total spend (highest spender = rank 1)
-------------------------------------------------- */  

SELECT customer_id, total_spend,
  DENSE_RANK() OVER (ORDER BY total_spend DESC) AS spend_rank
FROM ( SELECT s.customer_id, SUM(m.price) AS total_spend
  FROM sales s JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id) t
ORDER BY spend_rank, customer_id;

/* --------------------------------------------------
   Q#20. Rank each customer’s purchases by date (earliest → latest)
-------------------------------------------------- */  

 Select customer_id, order_date, purchases, 
	row_number() over( partition by customer_id 
						order by order_date asc) as rnk
	from (Select customer_id, order_date, count(*) as purchases
	FROM sales
    group by customer_id, order_date)daily_sales
    ORDER BY customer_id, order_date;
    #here row_number & dense_rank() will perform same since there are no ties within a customer.


      /* --------------------------------------------------
   Q#21. For each product, rank customers by how much they spent on that product
-------------------------------------------------- */  

 select customer_id, product_name, total_spent,
	dense_rank() over(partition by product_name
						order by total_spent desc) as rnk
	from (Select product_name , customer_id, sum(price) as total_spent
FROM sales s JOIN menu m ON s.product_id = m.product_id
group by m.product_name, s.customer_id) as dt
ORDER BY product_name, rnk, customer_id;

/* --------------------------------------------------
   Q#22. Top 2 most purchased items overall (include ties)
-------------------------------------------------- */  

Select product_name, purchases
from ( Select m.product_name, count(*) as purchases,
	dense_rank() over(order by COUNT(*) DESC) as rnk
	from sales s JOIN menu m ON s.product_id = m.product_id
group by product_name ) as purchase_sales
where rnk<=2
order by purchases desc, product_name;

/* --------------------------------------------------
   Q#23. Number of days between a customer’s first and last purchaset
-------------------------------------------------- */  

Select customer_id, datediff(last_purchase, first_purchase) as difference
from ( select customer_id, min(order_date) as first_purchase, Max(order_date) as last_purchase
	from sales group by customer_id) temp
	order by customer_id;

/* --------------------------------------------------
   Q#24. First purchase date after becoming a member for each customer
-------------------------------------------------- */  

select * from (select s.customer_id, s.order_date,
	dense_rank() over(partition by m.customer_id
						order by s.order_date) as rnk
	from members m join sales s on m.customer_id = s.customer_id
    where s.order_date >= m.join_date) ranked
    where rnk=1;

/* --------------------------------------------------
   Q#25. Customers who made no purchase in the first 7 days after joining
-------------------------------------------------- */  
SELECT m.customer_id
	FROM members m LEFT JOIN sales s ON s.customer_id = m.customer_id
 AND s.order_date >= m.join_date
 AND s.order_date <= DATE_ADD(m.join_date, INTERVAL 6 DAY)
WHERE s.customer_id IS NULL
ORDER BY m.customer_id; 
#OR using not exists
SELECT m.customer_id
	FROM members m
WHERE NOT EXISTS (
  SELECT 1 FROM sales s WHERE s.customer_id = m.customer_id
    AND s.order_date >= m.join_date
    AND s.order_date <= DATE_ADD(m.join_date, INTERVAL 6 DAY)
);
#OR using group by and having
SELECT m.customer_id
	FROM members m LEFT JOIN sales s ON s.customer_id = m.customer_id
 AND s.order_date >= m.join_date
 AND s.order_date <= DATE_ADD(m.join_date, INTERVAL 6 DAY)
GROUP BY m.customer_id
HAVING COUNT(s.order_date) = 0;

/* --------------------------------------------------
#26. Customers who purchased something exactly on their join date
-------------------------------------------------- */  


Select distinct m.customer_id
from members m join sales s on m.customer_id = s.customer_id
where m.join_date = s.order_date;

/* --------------------------------------------------
   Q#27. Total spend before membership for each customer
-------------------------------------------------- */  

Select s.customer_id, sum(price) as bef_Spend
	from sales s join members mem on s.customer_id = mem.customer_id
	join menu m on s.product_id = m.product_id
	where join_date > order_date
	group by s.customer_id
    order by s.customer_id;

/* --------------------------------------------------
#Total spend before vs after membership for each customer
-------------------------------------------------- */  

SELECT
  s.customer_id,
  SUM(CASE WHEN s.order_date <  mem.join_date THEN m.price ELSE 0 END) AS before_spend,
  SUM(CASE WHEN s.order_date >= mem.join_date THEN m.price ELSE 0 END) AS after_spend,
  SUM(CASE WHEN s.order_date >= mem.join_date THEN m.price ELSE 0 END)
  - SUM(CASE WHEN s.order_date <  mem.join_date THEN m.price ELSE 0 END) AS after_minus_before
FROM sales s
JOIN members mem
  ON s.customer_id = mem.customer_id
JOIN menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

#OR
SELECT customer_id, before_spend, after_spend,
  (after_spend - before_spend) AS after_minus_before
FROM (
  SELECT s.customer_id,
    SUM(CASE WHEN s.order_date <  mem.join_date THEN m.price ELSE 0 END) AS before_spend,
    SUM(CASE WHEN s.order_date >= mem.join_date THEN m.price ELSE 0 END) AS after_spend
  FROM sales s
  JOIN members mem ON s.customer_id = mem.customer_id
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id
) t
ORDER BY customer_id;

/* --------------------------------------------------
   Q#28 Did customers spend more before or after joining?
#(Return: before_amount, after_amount, comparison flag)
-------------------------------------------------- */  


SELECT customer_id, before_spend, after_spend,
  CASE
    WHEN after_spend > before_spend THEN 'After'
    WHEN after_spend < before_spend THEN 'Before'
    ELSE 'Equal'
  END AS spend_more
FROM (
  SELECT
    s.customer_id,
    SUM(CASE WHEN s.order_date <  mem.join_date THEN m.price ELSE 0 END) AS before_spend,
    SUM(CASE WHEN s.order_date >= mem.join_date THEN m.price ELSE 0 END) AS after_spend
  FROM sales s
  JOIN members mem ON s.customer_id = mem.customer_id
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id
) t
ORDER BY customer_id;

/* --------------------------------------------------
   Q#29. Number of days between joining and first post-membership purchase
-------------------------------------------------- */  

select customer_id, datediff(order_date, join_date) as diffbetween 
 from (select s.customer_id, mem.join_date, s.order_date,
	dense_rank() over(partition by s.customer_id
						order by order_date) as rnk
	from members mem join sales s
    On mem.customer_id = s.customer_id
    where s.order_date >= mem.join_date) ranked
    where rnk=1;
  

/* --------------------------------------------------
   Q#30. Percentage of customers who made a purchase within 7 days of joining
-------------------------------------------------- */  
SELECT
  ROUND(100.0 * SUM(purchased_within_7) / COUNT(*), 2) AS pct_purchased_within_7_days
FROM (
  SELECT
    m.customer_id,
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM sales s
        WHERE s.customer_id = m.customer_id
          AND s.order_date >= m.join_date
          AND s.order_date <= DATE_ADD(m.join_date, INTERVAL 6 DAY)
      ) THEN 1 ELSE 0
    END AS purchased_within_7
  FROM members m
) temp;

/* --------------------------------------------------
   Q#31. Customers who ordered the same item multiple times on the same day
-------------------------------------------------- */  

SELECT s.customer_id, s.order_date, m.product_name, COUNT(*) AS times_ordered
	FROM sales s JOIN menu m
  ON s.product_id = m.product_id
	GROUP BY s.customer_id, s.order_date, m.product_name
	HAVING COUNT(*) > 1
	ORDER BY s.customer_id, s.order_date, m.product_name;


/* --------------------------------------------------
   Q#32. Products that were never purchased by members
-------------------------------------------------- */     
 
 SELECT m.product_name
	FROM menu m
WHERE NOT EXISTS (
  SELECT 1
  FROM sales s JOIN members mem
    ON mem.customer_id = s.customer_id
  WHERE s.product_id = m.product_id
    AND s.order_date >= mem.join_date
)
ORDER BY m.product_name;

#OR
SELECT m.product_name
	FROM menu m LEFT JOIN sales s
  ON m.product_id = s.product_id
	LEFT JOIN members mem
  ON mem.customer_id = s.customer_id
 AND s.order_date >= mem.join_date  
GROUP BY m.product_id, m.product_name
HAVING COUNT(mem.customer_id) = 0;

/* --------------------------------------------------
   Q#33. Customers whose first-ever purchase was also their first purchase as a member
-------------------------------------------------- */  

SELECT
  mem.customer_id
FROM members mem
JOIN (
  SELECT customer_id, MIN(order_date) AS first_ever_date
  FROM sales
  GROUP BY customer_id
) fe
  ON mem.customer_id = fe.customer_id
JOIN (
  SELECT
    s.customer_id,
    MIN(s.order_date) AS first_member_date
  FROM sales s
  JOIN members mem2
    ON s.customer_id = mem2.customer_id
  WHERE s.order_date >= mem2.join_date
  GROUP BY s.customer_id
) fm
  ON mem.customer_id = fm.customer_id
WHERE fe.first_ever_date = fm.first_member_date;	

/* --------------------------------------------------
   Q34. Which product converts non-members to members the fastest?
#(Shortest avg time from first purchase → join)
-------------------------------------------------- */  

SELECT
  me.product_name,
  AVG(DATEDIFF(mem.join_date, fp.first_purchase_date)) AS avg_days_to_join,
  COUNT(DISTINCT mem.customer_id) AS members_count
FROM members mem
JOIN (
  SELECT customer_id, MIN(order_date) AS first_purchase_date
  FROM sales
  GROUP BY customer_id
) fp
  ON mem.customer_id = fp.customer_id
JOIN sales s
  ON s.customer_id = fp.customer_id
 AND s.order_date = fp.first_purchase_date
JOIN menu me
  ON me.product_id = s.product_id
GROUP BY me.product_name
ORDER BY avg_days_to_join ASC, members_count DESC;

/* --------------------------------------------------
   Q35. Which product should Danny promote to increase membership sign-ups?#(Explain using SQL output)
-------------------------------------------------- */  

SELECT
  me.product_name,
  COUNT(DISTINCT mem.customer_id) AS members_acquired,
  AVG(DATEDIFF(mem.join_date, fp.first_purchase_date)) AS avg_days_to_join
FROM members mem
JOIN (
  SELECT customer_id, MIN(order_date) AS first_purchase_date
  FROM sales
  GROUP BY customer_id
) fp
  ON mem.customer_id = fp.customer_id
JOIN sales s
  ON s.customer_id = fp.customer_id
 AND s.order_date = fp.first_purchase_date
JOIN menu me
  ON me.product_id = s.product_id
GROUP BY me.product_name
ORDER BY members_acquired DESC, avg_days_to_join ASC;

/* --------------------------------------------------
   Q#36. Rewrite “most popular item per customer” without window functions
-------------------------------------------------- */  
SELECT
  t.customer_id,
  t.product_name,
  t.cnt AS times_ordered
FROM (
  SELECT
    s.customer_id,
    m.product_name,
    COUNT(*) AS cnt
  FROM sales s
  JOIN menu m
    ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
) t
JOIN (
  SELECT
    customer_id,
    MAX(cnt) AS max_cnt
  FROM (
    SELECT
      s.customer_id,
      m.product_name,
      COUNT(*) AS cnt
    FROM sales s
    JOIN menu m
      ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
  ) x
  GROUP BY customer_id
) mx
  ON t.customer_id = mx.customer_id
 AND t.cnt = mx.max_cnt
ORDER BY t.customer_id, t.product_name;

/* --------------------------------------------------
 #Q37. Give me one first purchase record per customer
-------------------------------------------------- */  

SELECT customer_id, order_date, product_id
	FROM ( SELECT customer_id, order_date, product_id,
    ROW_NUMBER() OVER ( PARTITION BY customer_id
						ORDER BY order_date) AS rn
  FROM sales) ranked WHERE rn = 1;

-- Pizza Runner — SQL Solutions (MySQL)
-- Author: Saisushmitha Reddy
-- Case Study 2 of 8 Week SQL Challenge

/* --------------------------------------------------
   SECTION A: Pizza Metrics
-------------------------------------------------- */

#Cleaning the tables before performing analysis on various scenarios
CREATE OR REPLACE VIEW runner_orders_clean AS
SELECT
  order_id,
  runner_id,

  -- pickup_time: convert 'null' or '' to NULL, else cast to datetime
  CASE
    WHEN pickup_time IS NULL OR pickup_time = '' OR LOWER(pickup_time) = 'null' THEN NULL
    ELSE CAST(pickup_time AS DATETIME)
  END AS pickup_time,

  -- distance: remove 'km' and spaces, convert to decimal
  CASE
    WHEN distance IS NULL OR distance = '' OR LOWER(distance) = 'null' THEN NULL
    ELSE CAST(REPLACE(REPLACE(LOWER(distance), 'km', ''), ' ', '') AS DECIMAL(5,2))
  END AS distance_km,

  -- duration: remove 'minutes', 'minute', 'mins', spaces -> integer minutes
  CASE
    WHEN duration IS NULL OR duration = '' OR LOWER(duration) = 'null' THEN NULL
    ELSE CAST(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(LOWER(duration), 'minutes', ''),
          'minute', ''),
        'mins', ''),
      ' ', '') AS UNSIGNED
    )
  END AS duration_mins,

  -- cancellation: '' or 'null' -> NULL
  CASE
    WHEN cancellation IS NULL OR cancellation = '' OR LOWER(cancellation) = 'null' THEN NULL
    ELSE cancellation
  END AS cancellation
FROM runner_orders;

  CREATE OR REPLACE VIEW customer_orders_clean AS
SELECT
  order_id,
  customer_id,
  pizza_id,
  CASE
    WHEN exclusions IS NULL OR exclusions = '' OR LOWER(exclusions) = 'null' THEN NULL
    ELSE REPLACE(exclusions, ' ', '')
  END AS exclusions,
  CASE
    WHEN extras IS NULL OR extras = '' OR LOWER(extras) = 'null' THEN NULL
    ELSE REPLACE(extras, ' ', '')
  END AS extras,
  order_time
FROM customer_orders;

/* --------------------------------------------------
   Q1. How many pizzas were ordered?
-------------------------------------------------- */
Select count(*) as total_orders
	from customer_orders_clean;

/* --------------------------------------------------
   Q2. How many unique customer orders were made?
-------------------------------------------------- */
Select count(distinct order_id) as uniq_customers 
	from customer_orders_clean;

/* --------------------------------------------------
   Q3. How many successful orders were delivered by each runner?
-------------------------------------------------- */
Select runner_id, count(order_id) as total_orders
	from runner_orders_clean
    where cancellation is null
    and pickup_time is not null
    group by runner_id;
    
/* --------------------------------------------------
   Q4. How many of each type of pizza was delivered?
-------------------------------------------------- */
 Select c.pizza_id, count(*) as deliver_Pizzas
	from runner_orders_clean  as r
    join customer_orders_clean as c 
    on r.order_id = c.order_id
where r.cancellation is null
   and r.pickup_time is not null
group by c.pizza_id;

/* --------------------------------------------------
   Q5. How many Vegetarian and Meatlovers were ordered by each customer?
-------------------------------------------------- */
Select c.customer_id, p.pizza_name, count(*) as pizzas_ordered
	from customer_orders_clean as c
    join pizza_names as p
    on c.pizza_id = p.pizza_id
    group by c.customer_id, p.pizza_name
    order by c.customer_id;

/* --------------------------------------------------
   Q6.What was the maximum number of pizzas delivered in a single order?
-------------------------------------------------- */
 SELECT MAX(pizzas_inorder) AS max_pizzas from
 (Select c.order_id, count(*) as pizzas_inorder
	from customer_orders_clean as c
    join runner_orders_clean as r
    on c.order_id = r.order_id
    where r.cancellation is null
    and r.pickup_time is not null
    group by c.order_id)temp;

/* --------------------------------------------------
   Q7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
-------------------------------------------------- */
SELECT
  c.customer_id,
  SUM(CASE WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 1 ELSE 0 END) AS changed_pizzas,
  SUM(CASE WHEN c.exclusions IS NULL AND c.extras IS NULL THEN 1 ELSE 0 END)  AS no_change_pizzas
FROM customer_orders_clean c
JOIN runner_orders_clean r
  ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
  AND r.pickup_time IS NOT NULL
GROUP BY c.customer_id
ORDER BY c.customer_id;

SELECT
  c.customer_id,
  CASE
    WHEN c.exclusions IS NOT NULL OR c.extras IS NOT NULL THEN 'changed'
    ELSE 'no_change'
  END AS pizza_status,
  COUNT(*) AS pizzas
FROM customer_orders_clean c
JOIN runner_orders_clean r
  ON r.order_id = c.order_id
WHERE r.cancellation IS NULL
  AND r.pickup_time IS NOT NULL
GROUP BY c.customer_id, pizza_status
ORDER BY c.customer_id, pizza_status;

/* --------------------------------------------------
   Q8.How many pizzas were delivered that had both exclusions and extras?
-------------------------------------------------- */
Select
	sum( case when c.exclusions is not null and c.extras is not null then 1 else 0 end) as changes
	from customer_orders_clean as c 
	join runner_orders_clean as r
    on c.order_id = r.order_id
    where cancellation is null
   and pickup_time is not null;

/* --------------------------------------------------
   Q9.What was the total volume of pizzas ordered for each hour of the day?
-------------------------------------------------- */
SELECT
  HOUR(order_time) AS hour_of_day,
  COUNT(*) AS pizzas_ordered
FROM customer_orders_clean
GROUP BY HOUR(order_time)
ORDER BY hour_of_day;

/* --------------------------------------------------
   Q10.What was the volume of orders for each day of the week?
-------------------------------------------------- */
Select count(distinct order_id) as order_volumes, weekday(order_time) as w_day
from customer_orders_clean
group by weekday(order_time)
order by w_day;
####OR
SELECT
  WEEKDAY(order_time) AS weekday_num,
  DAYNAME(order_time) AS day_of_week,
  COUNT(DISTINCT order_id) AS order_volume
FROM customer_orders_clean
GROUP BY WEEKDAY(order_time), DAYNAME(order_time)
ORDER BY weekday_num;


###########Runner and Customer Experience
/* --------------------------------------------------
   Q11.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
-------------------------------------------------- */
SELECT
  DATE_ADD('2021-01-01', INTERVAL (FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) * 7) DAY) AS week_start,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_start
ORDER BY week_start;

SELECT
  week_index,
  DATE_ADD('2021-01-01', INTERVAL week_index * 7 DAY) AS week_start,
  COUNT(*) AS runners_signed_up
FROM (
  SELECT
    FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) AS week_index
  FROM runners
) t
GROUP BY week_index
ORDER BY week_index;


/* --------------------------------------------------
   Q12.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
-------------------------------------------------- */  
SELECT r.runner_id,
  AVG(TIMESTAMPDIFF(MINUTE, c.order_time, r.pickup_time)) AS avg_minutes_to_pickup
FROM runner_orders_clean r
JOIN customer_orders_clean c
  ON r.order_id = c.order_id
WHERE r.pickup_time IS NOT NULL
  AND r.cancellation IS NULL
GROUP BY r.runner_id
ORDER BY r.runner_id;

/* --------------------------------------------------
   Q13.Is there any relationship between the number of pizzas and how long the order takes to prepare?
-------------------------------------------------- */  
select c.order_id, count(*) as pizza_count, timestampdiff(minute, min(c.order_time), r.pickup_time) as prep_time
	FROM runner_orders_clean r
	JOIN customer_orders_clean c
  ON r.order_id = c.order_id
	WHERE r.pickup_time IS NOT NULL
  AND r.cancellation IS NULL
    group by c.order_id, r.pickup_time;


/* --------------------------------------------------
   Q13.What was the average distance travelled for each customer?
-------------------------------------------------- */ 
SELECT
  customer_id,
  AVG(distance_km) AS avg_distance_km
FROM (
  SELECT
    r.order_id,
    MIN(c.customer_id) AS customer_id,
    r.distance_km
  FROM runner_orders_clean r
  JOIN customer_orders_clean c
    ON r.order_id = c.order_id
  WHERE r.pickup_time IS NOT NULL
    AND r.cancellation IS NULL
    AND r.distance_km IS NOT NULL
  GROUP BY r.order_id, r.distance_km
) innert
GROUP BY customer_id
ORDER BY customer_id;

/* --------------------------------------------------
   Q14.What was the difference between the longest and shortest delivery times for all orders?
-------------------------------------------------- */ 
Select (max(duration_mins) - min(duration_mins)) as diff 
	from runner_orders_clean
    where cancellation is null
    and pickup_time is not null
    and duration_mins is not null;
    
###more clear readability
SELECT
  MIN(duration_mins) AS shortest,
  MAX(duration_mins) AS longest,
  MAX(duration_mins) - MIN(duration_mins) AS diff
FROM runner_orders_clean
WHERE cancellation IS NULL
  AND pickup_time IS NOT NULL
  AND duration_mins IS NOT NULL;

/* --------------------------------------------------
   Q14.What was the average speed for each runner for each delivery and do you notice any trend for these values?
-------------------------------------------------- */ 
Select order_id, runner_id, Round(distance_km/duration_mins,2) as speed
	from runner_orders_clean
	WHERE cancellation IS NULL
  AND pickup_time IS NOT NULL
  AND duration_mins IS NOT NULL
  and distance_km is not null;

/* --------------------------------------------------
   Q15.What is the successful delivery percentage for each runner?
-------------------------------------------------- */ 

SELECT
  runner_id,
  ROUND(
    100.0 * 
    SUM(
      CASE 
        WHEN pickup_time IS NOT NULL AND cancellation IS NULL THEN 1 
        ELSE 0 
      END
    ) / COUNT(*),
    2
  ) AS successful_delivery_percentage
FROM runner_orders_clean
GROUP BY runner_id
ORDER BY runner_id;

####using left join
SELECT
  d.runner_id,
  ROUND(100.0 * s.Nr / d.Dr, 2) AS percent_del
FROM
  (SELECT runner_id, COUNT(*) AS Dr
   FROM runner_orders_clean
   GROUP BY runner_id) AS d
LEFT JOIN
  (SELECT runner_id, COUNT(*) AS Nr
   FROM runner_orders_clean
   WHERE cancellation IS NULL
     AND pickup_time IS NOT NULL
   GROUP BY runner_id) AS s
ON d.runner_id = s.runner_id
ORDER BY d.runner_id;



################Ingredient Optimisation
/* --------------------------------------------------
   Q16.What are the standard ingredients for each pizza?
-------------------------------------------------- */ 
SELECT
  pn.pizza_id,
  pn.pizza_name,
  GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name) AS standard_ingredients
FROM pizza_names pn
JOIN pizza_recipes pr
  ON pn.pizza_id = pr.pizza_id
JOIN pizza_toppings pt
  ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0
GROUP BY pn.pizza_id, pn.pizza_name
ORDER BY pn.pizza_id;

/* --------------------------------------------------
   Q17.What was the most commonly added extra?
-------------------------------------------------- */ 
Select pt.topping_name, count(*) as common_extra
from customer_orders_clean c join pizza_toppings pt 
on FIND_IN_SET(pt.topping_id, REPLACE(c.extras, ' ', '')) > 0
where c.extras is not null
group by pt.topping_name
order by common_extra desc
limit 1;

/* --------------------------------------------------
   Q18.What was the most common exclusion?
-------------------------------------------------- */ 
Select pt.topping_name, count(*) as common_exclusion
from customer_orders_clean c join pizza_toppings pt
on find_in_set(pt.topping_id, replace(c.exclusions, ' ', '')) >0
where c.exclusions is not null
group by pt.topping_name
order by common_exclusion desc
limit 1;

/* --------------------------------------------------
   Q19.Generate an order item for each record in the customers_orders table in the format of one of the following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-------------------------------------------------- */ 
SELECT
  CONCAT(
    p.pizza_name,
    IF(excl.excl_names IS NULL, '', CONCAT(' - Exclude ', excl.excl_names)),
    IF(ext.extra_names IS NULL, '', CONCAT(' - Extra ', ext.extra_names))
  ) AS order_item
FROM customer_orders_clean c
JOIN pizza_names p
  ON c.pizza_id = p.pizza_id

/* exclusions per row */
LEFT JOIN (
  SELECT
    c2.order_id,
    c2.pizza_id,
    GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS excl_names
  FROM customer_orders_clean c2
  JOIN pizza_toppings pt
    ON FIND_IN_SET(pt.topping_id, REPLACE(c2.exclusions, ' ', '')) > 0
  WHERE c2.exclusions IS NOT NULL
  GROUP BY c2.order_id, c2.pizza_id
) excl
  ON c.order_id = excl.order_id
 AND c.pizza_id = excl.pizza_id

/* extras per row */
LEFT JOIN (
  SELECT
    c3.order_id,
    c3.pizza_id,
    GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS extra_names
  FROM customer_orders_clean c3
  JOIN pizza_toppings pt
    ON FIND_IN_SET(pt.topping_id, REPLACE(c3.extras, ' ', '')) > 0
  WHERE c3.extras IS NOT NULL
  GROUP BY c3.order_id, c3.pizza_id
) ext
  ON c.order_id = ext.order_id
 AND c.pizza_id = ext.pizza_id;


/* --------------------------------------------------
   Q20.Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-------------------------------------------------- */ 
WITH base_ingredients AS (
  -- standard ingredients per order
  SELECT
    c.order_id,
    p.pizza_name,
    pt.topping_name
  FROM customer_orders_clean c
  JOIN pizza_names p
    ON c.pizza_id = p.pizza_id
  JOIN pizza_recipes r
    ON c.pizza_id = r.pizza_id
  JOIN pizza_toppings pt
    ON FIND_IN_SET(pt.topping_id, REPLACE(r.toppings, ' ', '')) > 0
),

removed_exclusions AS (
  -- remove excluded toppings
  SELECT
    b.order_id,
    b.pizza_name,
    b.topping_name
  FROM base_ingredients b
  LEFT JOIN customer_orders_clean c
    ON b.order_id = c.order_id
   AND FIND_IN_SET(
         (SELECT topping_id
          FROM pizza_toppings
          WHERE topping_name = b.topping_name),
         REPLACE(c.exclusions, ' ', '')
       ) > 0
  WHERE c.exclusions IS NULL
     OR FIND_IN_SET(
         (SELECT topping_id
          FROM pizza_toppings
          WHERE topping_name = b.topping_name),
         REPLACE(c.exclusions, ' ', '')
       ) = 0
),

extras_added AS (
  -- extras as additional ingredients
  SELECT
    c.order_id,
    p.pizza_name,
    pt.topping_name
  FROM customer_orders_clean c
  JOIN pizza_names p
    ON c.pizza_id = p.pizza_id
  JOIN pizza_toppings pt
    ON FIND_IN_SET(pt.topping_id, REPLACE(c.extras, ' ', '')) > 0
),

all_ingredients AS (
  -- union standard + extras
  SELECT * FROM removed_exclusions
  UNION ALL
  SELECT * FROM extras_added
),

ingredient_counts AS (
  -- count ingredients per order
  SELECT
    order_id,
    pizza_name,
    topping_name,
    COUNT(*) AS qty
  FROM all_ingredients
  GROUP BY order_id, pizza_name, topping_name
)

SELECT
  CONCAT(
    pizza_name,
    ': ',
    GROUP_CONCAT(
      CASE
        WHEN qty > 1 THEN CONCAT(qty, 'x', topping_name)
        ELSE topping_name
      END
      ORDER BY topping_name
      SEPARATOR ', '
    )
  ) AS ingredient_list
FROM ingredient_counts
GROUP BY order_id, pizza_name
ORDER BY order_id;

/* --------------------------------------------------
   Q21. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
-------------------------------------------------- */ 
SELECT
  pt.topping_name,
  COUNT(*) AS total_quantity
FROM runner_orders_clean r
JOIN customer_orders_clean c
  ON r.order_id = c.order_id
JOIN pizza_recipes pr
  ON c.pizza_id = pr.pizza_id
JOIN pizza_toppings pt
  ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', '')) > 0

-- keep only delivered pizzas
WHERE r.cancellation IS NULL
  AND r.pickup_time IS NOT NULL

-- remove excluded ingredients
  AND (
    c.exclusions IS NULL
    OR FIND_IN_SET(pt.topping_id, REPLACE(c.exclusions, ' ', '')) = 0
  )

GROUP BY pt.topping_name
ORDER BY total_quantity DESC;




/*
D. Pricing and Ratings
If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
What if there was an additional $1 charge for any pizza extras?
Add cheese is $1 extra
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
customer_id
order_id
runner_id
rating
order_time
pickup_time
Time between order and pickup
Delivery duration
Average speed
Total number of pizzas
If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
E. Bonus Questions
If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/
  

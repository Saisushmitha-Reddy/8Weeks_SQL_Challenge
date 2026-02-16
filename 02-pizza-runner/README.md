# Pizza Runner — SQL Case Study (MySQL)

This case study focuses on order fulfillment, delivery performance, and operational metrics for a pizza delivery startup.

## Files
- `schema.sql` — tables + seed data (raw tables and cleaned views)
- `solutions.sql` — SQL solutions (MySQL) to all questions

## Key Concepts Practiced
- Data cleaning (text → numeric, handling NULLs)
- Joins across orders, runners, and pizzas
- Delivery KPIs (success rate, avg speed, time-to-deliver)
- Ingredient/extras/exclusions parsing
- Grouping + window functions for ranking and trends
- Conditional logic with CASE

## Notes
Pizza Runner has messy fields (extras/exclusions, distance, duration) that require cleaning before analysis.
So, I have created couple views in my solution

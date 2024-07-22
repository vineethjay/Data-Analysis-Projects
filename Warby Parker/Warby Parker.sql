-- Marketing Funnel Analysis

WITH Marketing_Funnel AS (
SELECT
question_text AS question,
COUNT(question_text) AS responses,
COUNT(question_text) * 100.00 / (SELECT COUNT(DISTINCT user_id) FROM survey) AS percentage_of_completion
FROM
survey
GROUP BY
question_text
)
SELECT
question,
responses,
percentage_of_completion,
percentage_of_completion - LAG(percentage_of_completion) OVER (ORDER BY question) AS decrease_in_response
FROM
Marketing_Funnel
ORDER BY
question;

-- Number of users at each stage
SELECT 'Quiz' AS stage, COUNT(DISTINCT user_id) AS number_of_customers FROM quiz
UNION ALL
SELECT 'Home Try-On' AS stage, COUNT(DISTINCT user_id) AS number_of_customers FROM home_try_on
UNION ALL
SELECT 'Purchase' AS stage, COUNT(DISTINCT user_id) AS number_of_customers FROM purchase;

-- Conversion Rates
SELECT
'Quiz to Home Try-On' AS conversion_type,
COUNT(DISTINCT q.user_id) * 100.00 / (SELECT COUNT(DISTINCT user_id) FROM quiz) AS conversion_rate
FROM
quiz q
JOIN
home_try_on h ON q.user_id = h.user_id
UNION ALL
SELECT
'Home Try-On to Purchase' AS conversion_type,
COUNT(DISTINCT h.user_id) * 100.00 / (SELECT COUNT(DISTINCT user_id) FROM home_try_on) AS conversion_rate
FROM
home_try_on h
JOIN
purchase p ON h.user_id = p.user_id
UNION ALL
SELECT
'Quiz to Purchase' AS conversion_type,
COUNT(DISTINCT q.user_id) * 100.00 / (SELECT COUNT(DISTINCT user_id) FROM quiz) AS conversion_rate
FROM
quiz q
JOIN
purchase p ON q.user_id = p.user_id;

-- AB Test with
WITH a AS (
SELECT DISTINCT
h.qty AS number_of_pairs,
COUNT(h.qty) AS home_trail
FROM quiz q
LEFT JOIN home_try_on h ON q.user_id = h.user_id
WHERE h.user_id IS NOT NULL
GROUP BY h.qty
),
b AS (
SELECT DISTINCT
h.qty AS number_of_pairs,
COUNT(h.qty) AS purchase,
SUM(p.price) AS total_revenue,
COUNT(product_id) AS total_units_sold
FROM quiz q
LEFT JOIN home_try_on h ON q.user_id = h.user_id
LEFT JOIN purchase p ON q.user_id = p.user_id
WHERE p.user_id IS NOT NULL
GROUP BY h.qty
)
SELECT
a.number_of_pairs,
home_trail,
b.purchase,
b.purchase * 100.00 / a.home_trail AS conversion_rate,
b.total_revenue,
b.total_units_sold,
b.total_revenue / b.total_units_sold AS avg_price
FROM a, b
WHERE a.number_of_pairs = b.number_of_pairs


-- Top 5 product_id purchases by sales
SELECT TOP 5
product_id,
COUNT(product_id) AS quantity,
SUM(price) AS sales
FROM purchase
GROUP BY product_id
ORDER BY sales DESC;

-- Top styles purchases by sales
SELECT
style,
COUNT(style) AS quantity,
SUM(price) AS sales
FROM purchase
GROUP BY style
ORDER BY sales DESC;

-- Top model_names purchases by sales
SELECT
model_name,
COUNT(model_name) AS quantity,
SUM(price) AS sales
FROM purchase
GROUP BY model_name
ORDER BY sales DESC;

-- Top 5 colors purchases by sales
SELECT TOP 5
color,
COUNT(color) AS quantity,
SUM(price) AS sales
FROM purchase
GROUP BY color
ORDER BY sales DESC;


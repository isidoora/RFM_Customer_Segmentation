/* data source: https://www.kaggle.com/datasets/jackdaoud/marketing-data?select=ifood_df.csv */

/* analyzing what customer's caracteristics lead to acceptance of campaign */
/* target variable pilot_campaign has value 1 if customer positively engaged with campaign, 0 otherwise */

USE marketing_analytics;

/* inspecting data */
SELECT * FROM ifood LIMIT 10;

/* renaming id column */
ALTER TABLE ifood RENAME COLUMN ï»¿id TO id;


/* pilot campagn success by gender */
SELECT
	gender,
    count(*)
FROM ifood
WHERE pilot_campaign = 1
GROUP BY 1;

/* success percent by gender */
WITH gender_count AS (
	SELECT
		gender, 
		COUNT(*) AS num
    FROM ifood
    GROUP BY 1
)
SELECT
	DISTINCT ifood.gender,
	ROUND(SUM(pilot_campaign) OVER(PARTITION BY gender) / gc.num * 100, 2) AS success_percent
FROM ifood
JOIN gender_count AS gc
	ON ifood.gender = gc.gender;

/* by age category */
SELECT
	CASE
		WHEN age < 30 THEN "young"
        WHEN age < 55 THEN "middle-aged"
        ELSE "elderly"
	END AS age_cat,
    COUNT(*) AS accepted_pilot
FROM ifood
WHERE pilot_campaign = 1
GROUP BY 1
ORDER BY 2;

select distinct marital_status from ifood;

/* spending by marital status grouped to single/taken*/
SELECT 
    CASE
        WHEN marital_status IN ('Single' , 'Widow', 'Divorced') THEN 'single'
        ELSE 'with partner'
    END AS status,
    COUNT(*),
    SUM(total)
FROM ifood
WHERE pilot_campaign = 1			
GROUP BY 1;

/* success by marital_status of other campaigns*/
SELECT
	CASE
        WHEN marital_status IN ('Single' , 'Widow', 'Divorced') THEN 'single'
        ELSE 'taken'
    END status,
    SUM(campaign1),
    SUM(campaign2),
    SUM(campaign3),
    SUM(campaign4),
    SUM(campaign5),
    SUM(pilot_campaign)
FROM ifood
GROUP BY 1;
-- taken spend more in general and were a lot more influenced by all previous campaigns


/* average income of customers */
-- SELECT AVG(income) FROM ifood;
-- output: '51969.8614'

-- successful pilot by level of education
SELECT education, 
		COUNT(*) num   
FROM ifood 
WHERE pilot_campaign = 1
GROUP BY education
ORDER BY 2 DESC;

/* by income */
SELECT
	CASE 
		WHEN income < 30000 THEN 'low'
		WHEN income < 60000 THEN 'medium'
		ELSE 'high'
	END AS income_category,
    COUNT(*) AS num
FROM ifood
WHERE pilot_campaign = 1
GROUP BY 1
ORDER BY 2 DESC;

/* by number of kids */
SELECT 
    kids,
    COUNT(*) AS count
FROM ifood
WHERE pilot_campaign = 1
GROUP BY 1;

/* through which channel should we aim next campaign? */
SELECT
	SUM(web_purchases) AS web,
	SUM(catalog_purchases) AS catalog,
    SUM(store_purchases) AS store
FROM ifood
WHERE pilot_campaign = 1;

/* RFM */
WITH rfm AS
(
	SELECT
		id,
		recency,
		frequancy,
		monetary_value,
		recency * 100 + frequancy * 10 + monetary_value AS rfm_score,
		ROUND((recency + frequancy + monetary_value)/3) AS rfm_category
	FROM
    (
		SELECT
			id,
			NTILE(5) OVER(ORDER BY last_purchase DESC) AS recency,
			NTILE(5) OVER(ORDER BY count_purchases) AS frequancy,
			NTILE(5) OVER(ORDER BY amount_spent) AS monetary_value
		FROM
        (
			SELECT
				id,
				last_purchase,
				COUNT(*) AS count_purchases,
				SUM(total) AS amount_spent
			FROM ifood
			GROUP BY 1, 2
		) AS counts
	) AS scores
)
SELECT 
    rfm_category,
    COUNT(*)
FROM
    rfm
	LEFT JOIN ifood 
		ON rfm.id = ifood.id
WHERE
    ifood.pilot_campaign = 1
GROUP BY 1
ORDER BY 2;

-- ----------------------------- ------------------------------- --------------------------- ------------------------------- ------------------------------ --
/* some queries used to gain insights into data
that were irelevant for inclusion in final report */

/* spending across food categories */
SELECT SUM(wines) OVER() AS wines,
		SUM(fruits) OVER() AS fruit,
        SUM(meats) OVER() AS meat,
        SUM(fish) OVER() AS fish,
        SUM(sweets) OVER() AS sweet
FROM ifood
-- WHER pilot_campaign = 1
LIMIT 1;

/* gold/regular */
SELECT SUM(gold_products) OVER() AS gold,
		SUM(regular_products) OVER() AS regular
FROM ifood
-- WHERE pilot_campaign = 1
LIMIT 1;

/* spending by gender */
SELECT gender,
	SUM(total) AS total
FROM ifood
-- WHERE pilot_campaign = 1 
GROUP BY 1
ORDER BY 2 DESC;

/* by marital status */
SELECT
	marital_status, 
	COUNT(*), 
	AVG(total),
	SUM(total)
FROM ifood
WHERE pilot_campaign = 1
GROUP BY 1
ORDER BY 2 DESC;

/* education review */
SELECT 
	education,
    COUNT(*),
    MIN(income),
    MAX(income),
    AVG(income)
FROM ifood
GROUP BY 1
ORDER BY 5 DESC;

/* most valuable customers */
SELECT
	id,
    SUM(total)
FROM ifood
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


/* age group with most discounted purchases and purchase channels */
SELECT
	CASE 
		WHEN age < 30 THEN "young"
        WHEN age < 55 THEN "middle aged"
        ELSE "elderly"
	END AS age_cat,
    SUM(web_purchases),
    SUM(store_purchases),
    SUM(web_visits_month),
    SUM(deal_purchases)
FROM ifood
-- WHERE pilot_campaign = 1
GROUP BY 1;
# SQL quries

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
LIMIT 100;

---old car was manufactured in 1982 and latest in 2015
SELECT MIN(year) AS old_year_manufactured,
       MAX(year) AS latest_manufacture_year
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

----oldest and latest model year by make and model
SELECT make,
   model,
  MIN(year) AS oldest_model_year,
  MAX(year) AS latest_model_year
FROM `workspace`.`bright_car_sales`.`car_sales_data`
GROUP BY make,
         model
ORDER BY make DESC;

---Oldest date was in 2014 Jan and latest July 2015
SELECT make,
  model,
  MIN(saledate) AS oldest_sale_date,
  MAX(saledate) AS latest_sale_date
FROM `workspace`.`bright_car_sales`.`car_sales_data`
GROUP BY make, 
         model
ORDER BY oldest_sale_date ASC;

---We have 96 distinct make and 1 unknown
SELECT DISTINCT make
FROM `workspace`.`bright_car_sales`.`car_sales_data`
ORDER BY make ASC;

---check for nulls
SELECT
  COUNT(*) AS total_rows,
  COUNT(sellingprice) AS s_price,
  COUNT(mmr) AS m_mmr,
  COUNT(condition) AS c_condition,
  COUNT(transmission) AS t_transmission
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---Check for nulls in each column
---================================
---12 columns have nulls. 
---================================
SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE transmission is NULL;

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE body is NULL;

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE make is NULL;

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE color is NULL;

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE odometer is NULL;

SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE mmr is NULL;

--- No null values
SELECT *
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE seller is NULL;
---==================================================
---Min and max travelled
SELECT MIN(odometer),   --1km
       MAX(odometer)    --999999km
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---Calculate the profit margin
SELECT 
   ((sellingprice - mmr) / sellingprice)*100 AS Profit_Margin
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---units_sold can be created by counting how many times the same make+model+saledate appears together:
SELECT COUNT(*) OVER (PARTITION BY make, model, saledate) AS Units_Sold
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---calculate total revenue
SELECT (sellingprice) * (COUNT(*) OVER (PARTITION BY make, model, saledate)) AS Total_Revenue
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---total revenue by model, make, year, state, note there is no fuel type column 
SELECT make,
       model,
       year,
       state,
       sellingprice,
       COUNT(*) OVER (PARTITION BY make, model, saledate) AS Units_Sold,
       sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---There's Dec 2014, Jan 2015, Feb 2015, April 2015, May 2015, July 2015,  
SELECT saledate
FROM `workspace`.`bright_car_sales`.`car_sales_data`
ORDER BY saledate DESC;

---The function removes the problematic day abbreviation that causes the error.
SELECT
    saledate,
    MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS month_name,
    DAYNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss'))   AS day_name,
    YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss'))   AS year,
    DAYOFMONTH(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS day_of_month
FROM `workspace`.`bright_car_sales`.`car_sales_data`;

---we have the year 2014 have 3 scattered months and 2015 have 7 consecutive months
SELECT
    MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS month_name,
    YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss'))      AS sale_year,
    COUNT(*) AS total_records
FROM `workspace`.`bright_car_sales`.`car_sales_data`
WHERE saledate IS NOT NULL
GROUP BY 
    MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),
    YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss'))
ORDER BY 
    sale_year,
    total_records DESC;
---================================
---CLEAN TABLE
---================================
SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`;
-- ============================================================
--- Analysis Queries
-- ============================================================
--- Revenue by Make
--- Ford generates the most revenue and sells the highest number of units, followed by Nissan and Toyota.
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    make,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue
FROM car_sales_clean
GROUP BY make
ORDER BY total_revenue DESC;

--- Revenue by Make and Model
--- At model level, the Nissan Altima is the top revenue generating model, followed by the Infiniti G Sedan
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    make,
    model,
    year,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue
FROM car_sales_clean
GROUP BY make, 
         model,
          year
ORDER BY total_revenue DESC;

--- Regional Performance
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    region,
    state,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue
FROM car_sales_clean
GROUP BY region,
         state
ORDER BY total_revenue DESC;

--- Body Style Performance
--- Sedans are the top performing body style, leading in both units sold and total revenue, followed closely by SUVs (both duplicated)
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    body,
    COUNT(*)                        AS units_sold,
    SUM(total_revenue)              AS total_revenue
FROM car_sales_clean
GROUP BY body
ORDER BY units_sold DESC;

--- Transmission Performance
--- Automatic transmission vehicles generate the most revenue, significantly outperforming manual transmission. Notably, vehicles with unknown transmission generated more revenue than manual, suggesting that the 65,352 missing transmission values represent a significant data gap that may be understating either automatic or manual performance.
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    transmission,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue 
FROM car_sales_clean
GROUP BY transmission
ORDER BY units_sold DESC;

--- Price vs Mileage (Mileage Bucket)
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    mileage_bucket,
    COUNT(*) AS units_sold,
    AVG(sellingprice) AS avg_selling_price,
    AVG(profit_margin) AS avg_profit_margin
FROM car_sales_clean
GROUP BY mileage_bucket
ORDER BY avg_selling_price DESC;

--- Condition vs Price
---Vehicles in Poor condition (1-10) sold more units than those in Fair condition (11-20), which is unexpected and may suggest that lower priced vehicles attract more buyers regardless of condition.
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    condition_bucket,
    COUNT(*) AS units_sold
FROM car_sales_clean
GROUP BY condition_bucket
ORDER BY units_sold DESC;

--- Sales by Time Period
---February 2015 generated the most revenue despite only selling 1 unit in Feb 2014. January 2015 was the second best performing but January 2014 performed poorly in comparison.
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    sale_period,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue,
    AVG(sellingprice) AS avg_selling_price,
    AVG(profit_margin) AS avg_profit_margin
FROM car_sales_clean
GROUP BY sale_period
ORDER BY total_revenue DESC;

--- Top 10 Sellers by Revenue
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    seller,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue,
    AVG(sellingprice) AS avg_selling_price,
    AVG(profit_margin) AS avg_profit_margin
FROM car_sales_clean
GROUP BY seller
ORDER BY total_revenue DESC
LIMIT 10;

--- Color Preference by Region
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    region,
    color,
    COUNT(*) AS units_sold
FROM car_sales_clean
GROUP BY region, color
ORDER BY region, units_sold DESC;


--- Make Performance by Region
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)SELECT
    region,
    make,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue,
    AVG(profit_margin) AS avg_profit_margin
FROM car_sales_clean
GROUP BY region, make
ORDER BY region, total_revenue DESC;

--------Black leads in both units sold and total revenue, white follows
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    color,
    COUNT(*) AS units_sold,
    SUM(total_revenue) AS total_revenue
FROM car_sales_clean
WHERE color != 'Unknown'
AND color != '—'
GROUP BY color
ORDER BY units_sold DESC;

------Relationship between price, mileage and year of manufacture
---- Year of manufacture is the strongest price driver, 2012 vehicle at low mileage sells for R20,554 while a 1998 vehicle at low mileage sells for only R4,013.
---Mileage accelerates depreciation significantly,  1997 vs 1998 — the 1998 at 30k–60k miles (R4,013) is nearly double the 1997 at 60k–100k miles (R1,849) despite being only one year newer. Mileage is compounding the age effect.
---High mileage old vehicles are near worthless, A 2001 vehicle with 150k+ miles sells for just R1,664 — barely worth stocking or selling.
WITH car_sales_clean AS(SELECT year,
       COALESCE(make, 'Unknown') AS make,
       COALESCE(model, 'Unknown') AS model,
       vin,
       state,
       condition,
       seller,
       mmr,
       sellingprice,
       saledate,
       COALESCE(body, 'Unknown') AS body,
       COALESCE(trim, 'Unknown') AS trim,
      
    COUNT(*) OVER (PARTITION BY make, model, saledate ) AS Units_Sold,
  
    sellingprice * COUNT(*) OVER (PARTITION BY make, model, saledate) AS Total_Revenue,

    ROUND(((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100, 2) AS Profit_Margin,

    CASE
           WHEN mmr IS NULL OR sellingprice IS NULL THEN 'Unknown'                                  
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 > 10 THEN 'High Margin'
           WHEN ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 >= 0 AND ((sellingprice - mmr) / NULLIF(sellingprice, 0)) * 100 <= 10 THEN 'Medium Margin'
           ELSE 'Low Margin'
    END AS Profit_margin_tier,

    CASE
        WHEN saledate IS NULL THEN 'Unknown'
        ELSE CONCAT(MONTHNAME(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')),' ',CAST(YEAR(TO_DATE(SUBSTRING(saledate, 5), 'MMM dd yyyy HH:mm:ss')) AS STRING))
    END AS sale_period,
    

    CASE
        WHEN transmission IS NULL THEN 'Unknown'
        WHEN transmission = 'automatic' THEN 'Automatic'
        WHEN transmission = 'manual' THEN 'Manual'
        ELSE transmission
    END AS transmission,

    CASE
        WHEN state IN ('ca', 'or', 'wa', 'nv', 'az') THEN 'West'
        WHEN state IN ('tx', 'ok', 'nm', 'co') THEN 'South West'
        WHEN state IN ('fl', 'ga', 'nc', 'sc', 'va') THEN 'South East'
        WHEN state IN ('ny', 'nj', 'pa', 'ma', 'ct') THEN 'North East'
        WHEN state IN ('il', 'oh', 'mi', 'mn', 'wi') THEN 'Mid West'
        ELSE 'Other'
    END AS region,

    CASE
        WHEN condition IS NULL THEN 'Unknown'
        WHEN condition > 0  AND condition <= 10 THEN 'Poor'
        WHEN condition > 10 AND condition <= 20 THEN 'Fair'
        WHEN condition > 20 AND condition <= 30 THEN 'Good'
        WHEN condition > 30 AND condition <= 40 THEN 'Very Good'
        WHEN condition > 40 AND condition <= 49 THEN 'Excellent'
        ELSE 'Unknown'
    END AS condition_bucket,

    CASE     
         WHEN odometer IS NULL THEN 'Unknown'                          
        WHEN odometer BETWEEN 0 AND 10000 THEN '0 - 10k'
        WHEN odometer > 10000 AND odometer <= 30000  THEN '10k - 30k'
        WHEN odometer > 30000 AND odometer <= 60000  THEN '30k - 60k'
        WHEN odometer > 60000 AND odometer <= 100000 THEN '60k - 100k'
        WHEN odometer > 100000 AND odometer <= 150000  THEN '100k - 150k'
        WHEN odometer > 150000 THEN '150k+'
        ELSE 'Unknown'
    END AS mileage_bucket,

    CASE
        WHEN interior IS NULL THEN 'Unknown'
        WHEN interior = '—'   THEN 'Unknown'
        ELSE interior
    END AS interior,

    
    CASE
        WHEN color IS NULL THEN 'Unknown'
        WHEN color = '—'   THEN 'Unknown'
        ELSE color
    END AS color
 
FROM `workspace`.`bright_car_sales`.`car_sales_data`)
SELECT
    year,
    mileage_bucket,
    COUNT(*) AS units_sold,
    ROUND(AVG(sellingprice), 2) AS avg_selling_price
FROM car_sales_clean
WHERE year IS NOT NULL
GROUP BY year, 
mileage_bucket
ORDER BY selling_price DESC;

# Car-Sales-Analysis
## Project Overview
Bright Motors is a vehicle dealership network that has recently appointed a new Head of Sales with a mandate to expand the dealership footprint, improve sales performance and optimise inventory management. To support this mission, a historical car sales dataset titled Bright Car Sales was provided for analysis. The dataset contains 558,811 transaction records spanning January 2014 to July 2015, capturing daily selling prices, vehicle details, mileage, condition scores, seller information and sale dates across multiple US states. 

## Aim
The aim of this project was to extract meaningful, data-driven insights from Bright Motors' historical car sales data and translate those insights into actionable strategic recommendations that will guide future decisions around sales performance, inventory acquisition, pricing strategy and regional expansion.

## Objectives
- Which car makes and models generate the most revenue
- The relationship between price, mileage, and year of manufacture
- Which regions or locations have the highest sales volumes
- Emerging trends in customer purchasing preferences
- Recommendations to increase dealership profitability and efficiency

## Data Processing
The raw dataset arrived as a semicolon-delimited CSV file with 16 columns. Before any analysis could be performed, significant cleaning and transformation work was required in Databricks SQL.
The first challenge was handling missing values(there is a lot of missing informaation). For categorical columns a CASE statement was used to replace nulls with 'Unknown'. COALESCE with the column average could be used to preserve the rows without distorting calculations in numeric columns. These null records were retained in the dataset and acknowledged as a data quality limitation. The 12 records with null selling price and MMR were specifically excluded from profit margin calculations since those columns are used directly in the formula and any substituted value would produce misleading results.

Several columns required in the analysis simply did not exist in the raw data. There was no units_sold column, so this was derived using a window function — COUNT(*) OVER (PARTITION BY make, model, saledate) — which counts how many times the same make and model appeared on the same sale date, treating each occurrence as one unit sold. There was no cost_price column, so the MMR (Manheim Market Report) value — which represents the estimated market value of each vehicle — was used as a proxy. There is no fuel_type column at all, so transmission could be as the closest available substitute. There was also no region column, so US states were mapped into five regions — West, North East, Mid West, South East and South West.
Several new derived columns were created to enrich the dataset.

## Key Insights
At the brand level, Ford emerged as the overall revenue leader with R42 billion in total revenue, followed by Nissan at R36.8 billion and Toyota at R17.5 billion. At the model level however, the Nissan Altima dominated with R24.6 billion — more than 2.6 times the second placed Infiniti G Sedan at R9.3 billion. The Altima achieved this through a high volume strategy, selling large numbers of units at competitive prices, while the Infiniti G Sedan relied on a value strategy — fewer units at a significantly higher average selling price. Notably both top models belong to the Nissan group, confirming strong brand ecosystem performance across both mainstream and premium price segments.

Regionally, the South East proved to be the highest revenue generating region at R51.6 billion, led by Nissan which generated R11.3 billion in that region alone. North East and Mid West followed closely at R36.8 billion and R36.6 billion respectively. The West, while only fourth overall, is distinctly a premium market — led by Infiniti at R5.6 billion and BMW at R5.2 billion rather than volume brands. The South West was the weakest region at R12 billion and presents the least immediate opportunity for expansion.

On body style, Sedan accounted for 63.6% of all units sold — 8,345,118 units — which is nearly four times the second placed SUV at 15.7%. Together, Sedan and SUV account for 79.3% of total units sold, making these two body styles the absolute core of Bright Motors' business. Pickup Truck (cabs) ranked third at 7.0%, a figure derived by consolidating multiple cab configurations from the raw data. Minivan and Coupe were minor segments at 3.8% and 3.2% respectively.

On transmission, automatic vehicles accounted for 87% of revenue while manual contributed just 1%. A concerning 12% fell under unknown transmission — a direct result of the 65,352 missing transmission records which represents a significant data quality gap.

The analysis of price against mileage and year of manufacture revealed a clear and consistent pattern. As mileage increases, average selling price decreases — from R22,859 for vehicles under 10,000 miles down to R3,255 for vehicles above 150,000 miles. Year of manufacture proved to be the single strongest price driver. A 2012 vehicle at low mileage commanded R20,554 while a comparable 1998 vehicle at similarly low mileage sold for only R4,013 — a five-fold difference driven purely by age. High mileage combined with old age produced the lowest values, with 2001 vehicles above 150,000 miles selling for as little as R1,664.

The profit margin analysis revealed a systemic pricing problem. Forty percent of all transactions were classified as Low Margin — meaning vehicles were sold below their MMR market value. Only 22% achieved High Margin status. This pattern held across every single mileage bucket, confirming that underpricing is not isolated to specific vehicle types but is a broad structural issue across the entire inventory.

## Tools Used
The data cleaning and transformation work was performed entirely in Databricks SQL. The processed data was exported to Microsoft Excel. The final presentation was built in Microsoft PowerPoint. Project Gantt chart - Canva and Project Planning Miro.

Please note the presentation is in pdf as the powerpoint is too large. 

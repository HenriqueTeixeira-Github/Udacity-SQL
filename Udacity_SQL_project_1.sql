-- PART 0

CREATE VIEW forestation AS
SELECT
  fa.country_code as country_code,
  fa.country_name as country,
  fa.year as year,
  fa.forest_area_sqkm as forest_area_sqkm,
  la.total_area_sq_mi*2.59 as total_area_sqkm,
  r.region as region,
  r.income_group as income_group,
  fa.forest_area_sqkm/(la.total_area_sq_mi*2.59) AS percent_forest
FROM forest_area AS fa
JOIN land_area AS la
ON fa.country_code = la.country_code AND fa.year = la.year
JOIN regions AS r
ON fa.country_code = r.country_code

-- PART 1

-- A) What was the total forest area (in sq km) of the world in 1990?
-- Please keep in mind that you can use the country record denoted as “World" in the region table.

SELECT
	region,
    year,
    forest_area_sqkm
FROM forestation
WHERE country = 'World' AND year = 1990

-- OK

-- B) What was the total forest area (in sq km) of the world in 2016?
-- Please keep in mind that you can use the country record denoted as “World" in the region table.

SELECT
	region,
    year,
    forest_area_sqkm
FROM forestation
WHERE country = 'World' AND year = 2016

-- OK

-- C) What was the change (in sq km) in the forest area of the world from 1990 to 2016?

SELECT
    country,
    year,
    forest_area_sqkm,
    LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) AS forest_area_sqkm_lead,
    forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) AS deforestation
FROM forestation
WHERE country = 'World' AND (year = 2016 OR year = 1990)

-- OK

-- D) What was the percent change in forest area of the world between 1990 and 2016?

SELECT
    country,
    year,
    percent_forest,
    LEAD(percent_forest) OVER (ORDER BY percent_forest DESC) AS percent_forest_lead,
    percent_forest - LEAD(percent_forest) OVER (ORDER BY percent_forest DESC) AS deforestation_percent
FROM forestation
WHERE country = 'World' AND (year = 2016 OR year = 1990)

-- E) If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?

WITH sub AS
    (SELECT
        country,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) AS deforestation
    FROM forestation
    WHERE country = 'World' AND (year = 2016 OR year = 1990)
    )

SELECT
    country,
    year,
    total_area_sqkm AS total_area_sqkm,
    ABS(total_area_sqkm - (SELECT MAX(deforestation) FROM sub)) as diff
FROM forestation
WHERE year = 2016
ORDER BY diff
LIMIT 1

-- OK

-- PART 2

-- Prep: Create a table that shows the Regions and their percent forest area (sum of forest area divided by sum of land area) in 1990 and 2016.
-- (Note that 1 sq mi = 2.59 sq km).

CREATE VIEW region_forestation AS
SELECT
    r.region as region,
    fa.year as year,
    SUM(fa.forest_area_sqkm) as forest_area_sqkm,
    SUM(la.total_area_sq_mi)*2.59 as total_area_sqkm,
    SUM(fa.forest_area_sqkm)/(SUM(la.total_area_sq_mi)*2.59) AS percent_forest
FROM forest_area AS fa
JOIN land_area AS la
ON fa.country_code = la.country_code AND fa.year = la.year
JOIN regions AS r
ON fa.country_code = r.country_code
GROUP BY 1,2
ORDER BY 1,2 DESC

-- A) What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?

-- What was the percent forest of the entire world in 2016? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region = 'World' AND year = 2016


-- Which region had the HIGHEST percent forest in 2016? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 2016
ORDER BY 3 DESC
LIMIT 1


-- Which region had the LOWEST percent forest in 2016? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 2016
ORDER BY 3
LIMIT 1


-- B) What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?

-- What was the percent forest of the entire world in 1990? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region = 'World' AND year = 1990


-- Which region had the HIGHEST percent forest in 1990? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 1990
ORDER BY 3 DESC
LIMIT 1


-- Which region had the LOWEST percent forest in 1990? (2 decimal places)
SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 1990
ORDER BY 3
LIMIT 1

-- C) Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?

WITH sub AS (
    SELECT
        region,
        year,
        percent_forest,
        LEAD(percent_forest) OVER (ORDER BY region, year DESC) AS percent_forest_lead,
        percent_forest - LEAD(percent_forest) OVER (ORDER BY region, year DESC) AS diff_percent_forest
    FROM region_forestation
    WHERE year IN (1990,2016)
    ORDER BY 1,2 DESC
)

SELECT
    region,
    percent_forest_lead::decimal(2,2) AS percent_forest_1990,
    percent_forest::decimal(2,2) AS percent_forest_2016,
    diff_percent_forest::decimal(2,2)
FROM sub
WHERE year = 2016
ORDER BY 4

-- PART 3

-- A) Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?

WITH sub AS (
    SELECT
        country,
        region,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_area_2016_1990
    FROM forestation
    WHERE
        country <> 'World' AND (year = 2016 OR year = 1990)
    ORDER BY 1,2 DESC
)

SELECT
    country,
    region,
    ABS(diff_forest_area_2016_1990) AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead > forest_area_sqkm AND
    (diff_forest_area_2016_1990 IS NOT NULL)
ORDER BY 3 DESC
LIMIT 5

-- A.2) Which 5 countries saw the largest amount increase in forest area from 1990 to 2016? What was the difference in forest area for each?

WITH sub AS (
    SELECT
        country,
        region,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_area_2016_1990
    FROM forestation
    WHERE
        country <> 'World' AND (year = 2016 OR year = 1990)
    ORDER BY 1,2 DESC
)

SELECT
    country,
    region,
    ABS(diff_forest_area_2016_1990) AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead < forest_area_sqkm AND
    diff_forest_area_2016_1990 IS NOT NULL
ORDER BY 3 DESC
LIMIT 5

-- B) Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?

WITH sub AS (
    SELECT
        country,
        region,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_area_2016_1990
    FROM forestation
    WHERE
        country <> 'World' AND (year = 2016 OR year = 1990)
    ORDER BY 1,2 DESC
)

SELECT
    country,
    region,
    ABS(diff_forest_area_2016_1990)/forest_area_sqkm_lead AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead > forest_area_sqkm AND
    (diff_forest_area_2016_1990 IS NOT NULL)
ORDER BY 3 DESC
LIMIT 5

-- B) Which 5 countries saw the largest percent increase in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?

WITH sub AS (
    SELECT
        country,
        region,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_area_2016_1990
    FROM forestation
    WHERE
        country <> 'World' AND (year = 2016 OR year = 1990)
    ORDER BY 1,2 DESC
)

SELECT
    country,
    region,
    ABS(diff_forest_area_2016_1990)/forest_area_sqkm_lead AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead < forest_area_sqkm AND
    (diff_forest_area_2016_1990 IS NOT NULL)
ORDER BY 3 DESC
LIMIT 5

-- C) If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?

WITH sub AS (
    SELECT
        country,
        percent_forest,
        CASE
            WHEN percent_forest >= 0 AND percent_forest <= 0.25 THEN '0%-25%'
            WHEN percent_forest > 0.25 AND percent_forest <= 0.50 THEN '25%-50%'
            WHEN percent_forest > 0.50 AND percent_forest <= 0.75 THEN '50%-75%'
            WHEN percent_forest > 0.75 AND percent_forest <= 1 THEN '75%-100%'
        END AS group_quartiles
    FROM forestation
    WHERE
        country <> 'World' AND
        year = 2016 AND
        percent_forest IS NOT NULL
)

SELECT
    group_quartiles,
    COUNT(*) AS num_country
FROM sub
GROUP BY 1
ORDER BY 1


-- D) List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.

WITH sub AS (
    SELECT
        country,
        region,
        percent_forest,
        CASE
            WHEN percent_forest >= 0 AND percent_forest <= 0.25 THEN '0%-25%'
            WHEN percent_forest > 0.25 AND percent_forest <= 0.50 THEN '25%-50%'
            WHEN percent_forest > 0.50 AND percent_forest <= 0.75 THEN '50%-75%'
            WHEN percent_forest > 0.75 AND percent_forest <= 1 THEN '75%-100%'
        END AS group_quartiles
    FROM forestation
    WHERE
        country <> 'World' AND
        year = 2016 AND
        percent_forest IS NOT NULL
)

SELECT
    *
FROM sub
WHERE group_quartiles = '75%-100%'
ORDER BY 3 DESC

-- E) How many countries had a percent forestation higher than the United States in 2016?

SELECT
    COUNT(*) AS num_countries
FROM forestation
WHERE
    year = 2016 AND
    percent_forest IS NOT NULL AND
    percent_forest >
        (SELECT
            percent_forest
        FROM forestation
        WHERE
            country = 'United States' AND
            year = 2016
        )

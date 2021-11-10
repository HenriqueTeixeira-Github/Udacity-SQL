-- PART 0 - Create a View called “forestation” by joining all three tables

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

-- B) What was the total forest area (in sq km) of the world in 2016?
-- Please keep in mind that you can use the country record denoted as “World" in the region table.

SELECT
    region,
    year,
    forest_area_sqkm
FROM forestation
WHERE country = 'World' AND year = 2016

-- C) What was the change (in sq km) in the forest area of the world from 1990 to 2016?

WITH sub AS (
    SELECT
        country,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) AS forest_area_sqkm_lead,
        LEAD(forest_area_sqkm) OVER (ORDER BY forest_area_sqkm DESC) - forest_area_sqkm AS diff_forest_2016_1990
    FROM forestation
    WHERE country = 'World' AND (year = 2016 OR year = 1990)
    )
SELECT
    country,
    forest_area_sqkm AS forest_area_sqkm_1990,
    forest_area_sqkm_lead AS forest_area_sqkm_2016,
    diff_forest_2016_1990
FROM sub
LIMIT 1

-- D) What was the percent change in forest area of the world between 1990 and 2016?

WITH sub AS (
    SELECT
        country,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) - forest_area_sqkm AS diff_forest_2016_1990
    FROM forestation
    WHERE country = 'World' AND (year = 2016 OR year = 1990)
    )
SELECT
    country,
    forest_area_sqkm AS forest_area_sqkm_1990,
    forest_area_sqkm_lead AS forest_area_sqkm_2016,
    (forest_area_sqkm_lead - forest_area_sqkm)/forest_area_sqkm AS percent_change_forest
FROM sub
LIMIT 1

-- E) If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?

WITH sub AS
    (SELECT
        country,
        year,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS deforestation
    FROM forestation
    WHERE country = 'World' AND (year = 2016 OR year = 1990)
    )
SELECT
    country,
    year,
    total_area_sqkm::decimal(12,2) AS total_area_sqkm,
    (ABS(total_area_sqkm - ABS((SELECT MAX(deforestation) FROM sub))))::decimal(12,2) as difference_total_area
FROM forestation
WHERE year = 2016
ORDER BY 4
LIMIT 1

-- PART 2
-- Prep: Create a table that shows the Regions and their percent forest area (sum of forest area divided by sum of land area) in 1990 and 2016.
-- (Note that 1 sq mi = 2.59 sq km).

-- Cleanning process to sum only the countries that have data for forest_area_sqkm and total_area_sqkm in both years (1990 and 2016).

CREATE VIEW region_forestation AS
    WITH forestation_clean AS (
        SELECT
            *
        FROM forestation
        WHERE
            year IN (1990, 2016) AND
            country NOT IN (
            SELECT DISTINCT
                country
                FROM forestation
            WHERE
                year IN (1990, 2016) AND
                (forest_area_sqkm IS NULL OR total_area_sqkm IS NULL)
            )
    )
    SELECT
        region,
        year,
        SUM(forest_area_sqkm) as forest_area_sqkm,
        SUM(total_area_sqkm) as total_area_sqkm,
        SUM(forest_area_sqkm)/SUM(total_area_sqkm) AS percent_forest
    FROM forestation_clean
    GROUP BY 1,2
    ORDER BY 1,2 DESC



-- A) What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?

-- A.1) What was the percent forest of the entire world in 2016? (2 decimal places)

SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region = 'World' AND year = 2016


-- A.2) Which region had the HIGHEST percent forest in 2016? (2 decimal places)

SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 2016
ORDER BY 3 DESC
LIMIT 1


-- A.3) Which region had the LOWEST percent forest in 2016? (2 decimal places)

SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 2016
ORDER BY 3
LIMIT 1

-- B) What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?

-- B.1) What was the percent forest of the entire world in 1990? (2 decimal places)

SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region = 'World' AND year = 1990


-- B.2) Which region had the HIGHEST percent forest in 1990? (2 decimal places)

SELECT
    region,
    year,
    percent_forest::decimal(2,2)
FROM region_forestation
WHERE region <> 'World' AND year = 1990
ORDER BY 3 DESC
LIMIT 1


-- B.3) Which region had the LOWEST percent forest in 1990? (2 decimal places)

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
WHERE year = 2016 AND region <> 'World'
ORDER BY 3 DESC

-- PART 3

-- A) Which 5 countries saw the largest amount DECREASE in forest area from 1990 to 2016? What was the difference in forest area for each?

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
    ABS(diff_forest_area_2016_1990)::decimal(10,2) AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead > forest_area_sqkm AND
    (diff_forest_area_2016_1990 IS NOT NULL)
ORDER BY 3 DESC
LIMIT 5

-- A.2) Which 5 countries saw the largest amount INCREASE in forest area from 1990 to 2016? What was the difference in forest area for each?

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
    ABS(diff_forest_area_2016_1990)::decimal(10,2) AS Foreste_Area_Amount_Decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead < forest_area_sqkm AND
    diff_forest_area_2016_1990 IS NOT NULL
ORDER BY 3 DESC
LIMIT 5

-- B) Which 5 countries saw the largest percent DECREASE in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?

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
    (ABS(diff_forest_area_2016_1990)/forest_area_sqkm_lead)::decimal(2,2) AS foreste_area_amount_decrease
FROM sub
WHERE
    year = 2016 AND
    forest_area_sqkm_lead > forest_area_sqkm AND
    (diff_forest_area_2016_1990 IS NOT NULL)
ORDER BY 3 DESC
LIMIT 5

-- B.2) Which 5 countries saw the largest percent INCREASE in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?

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
    (ABS(diff_forest_area_2016_1990)/forest_area_sqkm_lead)::decimal(5,2) AS foreste_area_amount_increase
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
        percent_forest::decimal(2,2),
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

-- PART 4 - RECOMMENDATIONS

-- We should take the deforestation situation seriously. Nowadays, 41,67% of the countries analyzed are in the lowest quartile for percentage percentage and we have one entire region with just 2% of their area with forest.
-- Keeping losing 3,21% of forest every 26 years it is not a great deal for for humanity. We should look in what China has changed to increase so much its forest area between 1990 and 2016. Maybe these changes could help Brazil (a country with similar land area) to recover the area that it has lost.
-- It also important to take a deeper look in the countries in the Sub-Saharan Africa to understand why 4 of the 5 countries are in the "Top 5 Percent Decrease in Forest Area".

-- When you use the income groups to look even further in the situation, it is possible to verify that we should pay attention to the countries with "Low income". None of them are listed in the fourth quartile (75%-100%) for forest percentage when we separated by income groups.
-- This situation becomes even worst when you realize that most of than (26 of 32) decreased their forest area from 1990 to 2016. On the other hand, when you look to the countries with "high income",
-- you realize that most of than (38 of 71) increased their forest area. Maybe some financial  support for those countries with "low income" could make some positive difference.

-- Extra queries

-- 4.1) If countries were grouped by percent forestation in quartiles, how many countries it would have in each group per income_group?

WITH sub AS (
    SELECT
        country,
        region,
        income_group,
        percent_forest::decimal(2,2),
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
    CASE
        WHEN income_group = 'High income' THEN '1. High income'
        WHEN income_group = 'Upper middle income' THEN '2. Upper middle income'
        WHEN income_group = 'Lower middle income' THEN '3. Lower middle income'
        WHEN income_group = 'Low income' THEN '4. Low income'
    END AS income_group_sort,
    group_quartiles,
    COUNT(*) AS num_countries
FROM sub
GROUP BY 1,2
ORDER BY 1,2

-- B) If countries were grouped by percent change, how many countries it would have in each group per income_group.


WITH sub AS (
    SELECT
        country,
        year,
        income_group,
        forest_area_sqkm,
        LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
        forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_2016_1990,
        (forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC))/LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS percent_change
    FROM forestation
    WHERE
        country <> 'World' AND (year = 2016 OR year = 1990)
    ORDER BY 1
    )

SELECT
    CASE
        WHEN income_group = 'High income' THEN '1. High income'
        WHEN income_group = 'Upper middle income' THEN '2. Upper middle income'
        WHEN income_group = 'Lower middle income' THEN '3. Lower middle income'
        WHEN income_group = 'Low income' THEN '4. Low income'
    END AS income_group_sort,
    CASE
        WHEN percent_change > 0 THEN '1. INCREASED'
        WHEN percent_change = 0 THEN '2. SAME'
        WHEN percent_change < 0 THEN '3. DECREASED'
    END AS percent_change_status,
    COUNT(*)
FROM sub
WHERE year = 2016 AND diff_forest_2016_1990 IS NOT NULL
GROUP BY 1,2

-- -- C) What is the average of forest change for the countries that increased for each income group?
--
-- WITH sub AS (
--     SELECT
--         country,
--         year,
--         income_group,
--         forest_area_sqkm,
--         LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
--         forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_2016_1990,
--         (forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC))/LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS percent_change
--     FROM forestation
--     WHERE
--         country <> 'World' AND (year = 2016 OR year = 1990)
--     ORDER BY 1
--     )
--
-- SELECT
--     income_group,
--     AVG(diff_forest_2016_1990)::decimal(9,2) AS forest_change_increase
-- FROM sub
-- WHERE
--     year = 2016 AND
--     percent_change > 0 -- INCREASED
-- GROUP BY 1
-- ORDER BY 2 DESC
--
-- -- D) What is the average of forest change for the countries that decreased for each income group?
--
-- WITH sub AS (
--     SELECT
--         country,
--         year,
--         income_group,
--         forest_area_sqkm,
--         LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS forest_area_sqkm_lead,
--         forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS diff_forest_2016_1990,
--         (forest_area_sqkm - LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC))/LEAD(forest_area_sqkm) OVER (ORDER BY country, year DESC) AS percent_change
--     FROM forestation
--     WHERE
--         country <> 'World' AND (year = 2016 OR year = 1990)
--     ORDER BY 1
--     )
--
-- SELECT
--     income_group,
--     ABS(AVG(diff_forest_2016_1990))::decimal(9,2) AS forest_change_decrease
-- FROM sub
-- WHERE
--     year = 2016 AND
--     percent_change < 0 -- DECREASED
-- GROUP BY 1
-- ORDER BY 2 DESC

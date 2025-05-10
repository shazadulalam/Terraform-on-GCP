CREATE OR REPLACE TABLE `{PROJECT_ID}.{DATASET_ID}.daily_covid_summary`
AS
SELECT
  country_region,
  date,
  SUM(confirmed) AS total_confirmed,
  SUM(deaths) AS total_deaths,
  SUM(recovered) AS total_recovered
FROM
  `bigquery-public-data.covid19_jhu_csse.summary`
GROUP BY
  1, 2
ORDER BY
  2 DESC;
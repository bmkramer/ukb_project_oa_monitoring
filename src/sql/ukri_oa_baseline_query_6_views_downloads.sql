---------------------------------
--- Views and downloads
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi,

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),

--- STEP 1B - Aggregate usage counts from IRUS_UK (collected separately through web UI)
--- Usage metrics were collected through IRUS_UK web UI, for all items with type 'article' in repositories included in IRUS_UK which saw at least one type of usage (views or downloads) in the period Jan-Dec 2023
--- Counts are per repository item, so need to be aggregated by DOI (as the same DOI can be included in multiple repositories)

TABLE_IRUS_AGG AS

(SELECT

UPPER(DOI) as DOI,
SUM(IF(Metric_Type = "Unique_Item_Requests", Reporting_Period_Total, 0)) as unique_item_requests_sum,
SUM(IF(Metric_Type = "Unique_Item_Investigations", Reporting_Period_Total, 0)) as unique_item_investigations_sum,

FROM `ukri-oa-baseline.supplementary_sources.irus_uk_dois_20240303`
WHERE Item_Type = "Article" AND DOI is not null

GROUP BY DOI
),


--- STEP 1C - Add aggregated usage counts to DOIs in corpus

TABLE_JOIN AS (

SELECT

a.*,
b.unique_item_Requests_sum,
b.unique_item_Investigations_sum,


FROM TABLE_DOIS as a
LEFT JOIN TABLE_IRUS_AGG as b
ON UPPER(TRIM(a.doi)) = UPPER(TRIM(b.DOI))

)


SELECT * FROM TABLE_JOIN

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_views_downloads`
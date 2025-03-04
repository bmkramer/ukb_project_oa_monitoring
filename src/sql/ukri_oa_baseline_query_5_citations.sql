---------------------------------
--- Citations
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi,
openalex_id

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),

--- STEP 1B - Collect citation counts from OpenAlex

TABLE_CITATIONS AS (

SELECT

a.doi,
b.cited_by_count

FROM TABLE_DOIS as a
LEFT JOIN `academic-observatory.openalex_snapshot.works20231018` as b
ON a.openalex_id = b.id

)

SELECT * FROM TABLE_CITATIONS

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_citations`
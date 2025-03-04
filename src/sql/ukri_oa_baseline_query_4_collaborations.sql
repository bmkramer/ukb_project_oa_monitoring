---------------------------------
--- Collaborations
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi,
openalex_id

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),

--- STEP 1B - Collect information on number of affiliated institutions and number of affiliated countries from OpenAlex
--- first, collect RORs and country codes for each author affiliation
--- second, count number of distinct RORs and countries per publication

--- NB OpenAlex also contains record-level variables countries_distinct_count and institutions_distinct_count which could be used directly in a future iteration

TABLE_OPENALEX_RAW AS (

SELECT

a.id,
institution.ror as aff_ror,
institution.country_code as aff_country_code

FROM `academic-observatory.openalex_snapshot.works20231018` as a
LEFT JOIN UNNEST (authorships) as authorship, UNNEST (institutions) as institution

),

TABLE_OPENALEX_COUNT AS (

SELECT DISTINCT

id,
count(distinct aff_ror) as aff_ror_distinct,
count(distinct aff_country_code) as aff_country_distinct

FROM TABLE_OPENALEX_RAW
GROUP BY id

),

---- STEP 1C - Add OpenAlex counts to DOIs in corpus (using OpenAlex IDs)
TABLE_JOIN AS (

SELECT

a.doi,
b.aff_ror_distinct,
b.aff_country_distinct,


FROM TABLE_DOIS as a
LEFT JOIN TABLE_OPENALEX_COUNT as b
ON a.openalex_id = b.id

),

---- STEP 1D - Create collaboration classification
TABLE_COLLAB AS (

SELECT
*,
if(aff_ror_distinct = 1, true, false) as collab_single,
if(aff_ror_distinct > 1, true, false) as collab_multiple,
if(aff_country_distinct > 1, true, false) as collab_international

FROM TABLE_JOIN
)

SELECT * FROM TABLE_COLLAB


--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_collaborations`

---------------------------------
--- Fields
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi,
openalex_id

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),

--- STEP 1B - Collect field information from OpenAlex
--- The current reporting used the entity 'concepts' at top level (n=19) 
--- For future iterations, the entity 'topics' can be used instead, either at top level 'domain' (n=4), or one level below 'fields' (n=26) 

TABLE_FIELDS AS (

SELECT

a.id,
c.display_name as field,
c.level as level


FROM `academic-observatory.openalex_snapshot.works20231018` as a,
UNNEST(concepts) as c
WHERE c.level = 0

),


--- STEP 1C - Aggregate field information from OpenAlex
--- Publications can have multiple level 0 concepts. Aggregate these into array (for use in downstrea analysis) and string (for inclusion in flat dataset file (csv))

TABLE_FIELDS_AGG AS (

SELECT

id,
ARRAY_AGG(field) as fields_array,
STRING_AGG(field) as fields_string

FROM TABLE_FIELDS
GROUP BY id

),

TABLE_JOIN AS (
SELECT

a.*,
b.fields_array,
b.fields_string

FROM TABLE_DOIS as a
LEFT JOIN TABLE_FIELDS_AGG as b
ON a.openalex_id = b.id

)

SELECT * FROM TABLE_JOIN

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_fields`
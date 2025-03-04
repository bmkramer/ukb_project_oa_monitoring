---------------------------------
--- Publishers
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),


--- STEP 1B - Join publisher data from Crossref
--- member ID is taken directly from Crossref metadata
--- publisher names are taken from custom table of member IDs and publisher names, created separately through Crossref member route API
--- publisher names in Crossref metadata are not harmonized, publisher names linked to member ID are harmonized

TABLE_PUBLISHERS AS (

SELECT

a.*,
b.member as member_id,
c.member_primary_name as publisher

FROM TABLE_DOIS as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20231031` as b
ON UPPER(TRIM(a.doi)) = UPPER(TRIM(b.DOI))
LEFT JOIN `ukri-oa-baseline.supplementary_sources.crossref_member_data_20240123` as c --- <- HERE
ON b.member = c.member_id

)

SELECT * FROM TABLE_PUBLISHERS

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_oa_publisher`
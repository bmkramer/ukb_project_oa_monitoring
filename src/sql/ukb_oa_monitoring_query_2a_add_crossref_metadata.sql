---------------------------------
--- Add bibliographic data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 2A - Add Crossref metadata
--------------------------------------------------------------------------------------


--- collect type, issued_year and created_date from Crossref
WITH TABLE_CROSSREF AS (

SELECT

a.doi_cleaned,
a.org_agg,
a.kuoz_a,
STRUCT(
if(b.doi is not null, true,false) as cr_included,
b.type as cr_type,
IF(ARRAY_LENGTH(b.issued.date_parts) > 0, b.issued.date_parts[offset(0)], null) as cr_issued_year,
EXTRACT(YEAR FROM b.created.date_time) as cr_created_year,
EXTRACT(DATE FROM b.created.date_time) as cr_created_date
) as crossref

FROM `UKB_OA_2023.all_2023_dois_instance` as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20240731` as b
ON UPPER(a.doi_cleaned) = UPPER(b.doi)

)

SELECT * FROM TABLE_CROSSREF

--- saved as `UKB_OA.all_2023_dois_crossref`
---------------------------------
--- Create export datasets
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 5E - Create full export table for public sharing
--------------------------------------------------------------------------------------


--- ungroup instance variables and create comma-separated strings
--- only include instance variables included in final export table

WITH TABLE AS (
SELECT

*

FROM `utrecht-university.UKB_OA_2023.all_2023_export_base_table_orgs` 

),

--- create array of each instance variable to be included in export table
TABLE_INSTANCE_ARRAY AS (

SELECT

doi_cleaned,
ARRAY(SELECT org_agg FROM UNNEST(instance)) as org_agg,
ARRAY(SELECT org_name FROM UNNEST(instance)) as org_name,
ARRAY(SELECT org_ror FROM UNNEST(instance)) as org_ror,
ARRAY(SELECT umc FROM UNNEST(instance)) as umc,
--- for variables that can include nulls, replace null with 'null' as string
ARRAY(SELECT IFNULL(kuoz, 'null') FROM UNNEST(instance)) as kuoz,
ARRAY(SELECT IFNULL(taverne, 'null') FROM UNNEST(instance)) as taverne

FROM TABLE

),

TABLE_INSTANCE_STRING AS (

SELECT

doi_cleaned,
ARRAY_TO_STRING(org_agg, ",") as org_agg,
ARRAY_TO_STRING(org_name, ",") as org_name,
ARRAY_TO_STRING(org_ror , ",") as org_ror,
ARRAY_TO_STRING(umc, ",") as umc,
ARRAY_TO_STRING(kuoz, ",") as kuoz,
ARRAY_TO_STRING(taverne, ",") as taverne

FROM TABLE_INSTANCE_ARRAY

),

TABLE_JOIN AS (

SELECT 
a.doi_cleaned,
b.* EXCEPT (doi_cleaned),
a.* EXCEPT (doi_cleaned, instance)

FROM TABLE as a
LEFT JOIN TABLE_INSTANCE_STRING as b
USING(doi_cleaned)

),

--- only keep records classified as KUOZ-A by at least one organization and with Crossref DOI
TABLE_SELECT AS (

SELECT

* 

FROM TABLE_JOIN
WHERE kuoz_a is true AND cr_included is true 


)


SELECT * FROM TABLE_SELECT
ORDER BY doi_cleaned

--- saved as `UKB_OA_2023.all_2023_export_table_full`

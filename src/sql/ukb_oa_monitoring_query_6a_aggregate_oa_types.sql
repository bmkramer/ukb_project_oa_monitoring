---------------------------------
--- Create aggregated data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 6A - Aggregated data - OA types 
--------------------------------------------------------------------------------------


--- select variables, filter to records in scope
WITH TABLE AS (
SELECT

doi_cleaned,
org_agg,
cr_included,
upw_included,
oa_type

FROM `UKB_OA_2023.all_2023_dois_oa_information`
WHERE kuoz_a is true AND cr_included is true AND oa_type.oa_type_extended is not null

),

--- calculate total aggregated OA values 
TABLE_AGG_OA_EXT AS (

SELECT

oa_type.oa_type_extended,
count(distinct doi_cleaned)

FROM TABLE, UNNEST (org_agg) as org_agg
WHERE NOT org_agg = 'uvh'

GROUP BY oa_type_extended

),

TABLE_AGG_OA_COMPACT AS (

SELECT

oa_type.oa_type_compact,
count(distinct doi_cleaned)

FROM TABLE, UNNEST (org_agg) as org_agg
WHERE NOT org_agg = 'uvh'

GROUP BY oa_type_compact

),

--- calculate total aggregated OA values by institution
TABLE_AGG_ORG_OA_EXT AS (

SELECT

org_agg,
count(distinct doi_cleaned) as dois,
count(distinct if (oa_type.oa_type_extended = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if (oa_type.oa_type_extended = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if (oa_type.oa_type_extended = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if (oa_type.oa_type_extended = "hybrid", doi_cleaned, null)) as hybrid,
count(distinct if (oa_type.oa_type_extended = "bronze_only", doi_cleaned, null)) as bronze_only,
count(distinct if (oa_type.oa_type_extended = "bronze_green_acc_pub", doi_cleaned, null)) as bronze_green_acc_pub,
count(distinct if (oa_type.oa_type_extended = "green_sub_only", doi_cleaned, null)) as green_sub_only,
count(distinct if (oa_type.oa_type_extended = "green_acc_pub_only_no_bronze", doi_cleaned, null)) as green_acc_pub_only_no_bronze,
count(distinct if (oa_type.oa_type_extended = "closed", doi_cleaned, null)) as closed

FROM TABLE,
UNNEST(org_agg) as org_agg

GROUP BY org_agg
ORDER BY org_agg

),

TABLE_AGG_ORG_OA_COMPACT AS (

SELECT

org_agg,
count(distinct doi_cleaned) as dois,
count(distinct if (oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if (oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if (oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if (oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid,
count(distinct if (oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only,
count(distinct if (oa_type.oa_type_compact = "non oa", doi_cleaned, null)) as non_oa

FROM TABLE,
UNNEST(org_agg) as org_agg

GROUP BY org_agg
ORDER BY org_agg

)

--- select relevant table to save/export

SELECT * FROM TABLE_AGG_OA_EXT
---SELECT * FROM TABLE_AGG_OA_COMPACT

---SELECT * FROM TABLE_AGG_ORG_OA_EXT
---SELECT * FROM TABLE_AGG_ORG_OA_COMPACT

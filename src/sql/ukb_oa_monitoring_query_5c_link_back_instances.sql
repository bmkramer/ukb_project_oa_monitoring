---------------------------------
--- Create export datasets
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 5C - Ungroup instances, link back to original instance data  
--------------------------------------------------------------------------------------

---- create helper variable with NULL replaced by "null" for joining on original doi

WITH TABLE_INSTANCE AS (

SELECT
IFNULL(doi, "null") as doi_match,
*
FROM `UKB_OA_2023.all_2023_instance`

),

TABLE_EXPORT AS (

SELECT

IFNULL(doi, "null") as doi_match,
* EXCEPT (instance)

FROM `UKB_OA_2023.all_2023_export_base_table_orgs` ,
UNNEST (instance)

),

TABLE_JOIN AS (

SELECT

a.uuid_unique, a.org_agg, a.uuid, a.umc, a.org_name, a.org_ror, a.doi, a.hoop, a.kuoz, a.taverne, a.funding, a.corresponding,

b.* EXCEPT (uuid_unique, org_agg, uuid, umc, org_name, org_ror, doi, hoop, kuoz, taverne, funding, corresponding, doi_match)


FROM TABLE_INSTANCE as a
LEFT JOIN TABLE_EXPORT as b

USING (uuid_unique, uuid, umc, org_name, org_ror, doi_match)

)

SELECT * FROM TABLE_JOIN



--- saved as `UKB_OA_2023.all_2023_export_base_table_orgs_linked_og_data`
---- n = equal to `UKB_OA_2023.all_2023_instance`
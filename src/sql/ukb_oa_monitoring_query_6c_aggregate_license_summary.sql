---------------------------------
--- Create aggregated data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 6C - Aggregated data - license summary
--------------------------------------------------------------------------------------

--- NB Counts are exclusive counts (i.e. each doi has one license value, and has_license does not include has_license_cc etc)


--- select variables, filter to records in scope
WITH TABLE AS (
SELECT

doi_cleaned,
org_agg,
oa_type,

FROM `UKB_OA_2023.all_2023_dois_oa_information`
WHERE kuoz_a is true AND cr_included is true AND oa_type.oa_type_extended is not null

),

--- join to table with license summary information
TABLE_JOIN AS (

SELECT

a.*,
b.* EXCEPT (doi_cleaned)

FROM TABLE as a
LEFT JOIN `UKB_OA_2023.all_2023_dois_license` as b
ON a.doi_cleaned = b.doi_cleaned
),

--- calculate publisher licenses for gold and hybrid OA
TABLE_AGG_PUBLISHER AS (

SELECT

IFNULL(oa_license.publisher_license, "null") as license, -- temporary conversion to allow left join on 'null'
---count(doi_cleaned) as count,
---count(distinct doi_cleaned) as count_distinct_publisher,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if(oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if(oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid


FROM TABLE_JOIN, UNNEST (org_agg) as org_agg
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

--- calculate repository licenses for green OA
TABLE_AGG_GREEN_ACC_PUB AS (

SELECT

IFNULL(oa_license.repository_acc_pub_license, "null") as license,

---count(doi_cleaned) as count,
---count(distinct doi_cleaned) as count_distinct_green_acc_pub,
count(distinct if(oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only,


FROM TABLE_JOIN, UNNEST (org_agg) as org_agg
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

TABLE_AGG_JOIN AS (

SELECT

a.*,
b.* EXCEPT (license)

FROM TABLE_AGG_PUBLISHER as a
FULL JOIN TABLE_AGG_GREEN_ACC_PUB as b
USING (license)

),

--- convert 'null' back to real nulls
TABLE_AGG_JOIN_NULLS AS (

SELECT
NULLIF(license, "null") as license,
* EXCEPT (license)

FROM TABLE_AGG_JOIN

ORDER BY license

)

SELECT * FROM TABLE_AGG_JOIN_NULLS

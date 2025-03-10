---------------------------------
--- Create aggregated data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 6B - Aggregated data - licenses
--------------------------------------------------------------------------------------

--- NB Counts are non-exclusive counts (i.e. a doi can have multiple licenses if there are multiple OA versions)

--- select variables, filter to records in scope
WITH TABLE AS (
SELECT

doi_cleaned,
org_agg,
oa_type

FROM `UKB_OA_2023.all_2023_dois_oa_information`
WHERE kuoz_a is true AND cr_included is true AND oa_type.oa_type_extended is not null

),

--- select publisher licenses for gold and hybrid OA
TABLE_LICENSE_PUBLISHER AS (
SELECT

doi_cleaned,
l.license

FROM `UKB_OA_2023.all_2023_dois_unpaywall` as b,
UNNEST (unpaywall.oa_locations) as l
WHERE l.host_type = "publisher" AND l.version = "publishedVersion"
),

--- select repository licenses for green OA
TABLE_LICENSE_GREEN_ACC_PUB AS (
SELECT

doi_cleaned,
l.license

FROM `UKB_OA_2023.all_2023_dois_unpaywall` as b,
UNNEST (unpaywall.oa_locations) as l
WHERE l.host_type = "repository" AND l.version IN ('publishedVersion', 'acceptedVersion')
),

--- add publisher and green licenses to base variables for downstream aggregation
TABLE_LICENSE_JOIN AS (

SELECT

a.*,
b.license as license_publisher,
c.license as license_green_acc_pub

FROM TABLE AS a
LEFT JOIN TABLE_LICENSE_PUBLISHER as b
USING (doi_cleaned)
LEFT JOIN TABLE_LICENSE_GREEN_ACC_PUB as c
USING (doi_cleaned)

),

--- calculate publisher licenses for gold and hybrid OA
TABLE_AGG_PUBLISHER AS (

SELECT

IFNULL(license_publisher, "null") as license, -- temporary conversion to allow left join on 'null'
---count(doi_cleaned) as count,
---count(distinct doi_cleaned) as count_distinct_publisher,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if(oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if(oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid


FROM TABLE_LICENSE_JOIN, UNNEST (org_agg) as org_agg
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

--- calculate repository licenses for green OA
TABLE_AGG_GREEN_ACC_PUB AS (

SELECT

IFNULL(license_green_acc_pub, "null") as license,

---count(doi_cleaned) as count,
---count(distinct doi_cleaned) as count_distinct_green_acc_pub,
count(distinct if(oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only,


FROM TABLE_LICENSE_JOIN, UNNEST (org_agg) as org_agg
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

ORDER BY hybrid DESC NULLS LAST --- order by hybrid as most populated - gives most useful ordering of licenses

)

SELECT * FROM TABLE_AGG_JOIN_NULLS
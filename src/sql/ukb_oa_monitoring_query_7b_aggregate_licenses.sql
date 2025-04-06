---------------------------------------------------
--- Create aggregated data - from structured table
---------------------------------------------------

--------------------------------------------------------------------------------------
--- STEP 6B - Aggregated data - licenses
--------------------------------------------------------------------------------------

--- NB Counts are non-exclusive counts (i.e. a doi can have multiple licenses if there are multiple OA versions)

--- import flat table
WITH TABLE_IMPORT AS (

SELECT

doi as doi_cleaned, --- to match script template
* EXCEPT (doi)

FROM `utrecht-university.UKB_OA_2023.all_2023_export_table_full`

),

--- create structured base table with selected variables
TABLE_BASE AS (
  
SELECT 

doi_cleaned,
SPLIT(org_agg, ",") as org_agg,
STRUCT(oa_type_compact, oa_type_extended) as oa_type,
STRUCT(publisher_license, repository_acc_pub_license) as oa_license

 FROM TABLE_IMPORT

),


--- transform selected variables from comma-separated string into separate rows for each oa_location
TABLE_OA_LOCATIONS_UNNEST AS (

SELECT 

a.doi_cleaned,
b.host_type,
c.version,
d.license

FROM TABLE_IMPORT as a
LEFT JOIN (SELECT doi_cleaned, host_type, offset FROM TABLE_IMPORT, UNNEST(SPLIT(host_type, ",") ) as host_type WITH OFFSET AS offset ORDER BY offset) as b
USING (doi_cleaned)
LEFT JOIN (SELECT doi_cleaned, version, offset FROM TABLE_IMPORT, UNNEST(SPLIT(version, ",") ) as version WITH OFFSET AS offset ORDER BY offset) as c
USING (doi_cleaned, offset)
LEFT JOIN (SELECT doi_cleaned, license, offset FROM TABLE_IMPORT, UNNEST(SPLIT(license, ",") ) as license WITH OFFSET AS offset ORDER BY offset) as d
USING (doi_cleaned, offset)

),

--- combine all oa location variables into one structured variable 
TABLE_OA_LOCATIONS_STRUCT AS (

SELECT 

doi_cleaned,
ARRAY_AGG(STRUCT(
host_type,
version,
license
)) as oa_locations

FROM TABLE_OA_LOCATIONS_UNNEST
GROUP BY doi_cleaned

),

--- join all variables to create structured base table
TABLE_BASE_COMBINE AS (

SELECT

a.*,
b.oa_locations

FROM TABLE_BASE as a
LEFT JOIN TABLE_OA_LOCATIONS_STRUCT as b
USING (doi_cleaned)

),

-------------------------------------------------------------------------------
---- remainder of script reuses SQL script 6b on reconstructed structured table
-------------------------------------------------------------------------------

--- select variables, filter to records in scope
TABLE AS (
SELECT

doi_cleaned,
org_agg,
oa_type

FROM TABLE_BASE_COMBINE,
UNNEST(org_agg) as org_agg
WHERE oa_type.oa_type_extended is not null

),

--- select publisher licenses for gold and hybrid OA
TABLE_LICENSE_PUBLISHER AS (
SELECT

doi_cleaned,
l.license

FROM TABLE_BASE_COMBINE as b,
UNNEST (oa_locations) as l
WHERE l.host_type = "publisher" AND l.version = "publishedVersion"
),

--- select repository licenses for green OA
TABLE_LICENSE_GREEN_ACC_PUB AS (
SELECT

doi_cleaned,
l.license

FROM TABLE_BASE_COMBINE as b,
UNNEST (oa_locations) as l
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
count(distinct if(oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if(oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if(oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid


FROM TABLE_LICENSE_JOIN
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

--- calculate repository licenses for green OA
TABLE_AGG_GREEN_ACC_PUB AS (

SELECT

IFNULL(license_green_acc_pub, "null") as license,
count(distinct if(oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only,


FROM TABLE_LICENSE_JOIN
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

--- join licenses counts
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

),

--- calculate totals per oa_type to enable downstream calculation of percentages
TABLE_DOI_COUNT AS (

SELECT

"unique_dois" as license, ---placeholder name to allow downstrem union
count(distinct if(oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if(oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if(oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid,
count(distinct if(oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only

FROM TABLE
WHERE NOT org_agg = 'uvh'
),

--- add total counts to license counts
TABLE_UNION AS (

SELECT * FROM TABLE_AGG_JOIN_NULLS

UNION ALL

SELECT * FROM TABLE_DOI_COUNT

)

SELECT * FROM TABLE_UNION
ORDER BY hybrid DESC NULLS LAST --- order by hybrid as most populated - gives most useful ordering of licenses

--- calculation of percentages not included - can be added or done outside script

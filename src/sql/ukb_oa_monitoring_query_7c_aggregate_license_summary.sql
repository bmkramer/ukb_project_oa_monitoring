--------------------------------------------------------
--- Create aggregated data - from flattened export table
-------------------------------------------------------

--------------------------------------------------------------------------------------
--- STEP 6C - Aggregated data - license summary
--------------------------------------------------------------------------------------

--- NB Counts are exclusive counts (i.e. has_license does not include has_license_cc etc)
--- calculation of percentages not included - can be added or done outside script

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

-------------------------------------------------------------------------------
---- remainder of script reuses SQL script 6c on reconstructed structured table
-------------------------------------------------------------------------------

--- select variables, filter to records in scope
TABLE AS (
SELECT

doi_cleaned,
org_agg,
oa_type,
oa_license

FROM TABLE_BASE,
UNNEST(org_agg) as org_agg
WHERE oa_type.oa_type_extended is not null

),

--- calculate publisher licenses for gold and hybrid OA
TABLE_AGG_PUBLISHER AS (

SELECT

IFNULL(oa_license.publisher_license, "null") as license, -- temporary conversion to allow left join on 'null'
count(distinct if(oa_type.oa_type_compact = "gold_doaj_non_apc", doi_cleaned, null)) as gold_doaj_non_apc,
count(distinct if(oa_type.oa_type_compact = "gold_doaj_apc", doi_cleaned, null)) as gold_doaj_apc,
count(distinct if(oa_type.oa_type_compact = "gold_non_doaj", doi_cleaned, null)) as gold_non_doaj,
count(distinct if(oa_type.oa_type_compact = "hybrid", doi_cleaned, null)) as hybrid


FROM TABLE
WHERE NOT org_agg = 'uvh'

GROUP BY license
),

--- calculate repository licenses for green OA
TABLE_AGG_GREEN_ACC_PUB AS (

SELECT

IFNULL(oa_license.repository_acc_pub_license, "null") as license,
count(distinct if(oa_type.oa_type_compact = "green_acc_pub_only", doi_cleaned, null)) as green_acc_pub_only,


FROM TABLE
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
ORDER BY license DESC

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
ORDER BY license DESC
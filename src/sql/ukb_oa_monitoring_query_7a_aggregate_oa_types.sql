--------------------------------------------------------
--- Create aggregated data - from flattened export table
-------------------------------------------------------

--------------------------------------------------------------------------------------
--- STEP 7A - Aggregated data - OA types 
--------------------------------------------------------------------------------------


--- import flat table
WITH TABLE_IMPORT AS (

SELECT

doi as doi_cleaned, --- to match script template
* EXCEPT (doi)

FROM `UKB_OA_2023.all_2023_export_table_full`

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
LEFT JOIN (SELECT doi_cleaned, license, offset FROM TABLE_IMPORT, UNNEST(SPLIT(license, ",") ) as version WITH OFFSET AS offset ORDER BY offset) as d
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
---- remainder of script reuses SQL script 6a on reconstructured structured table
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

--- calculate total aggregated OA values
TABLE_AGG_OA_EXT AS (

SELECT

oa_type.oa_type_extended,
count(distinct doi_cleaned) as count

FROM TABLE
WHERE NOT org_agg = 'uvh'

GROUP BY oa_type_extended

),

TABLE_AGG_OA_COMPACT AS (

SELECT

oa_type.oa_type_compact,
count(distinct doi_cleaned) as count

FROM TABLE
WHERE NOT org_agg = 'uvh'

GROUP BY oa_type_compact

),

--- calculate aggregated OA values by institution
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

FROM TABLE

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

FROM TABLE

GROUP BY org_agg
ORDER BY org_agg

)

--- select relevant table to save/export

----SELECT * FROM TABLE

SELECT * FROM TABLE_AGG_OA_EXT
---SELECT * FROM TABLE_AGG_OA_COMPACT


----SELECT * FROM TABLE_AGG_ORG_OA_EXT
---SELECT * FROM TABLE_AGG_ORG_OA_COMPACT


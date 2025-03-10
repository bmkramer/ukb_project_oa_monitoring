---------------------------------
--- Create export datasets
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 5B - Ungroup variables and create comma-separated strings
--------------------------------------------------------------------------------------

--- ungroup variables and create comma-separated strings
WITH TABLE AS (
SELECT

*

FROM `UKB_OA_2023.all_2023_export_base_table`

),

TABLE_ISSN_ARRAY_TO_STRING AS (

SELECT

doi_cleaned,
ARRAY_TO_STRING(issn.issns, ",") as issns,
ARRAY_TO_STRING(issn.issn_l, ",") as issn_l

FROM TABLE

),

TABLE_ISSN_STRING AS (

SELECT

doi_cleaned,
CASE WHEN LENGTH(issns) = 0 THEN null ELSE issns END AS issns,
CASE WHEN LENGTH(issn_l) = 0 THEN null ELSE issns END AS issn_l,

FROM TABLE_ISSN_ARRAY_TO_STRING

),

--- set oa_classification variables to null for dois not in upw (currently: false)
TABLE_OA_CLASSIFICATION AS (

SELECT

doi_cleaned,

CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.gold_doaj_non_apc END AS gold_doaj_non_apc,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.gold_doaj_apc END AS gold_doaj_apc,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.gold_non_doaj END AS gold_non_doaj,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.hybrid END AS hybrid,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.bronze END AS bronze,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.green_acc_pub END AS green_acc_pub,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.green_sub END AS green_sub,
CASE WHEN unpaywall.upw_included is false THEN null ELSE oa_classification.closed END AS closed,

FROM TABLE

),


TABLE_UPW_UNNEST AS (

SELECT

doi_cleaned,
IFNULL(l.host_type, 'null') as host_type,
IFNULL(l.version, 'null') as version,
IFNULL(l.license, 'null') as license,
IFNULL(SAFE_CAST(l.oa_date as STRING), 'null') as oa_date,
IFNULL(SAFE_CAST(SAFE_CAST(l.embargo_green_oa AS INT64) as STRING), "null") as embargo_green_oa,
IFNULL(l.repository_institution, 'null') as repository_institution,
IFNULL(l.host_url, 'null') as host_url

FROM TABLE,
UNNEST (unpaywall.oa_locations) as l

),

TABLE_UPW_ARRAY AS (

SELECT

doi_cleaned,
ARRAY_AGG(host_type) as host_type,
ARRAY_AGG(version) as version,
ARRAY_AGG(license) as license,
ARRAY_AGG(oa_date) as oa_date,
ARRAY_AGG(embargo_green_oa) as embargo_green_oa,
ARRAY_AGG(repository_institution) as repository_institution,
ARRAY_AGG(host_url) as host_url


FROM TABLE_UPW_UNNEST

GROUP BY doi_cleaned

),

TABLE_UPW_ARRAY_TO_STRING AS (

SELECT

doi_cleaned,
ARRAY_TO_STRING(host_type, ",") as host_type,
ARRAY_TO_STRING(version, ",") as version,
ARRAY_TO_STRING(license, ",") as license,
ARRAY_TO_STRING(oa_date, ",") as oa_date,
ARRAY_TO_STRING(embargo_green_oa, ",") as embargo_green_oa,
ARRAY_TO_STRING(repository_institution, ",") as repository_institution,
ARRAY_TO_STRING(host_url, ",") as host_url

FROM TABLE_UPW_ARRAY

),

--- replace strings with null where no oa_locations (check against presence of value(s) for host_type)
TABLE_UPW_STRING AS (

SELECT

doi_cleaned,

CASE WHEN host_type = "null" THEN null ELSE host_type END as host_type,
CASE WHEN host_type = "null" THEN null ELSE version END as version,
CASE WHEN host_type = "null" THEN null ELSE license END as license,
CASE WHEN host_type = "null" THEN null ELSE oa_date END as oa_date,
CASE WHEN host_type = "null" THEN null ELSE embargo_green_oa END as embargo_green_oa,
CASE WHEN host_type = "null" THEN null ELSE repository_institution END as repository_institution,
CASE WHEN host_type = "null" THEN null ELSE host_url END as host_url,

FROM TABLE_UPW_ARRAY_TO_STRING

),

TABLE_CREATE AS (

SELECT

a.doi_cleaned,
a.instance,
a.kuoz.*,
a.crossref.*,
b.* EXCEPT (doi_cleaned),
a.doaj.*,
a.unpaywall.upw_included,
a.unpaywall.journal_is_oa,
c.* EXCEPT (doi_cleaned),
d.* EXCEPT (doi_cleaned),
a.oa_type.*,
a.oa_license.*,
a.oa_embargo.*

FROM TABLE as a
LEFT JOIN TABLE_ISSN_STRING as b
USING (doi_cleaned)
LEFT JOIN TABLE_UPW_STRING as c
USING (doi_cleaned)
LEFT JOIN TABLE_OA_CLASSIFICATION as d
USING (doi_cleaned)

)

SELECT * FROM TABLE_CREATE

---saved as `UKB_OA_2023.all_2023_export_base_table_orgs`
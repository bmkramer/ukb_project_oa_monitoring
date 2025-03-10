---------------------------------
--- Add OA classification (OA type, licenses, embargo, Taverne)
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 4A - Add OA type classification
--------------------------------------------------------------------------------------

WITH TABLE AS (
SELECT

a.doi_cleaned,
a.org_agg,
a.kuoz_a.kuoz_a,
b.crossref.cr_included,
c.doaj,
d.unpaywall

FROM `UKB_OA_2023.all_2023_dois_instance` as a
LEFT JOIN `UKB_OA_2023.all_2023_dois_crossref` as b
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_doaj` as c
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_unpaywall` as d
USING (doi_cleaned)

),

TABLE_OA_CLASSIFICATION AS (

SELECT

doi_cleaned,

---- gold DOAJ (APC/no-APC)
CASE WHEN doaj.doaj_id is not null AND doaj.doaj_apc is false
THEN true ELSE FALSE END as gold_doaj_non_apc,

CASE WHEN doaj.doaj_id is not null AND doaj.doaj_apc is true
THEN true ELSE FALSE END as gold_doaj_apc,

--- gold non-DOAJ
--- this includes DOAJ-but-not-matched (xx) and non-DOAJ (xx)
CASE WHEN doaj.doaj_id is null
AND unpaywall.journal_is_oa is true
AND (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion')) > 0
THEN true ELSE FALSE END as gold_non_doaj,

-----hybrid
CASE WHEN doaj.doaj_id is null
AND unpaywall.journal_is_oa is false
AND (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion' AND l.license is not null)) > 0
THEN true ELSE FALSE END as hybrid,

-----bronze
CASE WHEN doaj.doaj_id is null
AND unpaywall.journal_is_oa is false
AND (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion' AND l.license is null)) > 0
THEN true ELSE FALSE END as bronze,


---- green acc/pub

CASE WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND l.version IN ("acceptedVersion", "publishedVersion"))) > 0
THEN true ELSE FALSE END as green_acc_pub,

--- green sub
CASE WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND NOT l.version IN ("acceptedVersion", "publishedVersion"))) > 0
THEN true ELSE FALSE END as green_sub,
--- NB this will include cases where version is null (can check if these occur in corpus)

--- closed
CASE WHEN doaj.doaj_id is null
AND (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion')) = 0
AND (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository")) = 0
AND unpaywall.oa_status is not null --- to differentiate dois not in Unpaywall
THEN true ELSE FALSE END as closed

FROM TABLE

),

--- create variables for oa type classification
TABLE_OA_TYPE AS (


SELECT

doi_cleaned,

CASE
WHEN gold_doaj_non_apc is true THEN "gold_doaj_non_apc"
WHEN gold_doaj_apc is true THEN "gold_doaj_apc"
WHEN gold_non_doaj is true THEN "gold_non_doaj"
WHEN hybrid is true THEN "hybrid"
WHEN (bronze is true
AND green_acc_pub is false) THEN "bronze_only"
WHEN (bronze is true
AND green_acc_pub is true) THEN "bronze_green_acc_pub"
WHEN (gold_doaj_non_apc is false
AND gold_doaj_apc is false
AND gold_non_doaj is false
AND hybrid is false
AND bronze is false
AND green_acc_pub is true) THEN "green_acc_pub_only_no_bronze"
WHEN (gold_doaj_non_apc is false
AND gold_doaj_apc is false
AND gold_non_doaj is false
AND hybrid is false
AND bronze is false
AND green_acc_pub is false
AND green_sub is true) THEN "green_sub_only"
WHEN closed is true THEN "closed"
ELSE null END as oa_type_extended,

CASE
WHEN gold_doaj_non_apc is true THEN "gold_doaj_non_apc"
WHEN gold_doaj_apc is true THEN "gold_doaj_apc"
WHEN gold_non_doaj is true THEN "gold_non_doaj"
WHEN hybrid is true THEN "hybrid"
WHEN (gold_doaj_non_apc is false
AND gold_doaj_apc is false
AND gold_non_doaj is false
AND hybrid is false
AND green_acc_pub is true) THEN "green_acc_pub_only"
WHEN (bronze is true
OR green_sub is true
OR closed is true) THEN "non oa"
ELSE null END as oa_type_compact,

CASE
WHEN
(gold_doaj_non_apc is true
OR gold_doaj_apc is true
OR gold_non_doaj is true
OR hybrid is true
OR bronze is true)
AND
(green_acc_pub is false
AND green_sub is false)
THEN "publisher open"
WHEN
(gold_doaj_non_apc is true
OR gold_doaj_apc is true
OR gold_non_doaj is true
OR hybrid is true
OR bronze is true)
AND
(green_acc_pub is true
OR green_sub is true)
THEN "both"
WHEN
(gold_doaj_non_apc is false
AND gold_doaj_apc is false
AND gold_non_doaj is false
AND hybrid is false
AND bronze is false)
AND
(green_acc_pub is true
OR green_sub is true)
THEN "other platform open"
WHEN
closed is true
THEN "closed"
ELSE null END as oa_type_coki,


FROM TABLE_OA_CLASSIFICATION
),


TABLE_JOIN AS (

SELECT

---- include additional variables to enable calculations for quality assurance
a.doi_cleaned,
a.org_agg,
a.kuoz_a,
a.cr_included,
a.unpaywall.upw_included,

STRUCT(
b.gold_doaj_non_apc,
b.gold_doaj_apc,
b.gold_non_doaj,
b.hybrid,
b.bronze,
b.green_acc_pub,
b.green_sub,
b.closed
) as oa_classification,

STRUCT(
c.oa_type_extended,
c.oa_type_compact,
c.oa_type_coki
) as oa_type

FROM TABLE as a
LEFT JOIN TABLE_OA_CLASSIFICATION as b
USING (doi_cleaned)
LEFT JOIN TABLE_OA_TYPE as c
USING (doi_cleaned)

)


SELECT * FROM TABLE_JOIN
---saved as `UKB_OA_2023.all_2023_dois_oa_information`
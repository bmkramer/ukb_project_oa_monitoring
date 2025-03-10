---------------------------------
--- Add OA classification (OA type, licenses, embargo, Taverne)
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 4a - Add embargo classification, include Taverne information
--------------------------------------------------------------------------------------

--- import selected variable from instance data to add embargo classification to
--- this creates an intermediate table useful for calculating aggregated counts on embargo and Taverne
--- this script can be cleaned by adding embargo classification only to dois

WITH TABLE_INSTANCE AS (

SELECT

doi_cleaned,
instance.org_agg as org_agg,
instance.taverne as taverne

FROM `UKB_OA_2023.all_2023_dois_instance`,
UNNEST (instance) as instance

),

--- join to relevant OA information
TABLE_JOIN AS (
SELECT

a.*,
b.oa_type,
c.unpaywall

FROM TABLE_INSTANCE as a
RIGHT JOIN `UKB_OA_2023.all_2023_dois_oa_information` as b
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_unpaywall` as c
USING (doi_cleaned)
WHERE b.kuoz_a is true AND b.cr_included is true AND b.oa_type.oa_type_extended is not null
),

--- calculate embargo classes
TABLE_EMBARGO AS (

SELECT

doi_cleaned,

---- first oa_date and version = accpub
(SELECT l.embargo_green_oa
FROM UNNEST(unpaywall.oa_locations) as l
WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion'))
ORDER BY l.embargo_green_oa ASC NULLS LAST LIMIT 1
)
as embargo_green_acc_pub,

---- first oa_date and version = sub
(SELECT l.embargo_green_oa
FROM UNNEST(unpaywall.oa_locations) as l
WHERE (l.host_type="repository" AND NOT l.version IN ('publishedVersion', 'acceptedVersion'))
ORDER BY l.embargo_green_oa ASC NULLS LAST LIMIT 1
)
as embargo_green_sub

FROM TABLE_JOIN

),

TABLE_EMBARGO_INT AS (

SELECT

doi_cleaned,

CASE
WHEN embargo_green_acc_pub >= 0 THEN FLOOR(embargo_green_acc_pub)
WHEN embargo_green_acc_pub < 0 THEN CEILING(embargo_green_acc_pub)
ELSE null END as embargo_green_acc_pub,

CASE
WHEN embargo_green_sub >= 0 THEN FLOOR(embargo_green_sub)
WHEN embargo_green_sub < 0 THEN CEILING(embargo_green_sub)
ELSE null END as embargo_green_sub,

FROM TABLE_EMBARGO

),

TABLE_EMBARGO_CLASS AS (

---- green embargo classification - aligned with distribution classes (which use FLOOR())
SELECT

doi_cleaned,

CASE
WHEN embargo_green_acc_pub < 0 THEN "embargo_neg"
WHEN embargo_green_acc_pub >= 0 AND embargo_green_acc_pub < 1 THEN "embargo_0"
WHEN embargo_green_acc_pub>= 1 AND embargo_green_acc_pub < 7 THEN "embargo_6"
WHEN embargo_green_acc_pub >= 7 AND embargo_green_acc_pub < 13 THEN "embargo_12"
WHEN embargo_green_acc_pub >= 13 AND embargo_green_acc_pub < 25 THEN "embargo_24"
WHEN embargo_green_acc_pub >= 25 THEN "embargo_max"
WHEN embargo_green_acc_pub is null THEN "embargo_null"
ELSE null END as embargo_class_green_acc_pub,

CASE
WHEN embargo_green_sub < 0 THEN "embargo_neg"
WHEN embargo_green_sub >= 0 AND embargo_green_acc_pub < 1 THEN "embargo_0"
WHEN embargo_green_sub >= 1 AND embargo_green_acc_pub < 7 THEN "embargo_6"
WHEN embargo_green_sub >= 7 AND embargo_green_acc_pub < 13 THEN "embargo_12"
WHEN embargo_green_sub >= 13 AND embargo_green_acc_pub < 25 THEN "embargo_24"
WHEN embargo_green_sub >= 25 THEN "embargo_max"
WHEN embargo_green_sub is null THEN "embargo_null"
ELSE null END as embargo_class_green_sub,

FROM TABLE_EMBARGO_INT

),



TABLE_JOIN_EMBARGO AS (

SELECT

a.*,

STRUCT(
b.embargo_green_acc_pub,
b.embargo_green_sub
) as oa_embargo,

STRUCT(
c.embargo_class_green_acc_pub,
c.embargo_class_green_sub
) as oa_embargo_class

FROM TABLE_JOIN as a
LEFT JOIN TABLE_EMBARGO_INT as b
USING (doi_cleaned)
LEFT JOIN TABLE_EMBARGO_CLASS as c
USING (doi_cleaned)

)


SELECT * FROM TABLE_JOIN_EMBARGO

---saved as `UKB_OA_2023.all_2023_dois_embargo_taverne`
---------------------------------
--- Combine CRIS data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 1B - Aggregate instances by DOI
--------------------------------------------------------------------------------------


-- aggregate all uuids (with all variables) under each doi
---also aggregate org_agg as separate variable
TABLE_INSTANCE_AGG AS (

SELECT DISTINCT

doi_cleaned,
ARRAY_AGG(
STRUCT(
uuid_unique,
org_agg,
uuid,
umc,
org_ror,
org_name,
doi,
issn_unidentified, e_issn, issn,
hoop,
kuoz,
taverne,
funding,
corresponding)) as instance,
ARRAY_AGG(org_agg) as org_agg

FROM `UKB_OA_2023.all_2023_instance`
WHERE doi_cleaned is not null

GROUP BY doi_cleaned

),

TABLE_KUOZ AS (
SELECT

*,
CASE
WHEN (SELECT COUNT(1) FROM UNNEST(instance) AS i WHERE i.kuoz = "A") > 0 THEN TRUE
ELSE FALSE
END as kuoz_a,
CASE
WHEN (SELECT COUNT(1) FROM UNNEST(instance) AS i WHERE (i.kuoz != "A" AND kuoz is not null)) > 0 THEN TRUE
ELSE FALSE
END as kuoz_other,

FROM TABLE_INSTANCE_AGG

),

TABLE_KUOZ_AGG AS (

SELECT
* EXCEPT (
kuoz_a,
kuoz_other),
STRUCT(
kuoz_a,
kuoz_other
) as kuoz_a,

FROM TABLE_KUOZ

)

SELECT * FROM TABLE_KUOZ_AGG
--- save as `UKB_OA.all_2023_dois_instance`
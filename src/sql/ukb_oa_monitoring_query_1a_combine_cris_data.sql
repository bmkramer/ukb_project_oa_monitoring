---------------------------------
--- Combine CRIS data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 1A - Combine CRIS tables, clean variables, add uuid 
--------------------------------------------------------------------------------------


--- append all CRIS tables
WITH TABLE_UNION AS (

SELECT * FROM `UKB_OA_2023.eur_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.eut_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.lei_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.ru_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.til_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.tud_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.ug_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.um_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.ut_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.uu_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.uumc_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.uva_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.vu_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.vumc_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.wur_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.ou_2023`
UNION ALL
SELECT * FROM `UKB_OA_2023.uvh_2023`
),

TABLE_ALL AS (
SELECT
*
FROM TABLE_UNION
WHERE uuid is not null --- to remove empty rows
--- NB do not remove duplicate rows to enable full match to institutional data later
),

--- clean variables according to specification
TABLE_CLEAN AS (
SELECT
uuid,
--- umc: standardize capitalization to specification
--- NB could simply use LOWER(), but align syntax across cleaning steps
CASE
WHEN umc = "Yes" THEN "yes"
WHEN umc = "No" THEN "no"
ELSE umc END as umc,
--- org_ror: fix 'pulled down' RORS with consecutive digits
CASE
WHEN org_name = "til" THEN "04b8v1s79"
WHEN org_name = "uvh" THEN "04w5ec154"
ELSE org_ror END as org_ror,
org_name,
--- issn columns: standardize separator to specification, remove all spaces (this includes trim)
REPLACE(REPLACE(issn_unidentified, '|', ';'), ' ', '') as issn_unidentified,
REPLACE(REPLACE(e_issn, '|', ';'), ' ', '') as e_issn,
REPLACE(REPLACE(issn, '|', ';'), ' ', '') as issn,
--- doi: clean in separate step, leave as supplied here
doi,
--- hoop: standardize separator to specification, remove space before and after separator, trim
TRIM(REGEXP_REPLACE(REPLACE(hoop, '|', ';'), '\\s?;\\s?', ';')) as hoop,
--- kuoz: no cleaning needed
kuoz,
--- taverne: standardize values to specification;
CASE
WHEN taverne = "Yes" THEN "yes"
WHEN taverne = "No" THEN "no"
WHEN taverne = "ja" THEN "yes"
WHEN taverne = "nee" THEN "no"
ELSE taverne END as taverne,
--- funding: replace NA with null, trum
--- separator not standardized as field contents not used in current analysis
CASE
WHEN funding = "NA" THEN null
ELSE funding END as funding,
--- corresponding: standardize values to specification, replace NA with 'unknown' (as not nullable)
CASE
WHEN corresponding = "Yes" THEN "yes"
WHEN corresponding = "Unknown" THEN "unknown"
WHEN corresponding = "ja" THEN "yes"
WHEN corresponding = "NA" THEN "unknown"
ELSE corresponding END as corresponding,

FROM TABLE_ALL
),

--- clean dois, add as new variable
TABLE_ADD_DOI_CLEAN AS (

SELECT

--- doi cleaning (in nested mutation statement):
---- 1) remove part of string before 10.
---- NB this conveniently also returns null for all values that do no contain a doi string
---- 2) remove spaces
---- 3) remove specific string '(+1more)' (spaces in orignal have already been removed in step 2)
---- NB This does not require regex as it is not pattern matching - but could consider specifying occurrence at end of string
---- 4) convert to lower for all subsequent matching

--- NB This leaves in cases of multiple DOIs (by design, as this is an input error)
--- NB This leaves in miscellaneous suffixes (which would need to be individually marked - with risk of false positives)

*,
LOWER(REPLACE(REGEXP_REPLACE(CONCAT('10.', REGEXP_SUBSTR(doi, '10\\.(.*)')),' ', ''), '(+1more)', '')) AS doi_cleaned,

FROM TABLE_CLEAN

),

--- add variables uuid_unique and org_agg for internal use
TABLE_ADD_VARIABLES AS (

SELECT

--- use # as character in CONCAT as this does not occur in any uuid string - allows for clean split at end of workflow
CONCAT(org_name, "#", uuid) as uuid_unique,

--- create org_agg to group unis wih their respective umcs
CASE
WHEN org_name IN ("eur", "emc") THEN "eur"
WHEN org_name IN ("lei", "lumc") THEN "lei"
WHEN org_name IN ("ru", "rumc") THEN "ru"
WHEN org_name IN ("ug", "umcg") THEN "ug"
WHEN org_name IN ("um", "mumc") THEN "um"
WHEN org_name IN ("uu", "uumc") THEN "uu"
WHEN org_name IN ("uva", "aumc") THEN "uva" --- vu data use vumc, so all aumc indicates uva IN THIS OVERALL DATASET
WHEN org_name IN ("vu", "vumc") THEN "vu"
ELSE org_name END as org_agg,

*

FROM TABLE_ADD_DOI_CLEAN

)

SELECT * FROM TABLE_ADD_VARIABLES

--- save as `UKB_OA_2023.all_2023_instance`
---------------------------------
--- Add bibliographic data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 2C - Add DOAJ metadata, match on ISSN/ISSN-L 
--------------------------------------------------------------------------------------


--- create table of all doaj_issns to turn into array later
--- NB all ISSNs are the right length and format
WITH TABLE_DOAJ_ISSN AS (

SELECT

SUBSTRING(URL_in_DOAJ, 22) as doaj_id,
UPPER(TRIM(Journal_ISSN__print_version_)) as issn

FROM `UKB_OA_2023.doaj_20231231`

UNION ALL

SELECT

SUBSTRING(URL_in_DOAJ, 22) as doaj_id,
UPPER(TRIM(Journal_EISSN__online_version_)) as issn

FROM `UKB_OA_2023.doaj_20231231`


),

--- convert issns into array, discard nulls
TABLE_DOAJ_ISSN_ARRAY AS (

SELECT

doaj_id,
ARRAY_AGG(issn) as doaj_issn,

FROM (SELECT DISTINCT * FROM TABLE_DOAJ_ISSN WHERE issn is not null)
GROUP BY doaj_id

),

--- join back to doaj to create working table
TABLE_DOAJ_SELECT AS (

SELECT

SUBSTRING(a.URL_in_DOAJ, 22) as doaj_id,
b.doaj_issn as doaj_issn,
a.APC as doaj_apc

FROM `UKB_OA_2023.doaj_20231231` as a
LEFT JOIN TABLE_DOAJ_ISSN_ARRAY as b
ON SUBSTRING(a.URL_in_DOAJ, 22) = b.doaj_id

),
--- n = 20261

TABLE_DOAJ_ISSN_L AS (

SELECT DISTINCT

a.doaj_id,
a.issns,
b.issn_l

FROM (SELECT * FROM TABLE_DOAJ_SELECT, UNNEST (doaj_issn) as issns) as a
LEFT JOIN `UKB_OA_2023.issn_to_issn_l_20240326` as b
ON UPPER(TRIM(a.issns)) = UPPER(TRIM(b.issn))
),

--- aggregate issn_ls per doaj_id
TABLE_DOAJ_ISSN_L_AGG AS (

SELECT

doaj_id,
ARRAY_AGG(issn_l IGNORE nulls) as issn_l


FROM TABLE_DOAJ_ISSN_L
GROUP BY doaj_id

--- 19391 of 20261 dois with issn-l, 280 of which with multiple issn_l
),

TABLE_DOAJ_ISSN_JOIN AS (

--- match back issn_l array to original DOAJ table
SELECT

a.doaj_id,
a.doaj_issn,
a.doaj_apc,
b.issn_l as doaj_issn_l,

FROM TABLE_DOAJ_SELECT as a
LEFT JOIN TABLE_DOAJ_ISSN_L_AGG as b
USING (doaj_id)

),

--- add structuring step
--- create structured issn variable
TABLE_DOAJ_ISSN_STRUCT AS (

SELECT

doaj_id,
doaj_apc,
STRUCT(doaj_issn, doaj_issn_l) as doaj_issn,

FROM TABLE_DOAJ_ISSN_JOIN


),

--- combine issns and issn_ls into 1 array
--- NB will include any duplicate issns
TABLE_ISSN_ALL AS (

SELECT

doi_cleaned,
ARRAY_CONCAT(
IFNULL(issn.issns, []),
IFNULL(issn.issn_l, [])) as issn_all,


FROM `UKB_OA_2023.all_2023_dois_issn`

),

--- combine issns and issn_ls into 1 array
--- NB will include any duplicate issns
TABLE_DOAJ_ISSN_ALL AS (

SELECT
doaj_id,
doaj_apc,
ARRAY_CONCAT(
IFNULL(doaj_issn.doaj_issn, []),
IFNULL(doaj_issn.doaj_issn_l, [])) as doaj_issn_all

FROM TABLE_DOAJ_ISSN_STRUCT
),

TABLE_MATCH_ISSN AS (
SELECT DISTINCT
a.doi_cleaned,
b.doaj_id,
b.doaj_apc,
FROM (SELECT * FROM TABLE_ISSN_ALL, UNNEST (issn_all) as issns) as a
LEFT JOIN (SELECT * FROM TABLE_DOAJ_ISSN_ALL, UNNEST(doaj_issn_all) as doaj_issns) as b
ON UPPER(TRIM(a.issns)) = UPPER(TRIM(b.doaj_issns))
WHERE doaj_id is not null --- to remove duplicate dois where one ISSN matches and 1 one does not
),

--- ARRAY_AGG should not be necessary as no duplicate matches. Fix with forced unnest in next step
--- TO DO: investigate what goes wrong here
TABLE_AGG_0 AS (
SELECT

doi_cleaned,
ARRAY_AGG(STRUCT(
doaj_id,
doaj_apc
)) as doaj

FROM TABLE_MATCH_ISSN
GROUP BY doi_cleaned
),

----interim measure to unnest repeated record
TABLE_AGG AS (

SELECT
doi_cleaned,
STRUCT(
doaj_id,
doaj_apc
) as doaj

FROM TABLE_AGG_0
LEFT JOIN UNNEST(doaj) as doaj

),

---match back to original table
TABLE_JOIN AS (

SELECT

a.doi_cleaned,
b.doaj

FROM `UKB_OA_2023.all_2023_dois_issn` as a
LEFT JOIN TABLE_AGG as b
ON UPPER(TRIM(a.doi_cleaned)) = UPPER(TRIM(b.doi_cleaned))

)

SELECT * FROM TABLE_JOIN


--- save as `UKB_OA_2023.all_2023_dois_doaj`
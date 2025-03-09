---------------------------------
--- Add bibliographic data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 2A - Add ISSNs from Crossref, match to ISSN-L 
--------------------------------------------------------------------------------------


--- collect issns from Crossref
--- match issn_ls to issns in CRIS data
WITH TABLE_CR_ISSN AS (

SELECT

a.doi_cleaned,
b.ISSN as issns


FROM `UKB_OA_2023.all_2023_dois_instance` as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20240731` as b
ON UPPER(TRIM(a.doi_cleaned)) = UPPER(TRIM(b.DOI))

),

--- this is done separately tp prevent data loss in next steps when issn_l is null
TABLE_CR_ISSN_L AS (

SELECT DISTINCT

a.doi_cleaned,
b.issn_l

FROM (SELECT * FROM TABLE_CR_ISSN, UNNEST (issns) as issn) as a
LEFT JOIN `UKB_OA_2023.issn_to_issn_l_20240326` as b
ON UPPER(TRIM(a.issn)) = UPPER(TRIM(b.issn_l))
),


--- aggregate issn_ls per doi
TABLE_CR_ISSN_L_AGG AS (

SELECT

doi_cleaned,
ARRAY_AGG(issn_l IGNORE NULLS) as issn_l

FROM TABLE_CR_ISSN_L
GROUP BY doi_cleaned

),

--- match back issn_l array to original CR table
TABLE_CR_ISSN_JOIN AS (
SELECT

a.*,
b.issn_l

FROM TABLE_CR_ISSN as a
LEFT JOIN TABLE_CR_ISSN_L_AGG as b
USING (doi_cleaned)
),

--- create structured issn variable
TABLE_CR_ISSN_STRUCT AS (

SELECT

doi_cleaned,
STRUCT(issns, issn_l) as issn

FROM TABLE_CR_ISSN_JOIN


)

SELECT * FROM TABLE_CR_ISSN_STRUCT


---- saved as `UKB_OA_2023.all_2023_dois_issn`
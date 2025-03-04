---------------------------------
--- Corpus collection
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 1 - Collect DOIs for UKRI-funded output from Gateway to Research and Crossref
--------------------------------------------------------------------------------------

--- STEP 1A - collate GTR data sets 2012-2022
--- datasets previously downloaded from Gateway to Research
--- Enforce single data type for PMID (which is sometimes imported as string, sometimes as integer)
WITH TABLE_GTR AS (

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2022_20231105`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2021_20231105`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2020_20231105`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2019_20231105`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2018_20231105`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2017_20231114`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2016_20231114`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2015_20231114`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2014_20231114`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2013_20231114`

UNION ALL

SELECT * REPLACE(SAFE_CAST(PMID AS STRING) AS PMID)
FROM `ukri-oa-baseline.supplementary_sources.GtR_2012_20231114`

--- n = 838,729
),


--- STEP 1B - Keep only DOIs as variable from Gateway to Research; clean DOIs
TABLE_GTR_CLEANED AS (

SELECT DISTINCT

UPPER(REGEXP_REPLACE(CONCAT('10.', REGEXP_SUBSTR(DOI, '10\\.(.*)')),' ', '')) AS DOI,
"GtR" as ukri_source_gtr, --- indicate GtR as source

FROM TABLE_GTR
--- n=381,647 (incl DOI = null)
),

--- STEP 1C - Collect DOIs from Crossref with UKRI-associated Funder IDs

TABLE_CR_UKRI AS (

SELECT DISTINCT

UPPER(a.DOI) as DOI,
"Crossref" as ukri_source_crossref, --- indicate Crossref as source

FROM `academic-observatory.crossref_metadata.crossref_metadata20231031` as a,
UNNEST (funder) as funder
WHERE funder.DOI IN (

'10.13039/100014013',
'10.13039/501100000265',
'10.13039/501100009187',
'10.13039/501100000266',
'10.13039/501100014813',
'10.13039/501100014814',
'10.13039/501100013915',
'10.13039/501100018959',
'10.13039/501100000267',
'10.13039/501100000268',
'10.13039/501100000269',
'10.13039/501100000270',
'10.13039/501100007849',
'10.13039/501100011027',
'10.13039/501100012508',
'10.13039/501100013341',
'10.13039/501100000271',
'10.13039/100013266',
'10.13039/100014570',
'10.13039/501100021200',
'10.13039/501100006041',
'10.13039/501100013589',
'10.13039/501100000690',
'10.13039/501100019328')

--- n=192,818
),

--- STEP 1D - Combine GtR and Crossref DOIs
--- keep source indicators (GtR and Crossref)

TABLE_UKRI_JOIN AS (

SELECT DISTINCT --- this ensures each DOI will only occur once in the table

DOI as doi,
a.ukri_source_gtr,
b.ukri_source_crossref

FROM TABLE_GTR_CLEANED as a
FULL JOIN TABLE_CR_UKRI as b
USING (DOI) --- variable DOI is already upper case in both source tables

--- n=450,066
),


--- STEP 1E - Collect additional information from Crossref for all DOIs (publication year and publication type)
--- For future iteration, consider moving this to after collecting OpenAlex DOIs for all UK

TABLE_UKRI_CR_ADD AS (

SELECT DISTINCT

a.*,
IF(ARRAY_LENGTH(b.issued.date_parts) > 0, b.issued.date_parts[offset(0)], null) as cr_issued_year,
b.type as cr_type,

FROM TABLE_UKRI_JOIN as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20231031` as b
ON UPPER(TRIM(a.DOI)) = UPPER(TRIM(b.DOI))

),

--- STEP 1F - Keep only DOIs with Crossref publication year between 2012 and 2022

TABLE_UKRI_2012_2022 AS (

SELECT * FROM TABLE_UKRI_CR_ADD
WHERE cr_issued_year BETWEEN 2012 AND 2022
---This will also exclude all GtR DOI records that cannot be matched to Crossref (other registrar or invalid)

---n = 422,237
),

-----------------------------------------------------
--- STEP 2 - Get DOIs with affiliation UK from OpenAlex
------------------------------------------------------

--- STEP 2A - Get DOIs from OpenAlex
--- indicate presence of UK-affiliated author(s) as well as UK-affiliated corresponding author(s)
TABLE_OPENALEX AS (

SELECT

id as source_id,
UPPER(TRIM(SUBSTRING(doi, 17))) as doi,

CASE WHEN (SELECT COUNT(1) FROM UNNEST(authorships) AS authors, UNNEST(institutions) as institution WHERE institution.country_code = "GB") > 0 THEN TRUE ELSE FALSE END as has_affiliation_gb,

CASE WHEN (SELECT COUNT(1) FROM UNNEST(authorships) AS authors, UNNEST(institutions) as institution WHERE institution.country_code = "GB" and authors.is_corresponding is true) > 0 THEN TRUE ELSE FALSE END as has_affiliation_corr_gb,

--- create ranking based on chosen variables (citation count, sequential OpenAlex ID)
--- needed because in a few cases, there are multiple OpenAlex IDs with the same DOI
--- this enables selecting only one OpenAlex ID (in step 2B) in a reproducible way
RANK() OVER (ORDER BY institutions_distinct_count DESC, id DESC) as deduplication_rank,

FROM `academic-observatory.openalex_snapshot.works20231018` --- this was the version used for the baseline report
--- FROM `academic-observatory.openalex.works` -- this is always the most current version
WHERE doi is not null

),

--- STEP 2B - Deduplicate dois
--- Sort OpenAlex IDs by previouysly defined rank, only keep first OpenAlex ID for each DOI
TABLE_OPENALEX_DEDUP AS (

SELECT
papers.*

FROM
(SELECT doi, ARRAY_AGG(source_id ORDER BY deduplication_rank)[offset(0)] as source_id
FROM TABLE_OPENALEX as cleaned_ids
GROUP BY doi) as dois

LEFT JOIN TABLE_OPENALEX as papers ON papers.source_id = dois.source_id
),

--- Step 2C - Keep only dois with UK affilation(s)
TABLE_UK AS (

SELECT * EXCEPT (deduplication_rank)

FROM TABLE_OPENALEX_DEDUP
WHERE has_affiliation_gb is true
),

--- Step 2D - Collect additional information from Crossref for all DOIs (publication year and publication type)
TABLE_UK_CR_ADD AS (

SELECT DISTINCT

a.*,
IF(ARRAY_LENGTH(b.issued.date_parts) > 0, b.issued.date_parts[offset(0)], null) as cr_issued_year,
b.type as cr_type,

FROM TABLE_UK as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20231031` as b
ON UPPER(TRIM(a.DOI)) = UPPER(TRIM(b.DOI))

),

--- Step 2E - Keep only DOIs with Crossref publication year between 2012 and 2022

TABLE_UK_2012_2022 AS (

SELECT * FROM TABLE_UK_CR_ADD
WHERE cr_issued_year BETWEEN 2012 AND 2022

---n = 2,591,813
),


--------------------------------------------------------------------
--- STEP 3 - Combine UK-funded and UK-affiliated DOIs into one dataset
--------------------------------------------------------------------

--- STEP 3A - Combine UK-funded and UK-affiliated DOIs into one dataset
--- OpenAlex IDs are lef out at this time (as these were only collected for UK-affiliated DOIs)
--- OpenAlex IDs for UKRI-funded DOIs are added for all records in Step 3B

TABLE_UKRI_UK_2012_2022 AS (

SELECT DISTINCT

doi,
b.source_id as openalex_id,
cr_type,
cr_issued_year,
CASE WHEN a.doi is not null THEN "ukri" ELSE null END as corpus_ukri,
CASE WHEN b.doi is not null THEN "uk" ELSE null END as corpus_uk,
a.ukri_source_gtr,
a.ukri_source_crossref,
b.has_affiliation_gb, --- T/F only included for UK-affiliated output
b.has_affiliation_corr_gb -- T/F only included for UK-affiliated output

FROM TABLE_UKRI_2012_2022 as a
FULL JOIN TABLE_UK_2012_2022 as b
USING (doi, cr_type, cr_issued_year) -- these are the same in both tables, including upper case DOI
--- n = 2,648,634
),

--- STEP 3B - Add OpenAlex ID for UKRI-funded DOIs
--- This uses a different prioritization for duplicate DOIs than used in Step 2A - in future iterations, the same approach should be used
--- Left as is in this version to be able to reproduce all counts as reported

TABLE_OPENALEX_ID AS (

SELECT

id as source_id,
UPPER(TRIM(SUBSTRING(doi, 17))) as doi,

--- create ranking based on chosen variables
RANK() OVER (ORDER BY institutions_distinct_count DESC, id DESC) as deduplication_rank,

FROM `academic-observatory.openalex_snapshot.works20231018` --- this was the version used for the baseline report 2023-10-18
--- FROM `academic-observatory.openalex.works` -- this is always the most current version
WHERE doi is not null

--- n = 2,648,634
),

TABLE_OPENALEX_ID_DEDUP AS (

SELECT
papers.*

FROM
(SELECT doi, ARRAY_AGG(source_id ORDER BY deduplication_rank)[offset(0)] as source_id
FROM TABLE_OPENALEX_ID as cleaned_ids
GROUP BY doi) as dois

LEFT JOIN TABLE_OPENALEX_ID as papers ON papers.source_id = dois.source_id
--- n = 2,648,634
),


TABLE_UKRI_UK_2012_2022_ID AS (

SELECT

a.doi,
CASE WHEN a.openalex_id is null THEN b.source_id ELSE a.openalex_id END as openalex_id,
a.* EXCEPT (doi, openalex_id)

FROM TABLE_UKRI_UK_2012_2022 as a
LEFT JOIN TABLE_OPENALEX_ID_DEDUP as b
ON UPPER(TRIM(a.doi)) = UPPER(TRIM(b.doi))
--- n = 2,648,634, of which 2,648,617 with OpenAlex ID 
),

--- STEP 3D - Limit dataaset to journal articles only

TABLE_UKRI_UK_2012_2022_ID_ARTICLES AS (

SELECT * FROM TABLE_UKRI_UK_2012_2022_ID
WHERE cr_type = "journal-article"

--- n = 2,183,830
)

SELECT * FROM TABLE_UKRI_UK_2012_2022_ID_ARTICLES

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
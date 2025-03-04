---------------------------------
--- OA classification
---------------------------------

--- STEP 1A Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),


--- STEP 1B - Collect created date from Crosssref
--- This is always given as YMD, and used for later calculation of embargo times

TABLE_DOIS_DATE AS (

SELECT
a.*,

EXTRACT(YEAR FROM b.created.date_time) as cr_created_year, -- can be used for quality control to assess difference with publication date
EXTRACT(DATE FROM b.created.date_time) as cr_created_date,

FROM TABLE_DOIS as a
LEFT JOIN `academic-observatory.crossref_metadata.crossref_metadata20231031` as b
ON UPPER(TRIM(a.doi)) = UPPER(TRIM(b.DOI))
),

--- STEP 1C - Collect OA information from Unpaywall
--- Take OA information from most recent version of Unpaywall for two reasons:
--- Not all variables included in OpenAlex yet (e.g.oa_date)
--- Discrepancies reported esp. regarding coverage of green OA -> use UPW directly

TABLE_UNPAYWALL AS (

SELECT

doi,
oa_status,
journal_is_in_doaj,
journal_is_oa,


--- oa_location = publisher, and publisher licenses
--- as discussed with UKRI, cc-by-sa not distinguished separately as not inlcuded in compliant licenses
--- in future iterations, consider limiting the above to published version on publisher website
CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher")) > 0
THEN true ELSE FALSE END as publisher,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.license is not null)) > 0
THEN true ELSE FALSE END as publisher_license,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND STARTS_WITH(l.license, "cc"))) > 0
THEN true ELSE FALSE END as publisher_cc,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.license="cc-by")) > 0
THEN true ELSE FALSE END as publisher_ccby,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.license="cc-by-nd")) > 0
THEN true ELSE FALSE END as publisher_ccbynd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.license IN ("cc0", "public-domain", "pd"))) > 0
THEN true ELSE FALSE END as publisher_cc0pd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion'))) > 0
THEN true ELSE FALSE END as publisher_pub,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion') AND l.license is not null)) > 0
THEN true ELSE FALSE END as publisher_pub_license,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion') AND STARTS_WITH(l.license, "cc"))) > 0
THEN true ELSE FALSE END as publisher_pub_cc,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion') AND l.license="cc-by")) > 0
THEN true ELSE FALSE END as publisher_pub_ccby,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion') AND l.license="cc-by-nd")) > 0
THEN true ELSE FALSE END as publisher_pub_ccbynd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="publisher" AND l.version IN ('publishedVersion') AND l.license IN ("cc0", "public-domain", "pd"))) > 0
THEN true ELSE FALSE END as publisher_pub_cc0pd,


--- oa_location = repository, same with licenses
CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository")) > 0
THEN true ELSE FALSE END as repository,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND STARTS_WITH(l.license, "cc"))) > 0
THEN true ELSE FALSE END as repository_cc,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.license="cc-by")) > 0
THEN true ELSE FALSE END as repository_ccby,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.license="cc-by-nd")) > 0
THEN true ELSE FALSE END as repository_ccbynd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.license IN ("cc0", "public-domain", "pd"))) > 0
THEN true ELSE FALSE END as repository_cc0pd,


--- oa_location = repository, version = accpub, same with licenses
CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion'))) > 0
THEN true ELSE FALSE END as repository_accpub,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND STARTS_WITH(l.license, "cc"))) > 0
THEN true ELSE FALSE END as repository_accpub_cc,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion')AND l.license="cc-by")) > 0
THEN true ELSE FALSE END as repository_accpub_ccby,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND l.license="cc-by-nd")) > 0
THEN true ELSE FALSE END as repository_accpub_ccbynd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND l.license IN ("cc0", "public-domain", "pd"))) > 0
THEN true ELSE FALSE END as repository_accpub_cc0pd,


--- oa_location = repository, version = sub, same with licenses
CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('submittedVersion'))) > 0
THEN true ELSE FALSE END as repository_sub,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('submittedVersion') AND STARTS_WITH(l.license, "cc"))) > 0
THEN true ELSE FALSE END as repository_sub_cc,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('submittedVersion') AND l.license="cc-by")) > 0
THEN true ELSE FALSE END as repository_sub_ccby,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('submittedVersion') AND l.license="cc-by-nd")) > 0
THEN true ELSE FALSE END as repository_sub_ccbynd,

CASE WHEN (
SELECT COUNT(1) FROM UNNEST(u.oa_locations) as l WHERE (l.host_type="repository" AND l.version IN ('submittedVersion') AND l.license IN ("cc0", "public-domain", "pd"))) > 0
THEN true ELSE FALSE END as repository_sub_cc0pd,

---- first oa_date, with license
(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE l.host_type="repository"
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and STARTS_WITH(l.license, "cc"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_cc,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.license="cc-by")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_ccby,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.license="cc-by-nd")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_ccbynd,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.license IN ("cc0", "public-domain", "pd"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_cc0pd,

---- first oa_date and version = accpub, with license
(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('publishedVersion', 'acceptedVersion'))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_accpub,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('publishedVersion', 'acceptedVersion') and STARTS_WITH(l.license, "cc"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_accpub_cc,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('publishedVersion', 'acceptedVersion') and l.license="cc-by")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_accpub_ccby,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('publishedVersion', 'acceptedVersion') and l.license="cc-by-nd")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_accpub_ccbynd,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('publishedVersion', 'acceptedVersion') and l.license IN ("cc0", "public-domain", "pd"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_accpub_cc0pd,

---- first oa_date and version = sub, with license
(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('submittedVersion'))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_sub,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('submittedVersion') and STARTS_WITH(l.license, "cc"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_sub_cc,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('submittedVersion') and l.license="cc-by")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_sub_ccby,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('submittedVersion') and l.license="cc-by-nd")
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_sub_ccbynd,

(
SELECT l.oa_date
FROM UNNEST(u.oa_locations) as l
WHERE (l.host_type="repository" and l.version IN ('submittedVersion') and l.license IN ("cc0", "public-domain", "pd"))
ORDER BY l.oa_date ASC NULLS LAST LIMIT 1
)
as first_green_oa_sub_cc0pd,


--- FROM `academic-observatory.unpaywall.unpaywall_snapshot20231127` as u --- this was the version used for the baseline report
FROM `academic-observatory.unpaywall.unpaywall` as u -- this is always the most current version 

),


--- STEP 1D - Add OA information from Unpaywall to DOIs in corpus

TABLE_OA_INFORMATION AS (

SELECT

a.*,
b.* EXCEPT (doi)

FROM TABLE_DOIS_DATE as a
LEFT JOIN TABLE_UNPAYWALL as b
ON UPPER(TRIM(a.doi)) = UPPER(TRIM(b.doi))

),


--- STEP 1E - Calculate embargo periods 
--- First, calculate raw embargo periods first (difference between created date and first oa date for green oa, in days divided by 30), for each subgroup of green OA (based on version and license) separately
--- Then, round down (for positive embargoes) or up (for negative embargoes) to whole months 
--- Finally, replace first oa date with rounded embargo times in table with oa information

TABLE_EMBARGO_RAW AS (
SELECT

doi,
SAFE_DIVIDE(DATE_DIFF(first_green_oa, cr_created_date, DAY), 30) as embargo_green_oa,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_cc, cr_created_date, DAY), 30) as embargo_green_oa_cc,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_ccby, cr_created_date, DAY), 30) as embargo_green_oa_ccby,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_ccbynd, cr_created_date, DAY), 30) as embargo_green_oa_ccbynd,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_cc0pd, cr_created_date, DAY), 30) as embargo_green_oa_cc0pd,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_accpub, cr_created_date, DAY), 30) as embargo_green_oa_accpub,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_accpub_cc, cr_created_date, DAY), 30) as embargo_green_oa_accpub_cc,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_accpub_ccby, cr_created_date, DAY), 30) as embargo_green_oa_accpub_ccby,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_accpub_ccbynd, cr_created_date, DAY), 30) as embargo_green_oa_accpub_ccbynd,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_accpub_cc0pd, cr_created_date, DAY), 30) as embargo_green_oa_accpub_cc0pd,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_sub, cr_created_date, DAY), 30) as embargo_green_oa_sub,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_sub_cc, cr_created_date, DAY), 30) as embargo_green_oa_sub_cc,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_sub_ccby, cr_created_date, DAY), 30) as embargo_green_oa_sub_ccby,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_sub_ccbynd, cr_created_date, DAY), 30) as embargo_green_oa_sub_ccbynd,
SAFE_DIVIDE(DATE_DIFF(first_green_oa_sub_cc0pd, cr_created_date, DAY), 30) as embargo_green_oa_sub_cc0pd

FROM TABLE_OA_INFORMATION
),

TABLE_EMBARGO_ROUNDED AS (

SELECT

doi,

CASE WHEN embargo_green_oa > 0 THEN FLOOR(embargo_green_oa)
WHEN embargo_green_oa < 0 THEN CEILING(embargo_green_oa)
ELSE embargo_green_oa END as embargo_green_oa,
CASE WHEN embargo_green_oa_cc > 0 THEN FLOOR(embargo_green_oa_cc)
WHEN embargo_green_oa_cc < 0 THEN CEILING(embargo_green_oa_cc)
ELSE embargo_green_oa_cc END as embargo_green_oa_cc,

CASE WHEN embargo_green_oa_ccby > 0 THEN FLOOR(embargo_green_oa_ccby)
WHEN embargo_green_oa_ccby < 0 THEN CEILING(embargo_green_oa_ccby)
ELSE embargo_green_oa_ccby END as embargo_green_oa_ccby,

CASE WHEN embargo_green_oa_ccbynd > 0 THEN FLOOR(embargo_green_oa_ccbynd)
WHEN embargo_green_oa_ccbynd < 0 THEN CEILING(embargo_green_oa_ccbynd)
ELSE embargo_green_oa_ccbynd END as embargo_green_oa_ccbynd,

CASE WHEN embargo_green_oa_cc0pd > 0 THEN FLOOR(embargo_green_oa_cc0pd)
WHEN embargo_green_oa_cc0pd < 0 THEN CEILING(embargo_green_oa_cc0pd)
ELSE embargo_green_oa_cc0pd END as embargo_green_oa_cc0pd,

----

CASE WHEN embargo_green_oa_accpub > 0 THEN FLOOR(embargo_green_oa_accpub)
WHEN embargo_green_oa_accpub < 0 THEN CEILING(embargo_green_oa_accpub)
ELSE embargo_green_oa_accpub END as embargo_green_oa_accpub,
CASE WHEN embargo_green_oa_accpub_cc > 0 THEN FLOOR(embargo_green_oa_accpub_cc)
WHEN embargo_green_oa_accpub_cc < 0 THEN CEILING(embargo_green_oa_accpub_cc)
ELSE embargo_green_oa_accpub_cc END as embargo_green_oa_accpub_cc,

CASE WHEN embargo_green_oa_accpub_ccby > 0 THEN FLOOR(embargo_green_oa_accpub_ccby)
WHEN embargo_green_oa_accpub_ccby < 0 THEN CEILING(embargo_green_oa_accpub_ccby)
ELSE embargo_green_oa_accpub_ccby END as embargo_green_oa_accpub_ccby,

CASE WHEN embargo_green_oa_accpub_ccbynd > 0 THEN FLOOR(embargo_green_oa_accpub_ccbynd)
WHEN embargo_green_oa_accpub_ccbynd < 0 THEN CEILING(embargo_green_oa_accpub_ccbynd)
ELSE embargo_green_oa_accpub_ccbynd END as embargo_green_oa_accpub_ccbynd,

CASE WHEN embargo_green_oa_accpub_cc0pd > 0 THEN FLOOR(embargo_green_oa_accpub_cc0pd)
WHEN embargo_green_oa_accpub_cc0pd < 0 THEN CEILING(embargo_green_oa_accpub_cc0pd)
ELSE embargo_green_oa_accpub_cc0pd END as embargo_green_oa_accpub_cc0pd,

----

CASE WHEN embargo_green_oa_sub > 0 THEN FLOOR(embargo_green_oa_sub)
WHEN embargo_green_oa_sub < 0 THEN CEILING(embargo_green_oa_sub)
ELSE embargo_green_oa_sub END as embargo_green_oa_sub,
CASE WHEN embargo_green_oa_sub_cc > 0 THEN FLOOR(embargo_green_oa_sub_cc)
WHEN embargo_green_oa_sub_cc < 0 THEN CEILING(embargo_green_oa_sub_cc)
ELSE embargo_green_oa_sub_cc END as embargo_green_oa_sub_cc,

CASE WHEN embargo_green_oa_sub_ccby > 0 THEN FLOOR(embargo_green_oa_sub_ccby)
WHEN embargo_green_oa_sub_ccby < 0 THEN CEILING(embargo_green_oa_sub_ccby)
ELSE embargo_green_oa_sub_ccby END as embargo_green_oa_sub_ccby,

CASE WHEN embargo_green_oa_sub_ccbynd > 0 THEN FLOOR(embargo_green_oa_sub_ccbynd)
WHEN embargo_green_oa_sub_ccbynd < 0 THEN CEILING(embargo_green_oa_sub_ccbynd)
ELSE embargo_green_oa_sub_ccbynd END as embargo_green_oa_sub_ccbynd,

CASE WHEN embargo_green_oa_sub_cc0pd > 0 THEN FLOOR(embargo_green_oa_sub_cc0pd)
WHEN embargo_green_oa_sub_cc0pd < 0 THEN CEILING(embargo_green_oa_sub_cc0pd)
ELSE embargo_green_oa_sub_cc0pd END as embargo_green_oa_sub_cc0pd,

FROM TABLE_EMBARGO_RAW

),

TABLE_EMBARGO_JOIN AS (

SELECT a.* EXCEPT (
first_green_oa,
first_green_oa_cc,
first_green_oa_ccby,
first_green_oa_ccbynd,
first_green_oa_cc0pd,
first_green_oa_accpub,
first_green_oa_accpub_cc,
first_green_oa_accpub_ccby,
first_green_oa_accpub_ccbynd,
first_green_oa_accpub_cc0pd,
first_green_oa_sub,
first_green_oa_sub_cc,
first_green_oa_sub_ccby,
first_green_oa_sub_ccbynd,
first_green_oa_sub_cc0pd
),
b.* EXCEPT (doi)

FROM TABLE_OA_INFORMATION as a
LEFT JOIN TABLE_EMBARGO_ROUNDED as b
USING (doi)

),

--- STEP 1F - Final OA classification 
--- Assigning T/F values for each class 
--- This includes more variables (e.g. for submitted versions as green oa) then included in final dataset 

TABLE_OA_CLASSIFICATION AS (

SELECT	
	
doi,	
	
CASE WHEN publisher AND journal_is_in_doaj THEN true ELSE false END as gold_doaj,	
CASE WHEN publisher AND journal_is_oa AND journal_is_in_doaj is false THEN true ELSE false END as gold_non_doaj,	
CASE WHEN publisher_license AND journal_is_oa is false AND journal_is_in_doaj is false THEN true ELSE false END as hybrid,	
CASE WHEN publisher AND publisher_license is false AND journal_is_oa is false AND journal_is_in_doaj is false THEN true ELSE false END as bronze,	
	
CASE WHEN repository THEN true ELSE false END as green,	
CASE WHEN repository_accpub THEN true ELSE false END as green_accpub,	
CASE WHEN repository_sub AND repository_accpub is false THEN true ELSE false END as green_sub,	
	
CASE WHEN publisher_license is false AND repository THEN true ELSE false END as green_only,	
CASE WHEN publisher_license is false AND repository_accpub THEN true ELSE false END as green_only_accpub,	
CASE WHEN publisher_license is false AND repository_sub AND repository_accpub is false THEN true ELSE false END as green_only_sub,	
	
--- license compliance (NB already implies publisher is true (and publisher_license is true), so can omit that clause)	
CASE WHEN journal_is_in_doaj AND (publisher_ccby OR publisher_ccbynd OR publisher_cc0pd) THEN true ELSE false END as gold_doaj_license,	
CASE WHEN journal_is_oa AND journal_is_in_doaj is false AND (publisher_ccby OR publisher_ccbynd OR publisher_cc0pd) THEN true ELSE false END as gold_non_doaj_license,	
CASE WHEN journal_is_oa is false AND journal_is_in_doaj is false AND (publisher_ccby OR publisher_ccbynd OR publisher_cc0pd) THEN true ELSE false END as hybrid_license,	
	
CASE WHEN repository AND (repository_ccby OR repository_ccbynd OR repository_cc0pd) THEN true ELSE false END as green_license,	
CASE WHEN repository_accpub AND (repository_accpub_ccby OR repository_accpub_ccbynd OR repository_accpub_cc0pd) THEN true ELSE false END as green_accpub_license,	
CASE WHEN repository_sub AND repository_accpub is false AND (repository_sub_ccby OR repository_sub_ccbynd OR repository_sub_cc0pd) THEN true ELSE false END as green_sub_license,	
	
CASE WHEN publisher_license is false AND repository AND (repository_ccby OR repository_ccbynd OR repository_cc0pd) THEN true ELSE false END as green_only_license,	
CASE WHEN publisher_license is false AND repository_accpub AND (repository_accpub_ccby OR repository_accpub_ccbynd OR repository_accpub_cc0pd) THEN true ELSE false END as green_only_accpub_license,	
CASE WHEN publisher_license is false AND repository_sub AND repository_accpub is false AND (repository_sub_ccby OR repository_sub_ccbynd OR repository_sub_cc0pd) THEN true ELSE false END as green_only_sub_license,	
	
---- green embargo compliance	
CASE WHEN repository AND (embargo_green_oa < 1) THEN true ELSE false END as green_embargo,	
CASE WHEN repository_accpub AND (embargo_green_oa_accpub < 1) THEN true ELSE false END as green_accpub_embargo,	
CASE WHEN repository_sub AND repository_accpub is false AND (embargo_green_oa_sub < 1) THEN true ELSE false END as green_sub_embargo,	
	
CASE WHEN publisher_license is false AND repository AND (embargo_green_oa < 1) THEN true ELSE false END as green_only_embargo,	
CASE WHEN publisher_license is false AND repository_accpub AND (embargo_green_oa_accpub < 1) THEN true ELSE false END as green_only_accpub_embargo,	
CASE WHEN publisher_license is false AND repository_sub AND repository_accpub is false AND (embargo_green_oa_sub < 1) THEN true ELSE false END as green_only_sub_embargo,	
	
---- green embargo + license compliance	
CASE WHEN repository AND (embargo_green_oa_ccby < 1 OR embargo_green_oa_ccbynd < 1 OR embargo_green_oa_cc0pd < 1) THEN true ELSE false END as green_license_embargo,	
CASE WHEN repository_accpub AND (embargo_green_oa_accpub_ccby < 1 OR embargo_green_oa_accpub_ccbynd < 1 OR embargo_green_oa_accpub_cc0pd < 1) THEN true ELSE false END as green_accpub_license_embargo,	
CASE WHEN repository_sub AND repository_accpub is false AND (embargo_green_oa_sub_ccby < 1 OR embargo_green_oa_sub_ccbynd < 1 OR embargo_green_oa_sub_cc0pd < 1) THEN true ELSE false END as green_sub_license_embargo,	
	
CASE WHEN publisher_license is false AND repository AND (embargo_green_oa_ccby < 1 OR embargo_green_oa_ccbynd < 1 OR embargo_green_oa_cc0pd < 1) THEN true ELSE false END as green_only_license_embargo,	
CASE WHEN publisher_license is false AND repository_accpub AND (embargo_green_oa_accpub_ccby < 1 OR embargo_green_oa_accpub_ccbynd < 1 OR embargo_green_oa_accpub_cc0pd < 1) THEN true ELSE false END as green_only_accpub_license_embargo,	
CASE WHEN publisher_license is false AND repository_sub AND repository_accpub is false AND (embargo_green_oa_sub_ccby < 1 OR embargo_green_oa_sub_ccbynd < 1 OR embargo_green_oa_sub_cc0pd < 1) THEN true ELSE false END as green_only_sub_license_embargo,	
	
	
FROM TABLE_EMBARGO_JOIN

)

SELECT * FROM TABLE_OA_CLASSIFICATION

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_oa_classification`
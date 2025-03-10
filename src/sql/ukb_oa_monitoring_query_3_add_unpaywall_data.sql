---------------------------------
--- Add Unpaywall data
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 3 - Add OA data from Unpaywall, calculate embargo for each repository location
--------------------------------------------------------------------------------------

--- create table with selected variables from Unpaywall
WITH TABLE_UPW AS (

SELECT

doi,
oa_status,
journal_is_in_doaj,
journal_is_oa,
l.host_type,
l.version,
l.license,
l.oa_date,
l.repository_institution,
NET.HOST(l.url) as host_url,
NET.HOST(l.url_for_landing_page) as host_url_for_landing_page,
NET.HOST(l.url_for_pdf) as host_url_for_pdf,


FROM `UKB_OA_2023.unpaywall_20240801` --- archived snapshot from daily feed
LEFT JOIN UNNEST(oa_locations) as l

),

--- join to basic table with doi and created date only (too limit complwxity when aggregating location data)
TABLE_UPW_JOIN AS (

SELECT

a.doi_cleaned,
a.crossref.cr_created_date,
CASE WHEN b.doi is not null THEN TRUE ELSE FALSE END as upw_included,
b.* EXCEPT (doi)

FROM `UKB_OA_2023.all_2023_dois_crossref` as a
LEFT JOIN TABLE_UPW as b
ON UPPER(TRIM(a.doi_cleaned)) = UPPER(TRIM(b.doi))

),

--- calculate wmbargo in months (for each repository location)
TABLE_UPW_EMBARGO AS (

SELECT

*,
CASE WHEN host_type = 'repository'
THEN SAFE_DIVIDE(DATE_DIFF(oa_date, cr_created_date, DAY), 30)
ELSE null
END as embargo_green_oa


FROM TABLE_UPW_JOIN

),

--- aggregate locations by doi
TABLE_AGG_LOCATIONS AS (

SELECT

doi_cleaned,
upw_included,
oa_status,
journal_is_in_doaj,
journal_is_oa,
ARRAY_AGG(STRUCT(
host_type,
version,
license,
oa_date,
embargo_green_oa,
repository_institution,
host_url,
host_url_for_landing_page,
host_url_for_pdf
)) as oa_locations

FROM TABLE_UPW_EMBARGO

GROUP BY
doi_cleaned,
upw_included,
oa_status,
journal_is_in_doaj,
journal_is_oa
),

--- create structured variable for all UPW information
TABLE_AGG_UPW AS (

SELECT

doi_cleaned,
STRUCT(
upw_included,
oa_status,
journal_is_in_doaj,
journal_is_oa,
oa_locations
) as unpaywall

FROM TABLE_AGG_LOCATIONS

),

--- join UPW variable to full database
TABLE_JOIN AS (

SELECT DISTINCT

a.doi_cleaned,
b.unpaywall

FROM `UKB_OA_2023.all_2023_dois_crossref` as a
LEFT JOIN TABLE_AGG_UPW as b
ON UPPER(TRIM(a.doi_cleaned)) = UPPER(TRIM(b.doi_cleaned))
)

SELECT * FROM TABLE_JOIN

--- saved as `UKB_OA_2023.all_2023_dois_unpaywall`
---------------------------------
--- Add OA classification (OA type, licenses, embargo, Taverne)
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 4B - Add license classification
--------------------------------------------------------------------------------------


--- cresta license classes for publisher and repository licenses separately
WITH TABLE_LICENSE AS (
SELECT

doi_cleaned,

--- publisher license
CASE WHEN (SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion' AND
l.license IN ("cc-by", "pd", "public-domain"))) > 0
THEN "has_license_cc_by"

WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion' AND
(l.license LIKE ("cc%") OR l.license IN ("pd", "public-domain")))) > 0
THEN "has_license_cc"

WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="publisher" AND l.version = 'publishedVersion' AND
l.license is not null)) > 0
THEN "has_license"

ELSE null END as publisher_license,

--- repository acc/pub license

CASE WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND
l.license IN ("cc-by", "pd", "public-domain"))) > 0
THEN "has_license_cc_by"


WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND
(l.license LIKE ("cc%") OR l.license IN ("pd", "public-domain")))) > 0
THEN "has_license_cc"

WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND l.version IN ('publishedVersion', 'acceptedVersion') AND
l.license is not null)) > 0
--- (l.license is not null AND NOT l.license = "other-oa"))) > 0
THEN "has_license"

ELSE null END as repository_acc_pub_license,

--- repository sub license

CASE WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND NOT l.version IN ('publishedVersion', 'acceptedVersion') AND
l.license IN ("cc-by", "pd", "public-domain"))) > 0
THEN "has_license_cc_by"


WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND NOT l.version IN ('publishedVersion', 'acceptedVersion') AND
(l.license LIKE ("cc%") OR l.license IN ("pd", "public-domain")))) > 0
THEN "has_license_cc"

WHEN
(SELECT COUNT(1) FROM UNNEST(unpaywall.oa_locations) as l WHERE
(l.host_type="repository" AND NOT l.version IN ('publishedVersion', 'acceptedVersion') AND
l.license is not null)) > 0
THEN "has_license"

ELSE null END as repository_sub_license,


FROM `UKB_OA_2023.all_2023_dois_unpaywall`
),


--- add license classification back to database as one structured variable 
TABLE_JOIN AS (

SELECT

a.doi_cleaned,

STRUCT(
b.publisher_license,
b.repository_acc_pub_license,
b.repository_sub_license
) as oa_license

FROM `UKB_OA_2023.all_2023_dois_unpaywall` as a
LEFT JOIN TABLE_LICENSE as b
USING (doi_cleaned)

)


SELECT * FROM TABLE_JOIN


---saved as `utrecht-university.UKB_OA_2023.all_2023_dois_license` 
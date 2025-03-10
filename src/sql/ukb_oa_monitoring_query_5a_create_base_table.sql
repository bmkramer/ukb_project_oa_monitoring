---------------------------------
--- Create export datasets
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 5A - Create base table for export (non-flat structure)
--------------------------------------------------------------------------------------

--- collect all variables (combine multiple datasets)
--- keep only variables used in export

WITH TABLE AS (

SELECT DISTINCT

a.doi_cleaned,
ARRAY(SELECT AS STRUCT i.* EXCEPT(issn_unidentified, e_issn, issn) FROM UNNEST(a.instance) as i) as instance, -- also keep org_agg in for now to (hopefully) ease creation of full dataset
a.kuoz_a as kuoz,
STRUCT(
b.crossref.cr_included,
b.crossref.cr_type,
b.crossref.cr_issued_year,
b.crossref.cr_created_date
) as crossref,
c.issn,
d.doaj,
STRUCT (
e.unpaywall.upw_included,
e.unpaywall.journal_is_oa,
ARRAY(SELECT AS STRUCT l.* EXCEPT(host_url_for_landing_page, host_url_for_pdf) FROM UNNEST(e.unpaywall.oa_locations) as l) as oa_locations
) as unpaywall,
f.oa_classification,
STRUCT(
f.oa_type.oa_type_extended,
f.oa_type.oa_type_compact
) as oa_type,
g.oa_license,
h.oa_embargo


FROM `UKB_OA_2023.all_2023_dois_instance` as a
LEFT JOIN `UKB_OA_2023.all_2023_dois_crossref` as b
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_issn` as c
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_doaj` as d
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_unpaywall` as e
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_oa_information` as f
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_license` as g
USING (doi_cleaned)
LEFT JOIN `UKB_OA_2023.all_2023_dois_embargo_taverne` as h
USING (doi_cleaned)

)

SELECT * FROM TABLE

---saved as `UKB_OA_2023.all_2023_export_base_table`
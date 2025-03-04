---------------------------------
--- Combine data
---------------------------------

SELECT

a.*,
b.* EXCEPT (doi),
c.* EXCEPT (doi),
d.* EXCEPT (doi),
e.* EXCEPT (doi),
f.* EXCEPT (doi),
g.* EXCEPT (doi),
h.fields_string as fields --- only keep fields string, not array for table export as csv


FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus` as a
LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_oa_classification` as b
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_publishers` as c
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_collaborations` as d
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_citations` as e
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_views_downloads` as f
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_event_data` as g
USING(doi)

LEFT JOIN `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_fields` as h
USING(doi)

ORDER BY doi

--- saved as `ukri-oa-baseline.final.ukri_uk_2012_2022_articles_dataset_v1`
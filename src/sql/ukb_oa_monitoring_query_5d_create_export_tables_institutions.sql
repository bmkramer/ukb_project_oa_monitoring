---------------------------------
--- Create export datasets
---------------------------------

--------------------------------------------------------------------------------------
--- STEP 5D - Create export tables for institutions 
--------------------------------------------------------------------------------------

---- select specific organization, leave out variables that are not included in institutional export
WITH TABLE AS (
SELECT DISTINCT

* EXCEPT (uuid_unique, org_agg, kuoz_other)

FROM `UKB_OA_2023.all_2023_export_base_table_orgs_linked_og_data`

WHERE org_agg = "eur" --- org_name IN ("eur", "eumc")
---WHERE org_agg = "eut" --- org_name IN ("eut")
---WHERE org_agg = "lei" --- org_name IN ("lei", "lumc")
---WHERE org_agg = "ru" --- org_name IN ("ru", "rumc")
---WHERE org_agg = "til" --- org_name IN ("til")
---WHERE org_agg = "tud" --- org_name IN ("tud")
---WHERE org_agg = "ug" --- org_name IN ("ug", "umcg")
---WHERE org_agg = "um" --- org_name IN ("um", "mumc")
---WHERE org_agg = "ut" --- org_name IN ("ut")
---WHERE org_agg = "uu" --- org_name IN ("uu", 'uumc') --- but data provided separately for uni/umc
---WHERE org_name = "uu"
---WHERE org_name = "uumc"
---WHERE org_agg = "uva" --- org_name IN ("uva", 'aumc')
---WHERE org_agg = "vu" --- org_name IN ("vu", 'vumc') --- but data provided separately for uni/umc
---WHERE org_name = "vu"
---WHERE org_name = "vumc"
---WHERE org_agg = "wur" --- org_name IN ("wur")
---WHERE org_agg = "ou" --- org_name IN ("ou")
---WHERE org_agg = "uvh" --- org_name IN ("uvh")

),

--- table for manual counts check before export
TABLE_CHECK AS (

SELECT

count(*) as count,
count(distinct doi_cleaned) as dois_cleaned,
count(distinct if(cr_included AND kuoz = "A", doi_cleaned, null)) as dois_included,
count(distinct if(cr_included AND kuoz_a, doi_cleaned, null)) as dois_included_all

FROM TABLE

),

TABLE_EXPORT AS (

SELECT * FROM TABLE

)

---SELECT * FROM TABLE_CHECK
SELECT * FROM TABLE_EXPORT ORDER BY uuid
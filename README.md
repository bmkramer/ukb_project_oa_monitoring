# UKB project Update OA monitoring - peer-reviewed articles
Code documented here is used to generate the dataset accompanying the 2025 report  
*"Project vernieuwing open access monitoring - rapportage fase 1 - peer-reviewed artikelen" [in Dutch]*  
  
Report: [add link]  
Dataset: [add link]

## General description
The repository contains JSON files and SQL scripts used to collect bibliographic metadata on research output (journal articles with Crossref DOIs only) published in 2023 as provided by Dutch universities from their CRIS systems, as well as data on open access availability. 

This project makes use of **Curtin Open Knowledge Initiative (COKI)** infrastructure, which is documented on GitHub: https://github.com/The-Academic-Observatory. Here, a number of open data sources (including Crossref, OpenAlex and Unpaywall) are ingested into a **Google Big Query** environment, which can then be queried via SQL. Additional data sources can be ingested manually, and similarly queried via SQL.

## Data sources  
The scripts use the following data sources included in the COKI Google Big Query environment:

- **Crossref Metadata Plus** (data snapshot 2024-07-31), provided by Crossref (see https://www.crossref.org/services/metadata-retrieval/metadata-plus/)
- **Unpaywall** (data snapshot 2024-08-01), provided by OurResearch (see https://unpaywall.org/products/data-feed) 

In addition, a number of supplementary open data sources were manually added to the Google Big Query environment for this project. 
These are included in this repository in the folder [supplementary_sources](/supplementary_sources)

- **DOAJ journal metadata** - Journal metadata provided by DOAJ in CSV-format (https://doaj.org/docs/public-data-dump/), downloaded on 2023-12-31 (1 csv file). Data provided by DOAJ under a [CC BY-SA license](https://creativecommons.org/licenses/by-sa/4.0/). 
- **ISSN-L tables**  - Tables provided by the ISSN International Centre reciprocally matching ISSNs to ISSN-L (https://www.issn.org/services/online-services/access-to-issn-l-table/), downloaded on 2024-03-26 (3 txt files)

Finally, Dutch universities provided csv files with output from their CRIS systems, according to an agreed upon schema [add Zenodo link]. These were used to create the corpus of research outputs (peer-reviewed articles with Crossref DOI only) that formed the base of this project. The individual files as provided by universities are not included in this repository, but relevant metadata from these files is included in the dataset resulting from the project. 

## Workflow description

The SQL scripts in this repository, when run in the COKI Google Big Query environment as described above, generate intermediate tables in Google Big Query with the results of that particular query (bibliographic metadata, open access classfication, etc). The final SQL script combines these intermediate files by matching on DOIs. The resulting final dataset containing all variables can then be exported from Google Big Query as csv or JSON file. 

Scripts are lightly annotated to explain the different parts of the code.

### Step 1 - combine CRIS data 
- [ukb_oa_monitoring_cris_import_schema](/src/json/ukb_oa_monitoring_cris_import_schema.json) - json schema used to import university-provided CRIS data into Google Big Query
- [ukb_oa_monitoring_query_1a_combine_cris_data.sql](/src/sql/ukb_oa_monitoring_query_1a_combine_cris_data.sql) - combine imported CRIS tables, clean variables, add unique identifier
- [ukb_oa_monitoring_query_1b_aggregate_instances.sql](/src/sql/ukb_oa_monitoring_query_1b_aggregate_instances.sql) - aggregate instances by DOI
### Step 2 - add bibliographic data
- [ukb_oa_monitoring_query_2a_add_crossref_metadata.sql](/src/sql/ukri_oa_baseline_query_2a_add_crossref_metadata.sql) - add metadata from Crossref (type, issued year, created date)
- [ukb_oa_monitoring_query_2b_add_issn.sql](/src/sql/ukri_oa_baseline_query_2b_add_issn.sql) - add ISSNs from Crossref, match to ISSN-L 
- [ukb_oa_monitoring_query_2c_add_doaj_metadata.sql](/src/sql/ukri_oa_baseline_query_2c_add_doaj_metadata.sql) - add metadata from DOAJ, match on ISSN/ISSN-L 
### Step 3 - add Unpaywall data
- [ukb_oa_monitoring_query_3_add_unpaywall_data.sql](/src/sql/ukb_oa_monitoring_query_3_add_unpaywall_data.sql) - add OA data from Unpaywall, calculate embargo for each repository location
### Step 4 - add OA classification 
- [ukb_oa_monitoring_query_4a_add_oa_types.sql](/src/sql/ukb_oa_monitoring_query_4a_add_oa_types.sql) - add OA types
- [ukb_oa_monitoring_query_4b_add_license_classification.sql](/src/sql/ukb_oa_monitoring_query_4b_add_license_classification.sql) - add OA license classification
- [ukb_oa_monitoring_query_4c_add_embargo_classification.sql](/src/sql/ukb_oa_monitoring_query_4c_add_embargo_classification.sql) - add OA embargo classification, include Taverne information
### Step 5 - create export datasets
- [ukb_oa_monitoring_query_5a_create_base_table.sql](/src/sql/ukb_oa_monitoring_query_5a_create_base_table.sql) - create base table for export (non-flat structure)
- [ukb_oa_monitoring_query_5b_ungroup_variables.sql](/src/sql/ukb_oa_monitoring_query_5b_ungroup_variables.sql) - ungroup variables and create comma-separated strings
- [ukb_oa_monitoring_query_5c_link_back_instances.sql](/src/sql/ukb_oa_monitoring_query_5c_link_back_instances.sql) - ungroup instances, link back to original instance data  
- [ukb_oa_monitoring_query_5d_create_export_tables_institutions.sql](/src/sql/ukb_oa_monitoring_query_5d_create_export_tables_institutions.sql) - create export tables for institutions 
- to be added: script to generate full dataset for export (pending decision on included variables)


Separate SQL scripts are provided to create aggregated OA information (OA types, licenses, embargoes) at national and institutional level. These are currently using intermediate tables, but can be rewritten to use export table instead.

### Step 6 - aggregate counts
- [ukb_oa_monitoring_query_6a_aggregate_oa_types.sql](/src/sql/ukb_oa_monitoring_query_6a_aggregate_oa_types.sql) - aggregate data - OA types
- [ukb_oa_monitoring_query_6b_aggregate_licenses.sql](/src/sql/ukb_oa_monitoring_query_6b_aggregate_licenses.sql) - aggregate data - license summary
- [ukb_oa_monitoring_query_6c_aggregate_license_summary.sql](/src/sql/ukb_oa_monitoring_query_6c_aggregate_license_summary.sql) - aggregate data - license summary
- to be added: script to generate aggregate counts for embargo periods and Taverne

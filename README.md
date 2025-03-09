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

- **DOAJ journal metadata** - Journal metadata provided by DOAJ in CSV-format (https://doaj.org/docs/public-data-dump/), downloaded on 2023-12-31 (1 csv file).
- **ISSN-L tables**  - Tables provided by the ISSN International Centre reciprocally matching ISSNs to ISSN-L (https://www.issn.org/services/online-services/access-to-issn-l-table/), downloaded on 2024-03-26 (3 txt files)

Finally, Dutch universities provided csv files with output from their CRIS systems which were used as to create the corpus of research outputs (peer-reviewed articles with Crossref DOI only). The individual files as provided by universities are not included in this repository, but relevant metadata from these files is included in the dataset resulting from the project. 

## Workflow description

The SQL scripts in this repository, when run in the COKI Google Big Query environment as described above, each generate an intermediate table in Google Big Query with the results of that particular query for each record in the dataset (bibliographic metadata, open access classfication, etc). The final SQL script combines all intermediate files by matching on DOIs. The resulting final dataset containing all variables can then be exported from Google Big Query as csv or JSON file. 

All scripts are annotated to explain the different parts of the code. [in progress]

### Step 1 - combine CRIS data 
- [ukb_oa_monitoring_cris_import_schema](/src/json/ukb_oa_monitoring_cris_import_schema.json) - json schema used to import university-provided CRIS data into Google Big Query
- [ukb_oa_monitoring_query_1a_corpus.sql](/src/sql/ukri_oa_baseline_query_1_corpus.sql) - collect bibliographic metadata for UKRI-funded and UK-affiliated journal articles from Gateway to Research, Crossref and OpenAlex (limited to publications with Crossref DOI)
### Step 2
[ukb_oa_monitoring_query_2_oa_classification.sql](/src/sql/ukri_oa_baseline_query_2_oa_classification.sql) - for each record, collect open access information from Unpaywall
### Step 3
[ukb_oa_monitoring_query_3_publishers.sql](/src/sql/ukri_oa_baseline_query_3_publishers.sql) - for each record, collect publisher information from Crossref
### Step 4
[ukb_oa_monitoring_query_4_collaborations.sql](/src/sql/ukri_oa_baseline_query_4_collaborations.sql) - for each record, collect information on national and international collaborations from OpenAlex
### Step 5
[ukb_oa_monitoring_query_5_citations.sql](/src/sql/ukri_oa_baseline_query_5_citations.sql) - for each record, collect citation information from OpenAlex
### Step 6
[ukb_oa_monitoring_query_6_views_downloads.sql](/src/sql/ukri_oa_baseline_query_6_views_downloads.sql) - for each record, collect usage information (views and downloads) from IRUS-UK
### Step 7
[ukb_oa_monitoring_query_7_event_data.sql](/src/sql/ukri_oa_baseline_query_7_event_data.sql) - for each record, collect altmetrics information (Twitter, newsfeeds, Reddit links, Wikipedia) from Crossref Event Data
### Step 8
[ukb_oa_monitoring_query_8_fields.sql](/src/sql/ukri_oa_baseline_query_8_fields.sql) - for each record, collect subject classification from OpenAlex
### Step 9
[ukb_oa_monitoring_query_9_combine_data.sql](/src/sql/ukri_oa_baseline_query_9_combine_data.sql) - combine all intermediate files by matching on DOI

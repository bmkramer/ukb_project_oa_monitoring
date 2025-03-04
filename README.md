# UKRI OA baseline values - exploration using open data sources

Code documented here is used to generate the dataset accompanying the 2024 report  
*"Monitoring and evaluation of UKRI's Open Access Policy: Exploring the use of open data sources to inform baseline values"*  
  
Report:  https://doi.org/10.5281/zenodo.12804855  
Dataset: https://doi.org/10.5281/zenodo.12801805

## General description
The repository contains SQL scripts used to collect bibliographic metadata of UKRI-funded and UK-affiliated research output (journal articles only) published between 2012 and 2022, as well as data on open access availability, publisher, national and international collaborations, citations, views and downloads, altmetrics and subjects (fields). 

This project makes use of **Curtin Open Knowledge Initiative (COKI)** infrastructure, which is documented on GitHub: https://github.com/The-Academic-Observatory. Here, a number of open data sources (including Crossref, OpenAlex and Unpaywall) are ingested into a **Google Big Query** environment, which can then be queried via SQL. Additional data sources can be ingested manually, and similarly queried via SQL.

## Data sources  
The scripts use the following data sources included in the COKI Google Big Query environment:

- **Crossref Metadata Plus** (data snapshot 2023-10-31), provided by Crossref (see https://www.crossref.org/services/metadata-retrieval/metadata-plus/)
- **OpenAlex** (data snapshot 2023-10-18), provided by OurResearch via Amazon AWS (see https://docs.openalex.org/download-all-data/openalex-snapshot)
- **Unpaywall** (data snapshot 2023-11-27), provided by OurResearch (see https://unpaywall.org/products/data-feed)
- **Crossref Event Data** (data snapshot 2023-04-01), provided by Crossref (see https://www.crossref.org/documentation/event-data/)  
and integrated in the aggregate DOI table in COKI Google Big Query  

In addition, a number of supplementary open data sources were manually added to the Google Big Query environment for this project. 
These are included in this repository in the folder [supplementary_sources](/supplementary_sources)

- **Gateway to Research** - data on UKRI-funded publications for publication years 2012-2022 (11 csv files), downloaded from Gateway to Research web UI (https://gtr.ukri.org/) between 2023-11-05 and 2023-11-13. 
Data made available by UKRI under an [Open Government Licence (OGL)](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
- **Crossref member data** - Crossref member IDs and publisher names, created by querying Crossref member route API (https://api.crossref.org/swagger-ui/index.html#/Members) on 2024-01-23 (1 csv file).
- **IRUS UK data** - Usage metrics collected through IRUS_UK web UI (https://irus.jisc.ac.uk/r5/report/item/irus_ir_master/) on 2023-04-03, for all items with type 'article' in repositories included in IRUS UK which saw at least one type of usage (views or downloads) in the period Jan-Dec 2023 (1 csv file, zipped). Data made available by Jisc under a [CC BY-NC 4.0 licence](https://creativecommons.org/licenses/by-nc/4.0/).

## Workflow description

The SQL scripts in this repository, when run in the COKI Google Big Query environment as described above, each generate an intermediate table in Google Big Query with the results of that particular query for each record in the dataset (bibliographic metadata, open access classfication, etc). The final SQL script combines all intermediate files by matching on DOIs. The resulting final dataset containing all variables can then be exported from Google Big Query as csv file. 

All scripts are annotated to explain the different parts of the code. 

### Step 1 
[ukri_oa_baseline_query_1_corpus.sql](/src/sql/ukri_oa_baseline_query_1_corpus.sql) - collect bibliographic metadata for UKRI-funded and UK-affiliated journal articles from Gateway to Research, Crossref and OpenAlex (limited to publications with Crossref DOI)
### Step 2
[ukri_oa_baseline_query_2_oa_classification.sql](/src/sql/ukri_oa_baseline_query_2_oa_classification.sql) - for each record, collect open access information from Unpaywall
### Step 3
[ukri_oa_baseline_query_3_publishers.sql](/src/sql/ukri_oa_baseline_query_3_publishers.sql) - for each record, collect publisher information from Crossref
### Step 4
[ukri_oa_baseline_query_4_collaborations.sql](/src/sql/ukri_oa_baseline_query_4_collaborations.sql) - for each record, collect information on national and international collaborations from OpenAlex
### Step 5
[ukri_oa_baseline_query_5_citations.sql](/src/sql/ukri_oa_baseline_query_5_citations.sql) - for each record, collect citation information from OpenAlex
### Step 6
[ukri_oa_baseline_query_6_views_downloads.sql](/src/sql/ukri_oa_baseline_query_6_views_downloads.sql) - for each record, collect usage information (views and downloads) from IRUS-UK
### Step 7
[ukri_oa_baseline_query_7_event_data.sql](/src/sql/ukri_oa_baseline_query_7_event_data.sql) - for each record, collect altmetrics information (Twitter, newsfeeds, Reddit links, Wikipedia) from Crossref Event Data
### Step 8
[ukri_oa_baseline_query_8_fields.sql](/src/sql/ukri_oa_baseline_query_8_fields.sql) - for each record, collect subject classification from OpenAlex
### Step 9
[ukri_oa_baseline_query_9_combine_data.sql](/src/sql/ukri_oa_baseline_query_9_combine_data.sql) - combine all intermediate files by matching on DOI

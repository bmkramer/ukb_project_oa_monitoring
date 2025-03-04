---------------------------------
--- Event Data
---------------------------------

--- STEP 1A - Take DOIs from corpus

WITH TABLE_DOIS AS (

SELECT

doi,

FROM `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_corpus`
),

--- STEP 1B -Add Crossref Event Data from COKI DOI table

--- In future iterations, data from the new Crossref relationship endpoint should be used, as the Event Data endpoint will be sunsetted once the relationship endpoint is fully operational
--- As this part was for proof of concept only, Crossref Event Data were used as integrated by COKI in their aggregate DOI table. This code thus cannot be run as standalone code on an Event Data snapshot directly
---  The latest data snapshot of Event Data available in COKI infrastructure is dated 2023-04-01, and includes Twitter data up to February 2023. 

TABLE_EVENTS AS (

SELECT DISTINCT

a.*,
(SELECT event.count FROM UNNEST(b.events.events) as event WHERE event.source = "twitter") as events_twitter,
(SELECT event.count FROM UNNEST(b.events.events) as event WHERE event.source = "wikipedia") as events_wikipedia,
(SELECT event.count FROM UNNEST(b.events.events) as event WHERE event.source = "newsfeed") as events_newsfeed,
(SELECT event.count FROM UNNEST(b.events.events) as event WHERE event.source = "reddit-links") as events_reddit_links,


FROM TABLE_DOIS as a
LEFT JOIN `academic-observatory.observatory.doi20231119` as b
ON UPPER(a.doi) = UPPER(b.doi)

)

SELECT * FROM TABLE_EVENTS

--- saved as `ukri-oa-baseline.intermediate.ukri_uk_2012_2022_event_data`
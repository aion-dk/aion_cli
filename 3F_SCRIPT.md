# 3F script in Electa setup
> Written based on run performed in 2025

## Prerequisites:
- Ruby installed to run aion_cli library (v2.5.3)
- Single CSV of all the raw votes combined
- JSON file containing the eligible voter counts

### Combined raw votes file
You need to have a single CSV of all the raw votes combined. This can be achieved via the following command
```
bundle exec aion table concat CSV_FILES..
```
### Eligible voters JSON
The JSON with eligible voter counts can be downloaded through an endpoint on Electa looking like this:
`https://electa.assemblyvoting.net/{ORG_SLUG}/{ELECTION_SLUG}/eligible_voters`

## Running the stats script
You run the script with the following command:
```
bundle exec aion data stats_3f CSV_FILE JSON_FILE
```
You are asked to specify the column that matches the requested data. Depending on the columns of the csv it will look something like this:
```
AREA NUMBER        -->  9) Områdenr
AREA TEXT          -->  11) Områdetekst
DEPARTMENT NUMBER  -->  10) Afdelingsnr
PROFESSION NUMBER  -->  8) Faggruppe
GROUP MAPPING      -->  7) Group
```
Two `.xlsx` files are generated:
- Overall statistics - Contains statistics for each of the large voter groups
- Profession statistics - Contains statistics for each department intersected with each profession
# ATP Tennis Database Engineering

A privacy-safe portfolio reconstruction of a team data-engineering project. It turns player-level tennis match records into a normalized MySQL model and answers four analytical questions about countries, tournaments, win rates and court surfaces.

The public version contains only fictitious players, tournaments and cities. The original exports, database dumps, reports and presentation files are intentionally excluded.

## What this project demonstrates

- MongoDB aggregation for selecting and renaming source fields
- Reproducible CSV ingestion into a MySQL staging table
- Text, date and numeric normalization with MySQL 8
- Referential integrity across a relational model
- Analytical SQL with common table expressions and explicit ranking rules
- Safe portfolio publishing without redistributing the source dataset

## Pipeline

```text
MongoDB source collection
        |
        v
Field projection and naming cleanup
        |
        v
CSV export -> MySQL staging table
        |
        v
Typed cleaning and normalization
        |
        v
Countries, hands, players, surfaces, rounds, tournaments and events
        |
        v
Four analytical queries
```

The fact table, `tournament_events`, has foreign keys to every modeled dimension, including `players`. Player identity uses the combination of player name and birth country instead of assuming names are globally unique.

## Repository structure

```text
data/
  atp_matches_synthetic.csv    Fictitious 30-row demonstration dataset
  README.md                    Data dictionary and publication policy
mongodb/
  01_project_players.js        MongoDB projection used before CSV export
sql/
  00_staging_schema.sql        Database and raw staging table
  01_load_synthetic_data.sql   Repeatable sample-data import
  02_clean_and_normalize.sql   Typed cleaning and relational model
  03_analytics_queries.sql     Corrected analytical questions
```

## Run the synthetic demonstration

Requirements: MySQL 8.0 or newer. Start the MySQL client from this project directory so that the relative CSV path resolves correctly:

```text
mysql --local-infile=1 -u YOUR_USER -p
```

Then run:

```sql
SOURCE sql/00_staging_schema.sql;
SOURCE sql/01_load_synthetic_data.sql;
SOURCE sql/02_clean_and_normalize.sql;
SOURCE sql/03_analytics_queries.sql;
```

If the client was started elsewhere, replace `data/atp_matches_synthetic.csv` in the load script with its absolute path. The normalization script ends with validation counts; both staging and fact tables should contain 30 rows.

## Analytical questions

1. For each country, how many players, tournaments, matches and distinct rounds are represented?
2. Which players have the highest win percentage, subject to a minimum match count?
3. Which left-handed players have the highest win percentage in Grand Slam-category events?
4. Which players have the most wins on hard courts?

The ranking queries calculate the requested percentage before applying `LIMIT`, so the selected top players match the stated metric.

## MongoDB preparation

Run `mongodb/01_project_players.js` in `mongosh` against a collection named `atpplayers`. It writes a projected collection named `atp_export`. That collection can be exported with field names matching the MySQL staging table. The synthetic CSV already uses this public schema, so MongoDB is optional for the demonstration.

## Data and privacy

The original project referenced historical ATP data. No original row, real athlete name, student identifier, collaborator name, course document or media file is included here. The real dataset's redistribution terms were not established, so anyone adapting the pipeline must obtain their own authorized source and review its terms.

See [data/README.md](data/README.md) for the synthetic-data declaration and field definitions.

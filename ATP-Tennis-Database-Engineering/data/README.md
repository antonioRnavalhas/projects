# Data notes

`atp_matches_synthetic.csv` is a small, fully synthetic dataset created only to exercise the public pipeline.

- 30 fictitious player-match records
- 6 generic player labels (`Player Alpha` through `Player Zeta`)
- fictitious city and tournament names
- no original identifiers, measurements or match results
- real country names and standard tennis categories are used only as reference values

The original project data is not included because its redistribution terms were not established and a full export would be inappropriate for a public portfolio.

## Schema

| Field | Meaning |
| --- | --- |
| `record_id` | Synthetic source-row identifier |
| `player_name` | Fictitious player label |
| `birth_location` | Synthetic city plus country |
| `height_cm` | Synthetic height used to test numeric conversion |
| `hand` | Dominant-hand and backhand description |
| `tournament` | Fictitious tournament name |
| `tournament_category` | `Grand Slam`, `Masters 1000`, `ATP 500` or `ATP 250` |
| `event_location` | Synthetic city plus country |
| `date_range` | Event dates in `YYYY.MM.DD - YYYY.MM.DD` format |
| `surface` | `Hard`, `Clay` or `Grass` |
| `prize_usd` | Synthetic numeric prize value |
| `round_name` | Tournament round |
| `ranking` | Synthetic player ranking at the event |
| `opponent_name` | Fictitious opponent label |
| `result` | `W` or `L` from the row player's perspective |

Do not add raw CSV exports, SQL dumps, reports or presentations to this directory. The project-level `.gitignore` blocks common source-data and coursework artefacts by default.

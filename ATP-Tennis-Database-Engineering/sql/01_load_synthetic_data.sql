-- Start the MySQL client from the project root and enable LOCAL INFILE:
-- mysql --local-infile=1 -u YOUR_USER -p

USE atp_portfolio;

TRUNCATE TABLE atp_raw;

LOAD DATA LOCAL INFILE 'data/atp_matches_synthetic.csv'
INTO TABLE atp_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  record_id,
  player_name,
  birth_location,
  height_cm,
  hand,
  tournament,
  tournament_category,
  event_location,
  date_range,
  surface,
  prize_usd,
  round_name,
  ranking,
  opponent_name,
  @raw_result
)
SET result = TRIM(BOTH '\r' FROM @raw_result);

SELECT COUNT(*) AS staged_rows
FROM atp_raw;

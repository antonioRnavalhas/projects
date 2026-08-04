-- MySQL 8.0+
-- Converts permissive staging values into a typed, normalized model.

USE atp_portfolio;

DROP TEMPORARY TABLE IF EXISTS atp_clean;

CREATE TEMPORARY TABLE atp_clean AS
SELECT
  TRIM(record_id) AS record_id,
  COALESCE(NULLIF(TRIM(player_name), ''), 'Unknown Player') AS player_name,
  CASE
    WHEN NULLIF(REGEXP_REPLACE(COALESCE(height_cm, ''), '[^0-9]', ''), '') IS NULL
      THEN NULL
    ELSE CAST(REGEXP_REPLACE(height_cm, '[^0-9]', '') AS UNSIGNED)
  END AS height_cm,
  CASE UPPER(COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(hand, ',', 1)), ''), 'UNKNOWN'))
    WHEN 'LEFT-HANDED' THEN 'Left-Handed'
    WHEN 'RIGHT-HANDED' THEN 'Right-Handed'
    ELSE 'Unknown'
  END AS dominant_hand,
  CASE
    WHEN hand LIKE '%,%'
      THEN COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(hand, ',', -1)), ''), 'Unknown')
    ELSE 'Unknown'
  END AS backhand_type,
  CASE UPPER(COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(birth_location, ',', -1)), ''), 'UNKNOWN'))
    WHEN 'USA' THEN 'United States'
    WHEN 'UNITED STATES OF AMERICA' THEN 'United States'
    WHEN 'UK' THEN 'United Kingdom'
    WHEN 'GREAT BRITAIN' THEN 'United Kingdom'
    WHEN 'RUSSIA' THEN 'Russian Federation'
    WHEN 'SOUTH KOREA' THEN 'Korea, Republic of'
    ELSE COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(birth_location, ',', -1)), ''), 'Unknown')
  END AS birth_country,
  COALESCE(NULLIF(TRIM(tournament), ''), 'Unknown Tournament') AS tournament_name,
  CASE UPPER(COALESCE(NULLIF(TRIM(tournament_category), ''), 'OTHER'))
    WHEN 'GRAND SLAM' THEN 'Grand Slam'
    WHEN 'MASTERS 1000' THEN 'Masters 1000'
    WHEN 'ATP 500' THEN 'ATP 500'
    WHEN 'ATP 250' THEN 'ATP 250'
    ELSE 'Other'
  END AS tournament_category,
  CASE UPPER(COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(event_location, ',', -1)), ''), 'UNKNOWN'))
    WHEN 'USA' THEN 'United States'
    WHEN 'UNITED STATES OF AMERICA' THEN 'United States'
    WHEN 'UK' THEN 'United Kingdom'
    WHEN 'GREAT BRITAIN' THEN 'United Kingdom'
    WHEN 'RUSSIA' THEN 'Russian Federation'
    WHEN 'SOUTH KOREA' THEN 'Korea, Republic of'
    ELSE COALESCE(NULLIF(TRIM(SUBSTRING_INDEX(event_location, ',', -1)), ''), 'Unknown')
  END AS event_country,
  CASE UPPER(COALESCE(NULLIF(TRIM(surface), ''), 'UNKNOWN'))
    WHEN 'HARD' THEN 'Hard'
    WHEN 'CLAY' THEN 'Clay'
    WHEN 'GRASS' THEN 'Grass'
    WHEN 'CARPET' THEN 'Carpet'
    ELSE 'Unknown'
  END AS surface_name,
  COALESCE(NULLIF(TRIM(round_name), ''), 'Unknown') AS round_name,
  COALESCE(NULLIF(TRIM(opponent_name), ''), 'Unknown Player') AS opponent_name,
  CASE UPPER(COALESCE(NULLIF(TRIM(result), ''), 'NA'))
    WHEN 'W' THEN 'W'
    WHEN 'L' THEN 'L'
    ELSE 'NA'
  END AS result,
  CASE
    WHEN NULLIF(TRIM(date_range), '') IS NULL THEN NULL
    ELSE STR_TO_DATE(TRIM(SUBSTRING_INDEX(date_range, ' - ', 1)), '%Y.%m.%d')
  END AS start_date,
  CASE
    WHEN NULLIF(TRIM(date_range), '') IS NULL THEN NULL
    WHEN date_range LIKE '% - %'
      THEN STR_TO_DATE(TRIM(SUBSTRING_INDEX(date_range, ' - ', -1)), '%Y.%m.%d')
    ELSE STR_TO_DATE(TRIM(date_range), '%Y.%m.%d')
  END AS end_date,
  CASE
    WHEN NULLIF(REGEXP_REPLACE(COALESCE(prize_usd, ''), '[^0-9.]', ''), '') IS NULL
      THEN NULL
    ELSE CAST(REGEXP_REPLACE(prize_usd, '[^0-9.]', '') AS DECIMAL(15, 2))
  END AS prize_usd,
  CASE
    WHEN NULLIF(REGEXP_REPLACE(COALESCE(ranking, ''), '[^0-9]', ''), '') IS NULL
      THEN NULL
    ELSE CAST(REGEXP_REPLACE(ranking, '[^0-9]', '') AS UNSIGNED)
  END AS player_ranking
FROM atp_raw
WHERE NULLIF(TRIM(record_id), '') IS NOT NULL;

ALTER TABLE atp_clean
  ADD PRIMARY KEY (record_id);

-- Drop the public model in dependency order so the script is repeatable.
DROP TABLE IF EXISTS tournament_events;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS tournaments;
DROP TABLE IF EXISTS game_rounds;
DROP TABLE IF EXISTS surfaces;
DROP TABLE IF EXISTS hands;
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
  id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(100)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_countries_name (name)
) ENGINE = InnoDB;

CREATE TABLE hands (
  id            TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  dominant_hand VARCHAR(30)      NOT NULL,
  backhand_type VARCHAR(50)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_hands_description (dominant_hand, backhand_type)
) ENGINE = InnoDB;

CREATE TABLE surfaces (
  id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(30)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_surfaces_name (name)
) ENGINE = InnoDB;

CREATE TABLE game_rounds (
  id   TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(60)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_rounds_name (name)
) ENGINE = InnoDB;

CREATE TABLE tournaments (
  id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name     VARCHAR(160) NOT NULL,
  category VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_tournaments_name_category (name, category)
) ENGINE = InnoDB;

CREATE TABLE players (
  id               INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  player_name      VARCHAR(120)      NOT NULL,
  hand_id          TINYINT UNSIGNED  NOT NULL,
  birth_country_id SMALLINT UNSIGNED NOT NULL,
  height_cm        SMALLINT UNSIGNED NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_players_identity (player_name, birth_country_id),
  KEY idx_players_hand (hand_id),
  KEY idx_players_birth_country (birth_country_id),
  CONSTRAINT fk_players_hand
    FOREIGN KEY (hand_id) REFERENCES hands (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_players_birth_country
    FOREIGN KEY (birth_country_id) REFERENCES countries (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_player_height
    CHECK (height_cm IS NULL OR height_cm BETWEEN 120 AND 240)
) ENGINE = InnoDB;

CREATE TABLE tournament_events (
  id               BIGINT UNSIGNED   NOT NULL AUTO_INCREMENT,
  source_record_id VARCHAR(50)       NOT NULL,
  tournament_id    INT UNSIGNED      NOT NULL,
  event_country_id SMALLINT UNSIGNED NOT NULL,
  surface_id       TINYINT UNSIGNED  NOT NULL,
  player_id        INT UNSIGNED      NOT NULL,
  round_id         TINYINT UNSIGNED  NOT NULL,
  opponent_name    VARCHAR(120)      NOT NULL,
  result           ENUM('W', 'L', 'NA') NOT NULL,
  start_date       DATE              NULL,
  end_date         DATE              NULL,
  prize_usd        DECIMAL(15, 2)    NULL,
  player_ranking   INT UNSIGNED      NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_events_source_record (source_record_id),
  KEY idx_events_tournament (tournament_id),
  KEY idx_events_country (event_country_id),
  KEY idx_events_surface (surface_id),
  KEY idx_events_player (player_id),
  KEY idx_events_round (round_id),
  CONSTRAINT fk_events_tournament
    FOREIGN KEY (tournament_id) REFERENCES tournaments (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_events_country
    FOREIGN KEY (event_country_id) REFERENCES countries (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_events_surface
    FOREIGN KEY (surface_id) REFERENCES surfaces (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_events_player
    FOREIGN KEY (player_id) REFERENCES players (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_events_round
    FOREIGN KEY (round_id) REFERENCES game_rounds (id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_event_dates
    CHECK (start_date IS NULL OR end_date IS NULL OR start_date <= end_date),
  CONSTRAINT chk_event_prize
    CHECK (prize_usd IS NULL OR prize_usd >= 0),
  CONSTRAINT chk_event_ranking
    CHECK (player_ranking IS NULL OR player_ranking > 0)
) ENGINE = InnoDB;

INSERT INTO countries (name)
SELECT birth_country FROM atp_clean
UNION
SELECT event_country FROM atp_clean
UNION
SELECT 'Unknown';

INSERT INTO hands (dominant_hand, backhand_type)
SELECT DISTINCT dominant_hand, backhand_type
FROM atp_clean;

INSERT INTO surfaces (name)
SELECT DISTINCT surface_name
FROM atp_clean;

INSERT INTO game_rounds (name)
SELECT DISTINCT round_name
FROM atp_clean;

INSERT INTO tournaments (name, category)
SELECT DISTINCT tournament_name, tournament_category
FROM atp_clean;

INSERT INTO players (player_name, hand_id, birth_country_id, height_cm)
SELECT
  c.player_name,
  MIN(h.id) AS hand_id,
  bc.id AS birth_country_id,
  MAX(c.height_cm) AS height_cm
FROM atp_clean AS c
INNER JOIN hands AS h
  ON h.dominant_hand = c.dominant_hand
 AND h.backhand_type = c.backhand_type
INNER JOIN countries AS bc
  ON bc.name = c.birth_country
GROUP BY c.player_name, bc.id;

INSERT INTO tournament_events (
  source_record_id,
  tournament_id,
  event_country_id,
  surface_id,
  player_id,
  round_id,
  opponent_name,
  result,
  start_date,
  end_date,
  prize_usd,
  player_ranking
)
SELECT
  c.record_id,
  t.id,
  ec.id,
  s.id,
  p.id,
  r.id,
  c.opponent_name,
  c.result,
  c.start_date,
  c.end_date,
  c.prize_usd,
  c.player_ranking
FROM atp_clean AS c
INNER JOIN countries AS bc
  ON bc.name = c.birth_country
INNER JOIN players AS p
  ON p.player_name = c.player_name
 AND p.birth_country_id = bc.id
INNER JOIN tournaments AS t
  ON t.name = c.tournament_name
 AND t.category = c.tournament_category
INNER JOIN countries AS ec
  ON ec.name = c.event_country
INNER JOIN surfaces AS s
  ON s.name = c.surface_name
INNER JOIN game_rounds AS r
  ON r.name = c.round_name;

-- Expected public-sample result: 30 staging rows and 30 fact rows.
SELECT 'atp_raw' AS table_name, COUNT(*) AS row_count FROM atp_raw
UNION ALL
SELECT 'countries', COUNT(*) FROM countries
UNION ALL
SELECT 'hands', COUNT(*) FROM hands
UNION ALL
SELECT 'players', COUNT(*) FROM players
UNION ALL
SELECT 'surfaces', COUNT(*) FROM surfaces
UNION ALL
SELECT 'game_rounds', COUNT(*) FROM game_rounds
UNION ALL
SELECT 'tournaments', COUNT(*) FROM tournaments
UNION ALL
SELECT 'tournament_events', COUNT(*) FROM tournament_events;

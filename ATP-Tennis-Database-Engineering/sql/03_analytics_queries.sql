-- MySQL 8.0+
-- Four portfolio queries evaluated against the normalized model.

USE atp_portfolio;

-- 1. Country coverage: players by birth country and event activity by host country.
WITH
player_counts AS (
  SELECT
    birth_country_id AS country_id,
    COUNT(*) AS total_players
  FROM players
  GROUP BY birth_country_id
),
tournament_counts AS (
  SELECT
    event_country_id AS country_id,
    COUNT(
      DISTINCT CONCAT_WS(
        '|',
        tournament_id,
        COALESCE(DATE_FORMAT(start_date, '%Y-%m-%d'), 'unknown-date')
      )
    ) AS total_tournaments
  FROM tournament_events
  GROUP BY event_country_id
),
record_counts AS (
  SELECT
    event_country_id AS country_id,
    COUNT(*) AS total_player_match_records
  FROM tournament_events
  GROUP BY event_country_id
),
round_counts AS (
  SELECT
    event_country_id AS country_id,
    COUNT(
      DISTINCT CONCAT_WS(
        '|',
        tournament_id,
        round_id,
        COALESCE(DATE_FORMAT(start_date, '%Y-%m-%d'), 'unknown-date')
      )
    ) AS total_rounds
  FROM tournament_events
  GROUP BY event_country_id
)
SELECT
  c.name AS country_name,
  COALESCE(pc.total_players, 0) AS total_players,
  COALESCE(tc.total_tournaments, 0) AS total_tournaments,
  COALESCE(rc.total_player_match_records, 0) AS total_player_match_records,
  COALESCE(rdc.total_rounds, 0) AS total_rounds
FROM countries AS c
LEFT JOIN player_counts AS pc
  ON pc.country_id = c.id
LEFT JOIN tournament_counts AS tc
  ON tc.country_id = c.id
LEFT JOIN record_counts AS rc
  ON rc.country_id = c.id
LEFT JOIN round_counts AS rdc
  ON rdc.country_id = c.id
WHERE c.name <> 'Unknown'
ORDER BY c.name;

-- 2. Top players by win percentage, calculated before LIMIT is applied.
SET @minimum_matches = 2;

WITH player_performance AS (
  SELECT
    p.id AS player_id,
    p.player_name,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN te.result = 'W' THEN 1 ELSE 0 END) AS wins
  FROM players AS p
  INNER JOIN tournament_events AS te
    ON te.player_id = p.id
  GROUP BY p.id, p.player_name
)
SELECT
  player_name,
  total_matches,
  wins,
  ROUND(100.0 * wins / NULLIF(total_matches, 0), 2) AS win_percentage
FROM player_performance
WHERE total_matches >= @minimum_matches
ORDER BY win_percentage DESC, wins DESC, total_matches DESC, player_name
LIMIT 10;

-- 3. Top left-handed players in Grand Slam-category events by win percentage.
SET @minimum_grand_slam_matches = 1;

WITH left_handed_grand_slam AS (
  SELECT
    p.id AS player_id,
    p.player_name,
    COUNT(*) AS total_matches,
    SUM(CASE WHEN te.result = 'W' THEN 1 ELSE 0 END) AS wins
  FROM players AS p
  INNER JOIN hands AS h
    ON h.id = p.hand_id
  INNER JOIN tournament_events AS te
    ON te.player_id = p.id
  INNER JOIN tournaments AS t
    ON t.id = te.tournament_id
  WHERE h.dominant_hand = 'Left-Handed'
    AND t.category = 'Grand Slam'
  GROUP BY p.id, p.player_name
)
SELECT
  player_name,
  total_matches,
  wins,
  ROUND(100.0 * wins / NULLIF(total_matches, 0), 2) AS win_percentage
FROM left_handed_grand_slam
WHERE total_matches >= @minimum_grand_slam_matches
ORDER BY win_percentage DESC, wins DESC, total_matches DESC, player_name
LIMIT 10;

-- 4. Top five players by hard-court wins, with percentage as a tie-breaker.
WITH hard_court_performance AS (
  SELECT
    p.id AS player_id,
    p.player_name,
    COUNT(*) AS total_hard_court_matches,
    SUM(CASE WHEN te.result = 'W' THEN 1 ELSE 0 END) AS hard_court_wins
  FROM players AS p
  INNER JOIN tournament_events AS te
    ON te.player_id = p.id
  INNER JOIN surfaces AS s
    ON s.id = te.surface_id
  WHERE s.name = 'Hard'
  GROUP BY p.id, p.player_name
)
SELECT
  player_name,
  total_hard_court_matches,
  hard_court_wins,
  ROUND(
    100.0 * hard_court_wins / NULLIF(total_hard_court_matches, 0),
    2
  ) AS hard_court_win_percentage
FROM hard_court_performance
WHERE hard_court_wins > 0
ORDER BY
  hard_court_wins DESC,
  hard_court_win_percentage DESC,
  total_hard_court_matches DESC,
  player_name
LIMIT 5;

-- MySQL 8.0+
-- Creates a project-scoped database and a permissive staging table.

CREATE DATABASE IF NOT EXISTS atp_portfolio
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE atp_portfolio;

DROP TABLE IF EXISTS atp_raw;

CREATE TABLE atp_raw (
  record_id          VARCHAR(50)  NOT NULL,
  player_name        VARCHAR(120) NULL,
  birth_location     VARCHAR(160) NULL,
  height_cm          VARCHAR(20)  NULL,
  hand               VARCHAR(120) NULL,
  tournament         VARCHAR(160) NULL,
  tournament_category VARCHAR(50) NULL,
  event_location     VARCHAR(160) NULL,
  date_range         VARCHAR(50)  NULL,
  surface            VARCHAR(30)  NULL,
  prize_usd          VARCHAR(50)  NULL,
  round_name         VARCHAR(60)  NULL,
  ranking            VARCHAR(20)  NULL,
  opponent_name      VARCHAR(120) NULL,
  result             VARCHAR(10)  NULL,
  loaded_at          TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (record_id),
  KEY idx_raw_player (player_name),
  KEY idx_raw_tournament (tournament)
) ENGINE = InnoDB;

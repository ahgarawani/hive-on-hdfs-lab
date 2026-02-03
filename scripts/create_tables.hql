-- =====================================================
-- MovieLens Data Warehouse - Schema Definition
-- =====================================================
-- Dataset: MovieLens Latest Small
-- Description: Movies, Ratings, Tags, and Links
-- Strategy:  
--   1. Create EXTERNAL tables for raw CSV data (Staging Layer)
--   2. Create MANAGED tables for optimized analysis (Warehousing Layer)
--      using ORC format, Bucketing, and Snappy Compression.
-- =====================================================

CREATE DATABASE IF NOT EXISTS movielens;
USE movielens;

-- =====================================================
-- STAGING LAYER (External CSV Tables)
-- =====================================================

-- 1. Movies (Staging)
DROP TABLE IF EXISTS movies_raw;
CREATE EXTERNAL TABLE movies_raw (
    movieId STRING,
    title STRING,
    genres STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = ",",
   "quoteChar"     = "\""
)
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/movielens.db/movies_raw'
TBLPROPERTIES ("skip.header.line.count"="1");

-- 2. Ratings (Staging)
DROP TABLE IF EXISTS ratings_raw;
CREATE EXTERNAL TABLE ratings_raw (
    userId STRING,
    movieId STRING,
    rating STRING,
    `timestamp` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = ",",
   "quoteChar"     = "\""
)
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/movielens.db/ratings_raw'
TBLPROPERTIES ("skip.header.line.count"="1");

-- 3. Tags (Staging)
DROP TABLE IF EXISTS tags_raw;
CREATE EXTERNAL TABLE tags_raw (
    userId STRING,
    movieId STRING,
    tag STRING,
    `timestamp` STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = ",",
   "quoteChar"     = "\""
)
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/movielens.db/tags_raw'
TBLPROPERTIES ("skip.header.line.count"="1");

-- 4. Links (Staging)
DROP TABLE IF EXISTS links_raw;
CREATE EXTERNAL TABLE links_raw (
    movieId STRING,
    imdbId STRING,
    tmdbId STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
   "separatorChar" = ",",
   "quoteChar"     = "\""
)
STORED AS TEXTFILE
LOCATION '/user/hive/warehouse/movielens.db/links_raw'
TBLPROPERTIES ("skip.header.line.count"="1");

-- =====================================================
-- WAREHOUSE LAYER (Optimized ORC Tables)
-- =====================================================

-- 1. Movies (Optimized)
-- Explaining Concepts:
--   - ORC: Optimized Row Columnar format for fast reads.
--   - TBLPROPERTIES: Enabling transactional properties (ACID) if needed, 
--     but here we focus on compression.
DROP TABLE IF EXISTS movies;
CREATE TABLE movies (
    movie_id INT,
    title STRING,
    genres STRING
)
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY");

-- 2. Ratings (Partitioned & Bucketed)
-- Explaining Concepts:
--   - CLUSTERED BY (Bucketing): Optimal for Joins on movie_id.
--   - SORTED BY: Speeds up aggregations per movie.
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
    user_id INT,
    rating FLOAT,
    `timestamp` BIGINT
)
PARTITIONED BY (movie_id INT) -- Partition by Movie for fast lookup (Specific Use Case)
-- Note: In reality, partitioning by date is more common, 
-- but here we demo Partition on high-cardinality for educational purposes (Dynamic Partitioning).
CLUSTERED BY (user_id) SORTED BY (timestamp) INTO 8 BUCKETS
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY");

-- Alternative Ratings schema (better for general analytics)
DROP TABLE IF EXISTS ratings_analytics;
CREATE TABLE ratings_analytics (
    user_id INT,
    movie_id INT,
    rating FLOAT,
    rating_time TIMESTAMP
)
CLUSTERED BY (movie_id) INTO 8 BUCKETS
STORED AS ORC;

-- =====================================================
-- ETL: LOADING DATA
-- =====================================================
-- Enable Dynamic Partitioning
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

-- Load Movies
INSERT OVERWRITE TABLE movies
SELECT 
    CAST(movieId AS INT), 
    title, 
    genres 
FROM movies_raw;

-- Load Ratings Analytics (Converting timestamps)
INSERT OVERWRITE TABLE ratings_analytics
SELECT 
    CAST(userId AS INT),
    CAST(movieId AS INT),
    CAST(rating AS FLOAT),
    CAST(FROM_UNIXTIME(CAST(`timestamp` AS BIGINT)) AS TIMESTAMP)
FROM ratings_raw;

-- =====================================================
-- VERIFICATION
-- =====================================================
SHOW TABLES;
SELECT * FROM movies LIMIT 5;
SELECT * FROM ratings_analytics LIMIT 5;

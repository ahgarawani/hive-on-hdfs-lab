CREATE DATABASE IF NOT EXISTS movielens;
USE movielens;

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
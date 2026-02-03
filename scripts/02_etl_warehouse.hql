SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;

-- Optimized Managed Tables
DROP TABLE IF EXISTS ratings_analytics;
CREATE TABLE ratings_analytics (
    user_id INT,
    movie_id INT,
    rating FLOAT,
    rating_time TIMESTAMP
)
CLUSTERED BY (movie_id) INTO 8 BUCKETS
STORED AS ORC
TBLPROPERTIES ("orc.compress"="SNAPPY");

DROP TABLE IF EXISTS ratings_partitioned;
CREATE TABLE ratings_partitioned (
    user_id INT, movie_id INT, rating FLOAT, rating_time TIMESTAMP
) PARTITIONED BY (rating_year INT) STORED AS ORC;

DROP TABLE IF EXISTS movies;
CREATE TABLE movies (
    movie_id INT, title STRING, genres STRING
) STORED AS ORC;

DROP TABLE IF EXISTS movies_bucketed;
CREATE TABLE movies_bucketed (
    movie_id INT,
    title STRING,
    genres STRING
)
CLUSTERED BY (movie_id) 
SORTED BY (movie_id) 
INTO 8 BUCKETS
STORED AS ORC;

-- Load & Filter Headers
INSERT OVERWRITE TABLE movies 
SELECT CAST(movieId AS INT), title, genres FROM movies_raw WHERE movieId != 'movieId';

INSERT OVERWRITE TABLE ratings_analytics 
SELECT CAST(userId AS INT), CAST(movieId AS INT), CAST(rating AS FLOAT), 
CAST(FROM_UNIXTIME(CAST(`timestamp` AS BIGINT)) AS TIMESTAMP) FROM ratings_raw WHERE userId != 'userId';

INSERT OVERWRITE TABLE ratings_partitioned PARTITION(rating_year)
SELECT CAST(userId AS INT), CAST(movieId AS INT), CAST(rating AS FLOAT), 
CAST(FROM_UNIXTIME(CAST(`timestamp` AS BIGINT)) AS TIMESTAMP),
YEAR(FROM_UNIXTIME(CAST(`timestamp` AS BIGINT))) FROM ratings_raw WHERE userId != 'userId';

-- Stats Collection
ANALYZE TABLE ratings_analytics COMPUTE STATISTICS;
ANALYZE TABLE ratings_partitioned PARTITION(rating_year) COMPUTE STATISTICS;
SET hive.auto.convert.join=false;

-- Query 1: The Basic Check
-- Verify data types are correct (rating is float, not string)
SELECT * FROM ratings_analytics LIMIT 5;

-- Query 2: Top 10 Highest Rated Movies (with at least 50 ratings)
-- Concept: JOIN, GROUP BY, HAVING, ORDER BY
SELECT 
    m.title,
    ROUND(AVG(r.rating), 2) as avg_rating,
    COUNT(r.user_id) as num_ratings
FROM movies m
JOIN ratings_analytics r ON m.movie_id = r.movie_id
GROUP BY m.title
HAVING num_ratings >= 50
ORDER BY avg_rating DESC
LIMIT 10;

-- Query 3: Handling Arrays (Lateral View Explode)
-- Problem: Genres are "Action|Sci-Fi". We want to count per genre.
SELECT 
    genre,
    COUNT(*) as movie_count
FROM movies 
LATERAL VIEW EXPLODE(SPLIT(genres, '\\|')) t AS genre
GROUP BY genre
ORDER BY movie_count DESC;

-- Query 4: Year-over-Year Rating Trends
-- Concept: Date functions, Histogram
SELECT 
    YEAR(rating_time) as rating_year,
    COUNT(*) as total_ratings,
    ROUND(AVG(rating), 2) as global_avg
FROM ratings_analytics
GROUP BY YEAR(rating_time)
ORDER BY rating_year;

-- Query 5: Window Function - Top 3 Movies per Genre (Complexity High)
-- Concept: CTE (Common Table Expressions), Window Functions (DENSE_RANK)
WITH MoviesExploded AS (
    SELECT movie_id, title, genre FROM movies
    LATERAL VIEW EXPLODE(SPLIT(genres, '\\|')) t AS genre
),
GenreRatings AS (
    SELECT me.genre, me.title, AVG(r.rating) AS avg_rating, COUNT(r.user_id) AS vote_count
    FROM MoviesExploded me
    JOIN ratings_analytics r ON me.movie_id = r.movie_id
    GROUP BY me.genre, me.title HAVING vote_count > 50
),
RankedMovies AS (
    SELECT genre, title, avg_rating,
    DENSE_RANK() OVER (PARTITION BY genre ORDER BY avg_rating DESC) AS rank
    FROM GenreRatings
)
SELECT * FROM RankedMovies WHERE rank <= 3;

EXPLAIN SELECT AVG(rating) FROM ratings_analytics WHERE rating_time LIKE '2018%';
EXPLAIN SELECT AVG(rating) FROM ratings_partitioned WHERE rating_year = 2018;
-- =====================================================
-- MovieLens Analytics - Sample Queries
-- =====================================================
-- Guided Learning: Aggregations, Joins, Window Functions, arrays
-- =====================================================
USE movielens;

-- Query 1: Basic Stats - How many movies and ratings?
-- Concept: COUNT(*)
SELECT COUNT(*) as total_movies FROM movies;
SELECT COUNT(*) as total_ratings FROM ratings_analytics;

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

-- Query 3: Most Popular Genres
-- Concept: LATERAL VIEW EXPLODE (Handling delimited strings/arrays)
-- Step: Split "Action|Adventure|Sci-Fi" into separate rows per genre
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
WITH GenreRatings AS (
    SELECT 
        genre,
        m.title,
        AVG(r.rating) as avg_rating,
        COUNT(r.user_id) as vote_count
    FROM movies m
    LATERAL VIEW EXPLODE(SPLIT(genres, '\\|')) t AS genre
    JOIN ratings_analytics r ON m.movie_id = r.movie_id
    GROUP BY genre, m.title
    HAVING vote_count > 50
),
RankedMovies AS (
    SELECT 
        genre,
        title,
        avg_rating,
        DENSE_RANK() OVER (PARTITION BY genre ORDER BY avg_rating DESC) as rank
    FROM GenreRatings
)
SELECT * FROM RankedMovies WHERE rank <= 3;

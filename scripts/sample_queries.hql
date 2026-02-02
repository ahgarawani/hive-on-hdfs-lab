-- =====================================================
-- NYC Yellow Taxi - Sample Queries for Learning
-- =====================================================

USE nyc_taxi;

-- =====================================================
-- BASIC QUERIES
-- =====================================================

-- 1. Count total trips
SELECT COUNT(*) as total_trips FROM yellow_trips;

-- 2. Sample 10 rows
SELECT * FROM yellow_trips LIMIT 10;

-- 3. Basic trip stats
SELECT 
    COUNT(*) as trips,
    ROUND(AVG(trip_distance), 2) as avg_distance_miles,
    ROUND(AVG(total_amount), 2) as avg_total,
    ROUND(AVG(tip_amount), 2) as avg_tip
FROM yellow_trips;

-- =====================================================
-- FILTERING & AGGREGATION
-- =====================================================

-- 4. Trips by payment type
SELECT 
    payment_type,
    CASE payment_type
        WHEN 1 THEN 'Credit Card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No Charge'
        WHEN 4 THEN 'Dispute'
        ELSE 'Other'
    END as payment_method,
    COUNT(*) as trip_count,
    ROUND(SUM(total_amount), 2) as total_revenue
FROM yellow_trips
GROUP BY payment_type
ORDER BY trip_count DESC;

-- 5. Trips by hour of day
SELECT 
    HOUR(tpep_pickup_datetime) as pickup_hour,
    COUNT(*) as trips,
    ROUND(AVG(trip_distance), 2) as avg_distance,
    ROUND(AVG(total_amount), 2) as avg_fare
FROM yellow_trips
GROUP BY HOUR(tpep_pickup_datetime)
ORDER BY pickup_hour;

-- 6. Daily trip volume
SELECT 
    DATE(tpep_pickup_datetime) as trip_date,
    COUNT(*) as daily_trips,
    ROUND(SUM(total_amount), 2) as daily_revenue
FROM yellow_trips
GROUP BY DATE(tpep_pickup_datetime)
ORDER BY trip_date;

-- =====================================================
-- JOIN QUERIES (with taxi zones)
-- =====================================================

-- 7. Top pickup locations by trip count
SELECT 
    z.Borough,
    z.Zone,
    COUNT(*) as pickups
FROM yellow_trips t
JOIN taxi_zones z ON t.PULocationID = z.LocationID
GROUP BY z.Borough, z.Zone
ORDER BY pickups DESC
LIMIT 20;

-- 8. Top routes (pickup -> dropoff)
SELECT 
    pz.Zone as pickup_zone,
    dz.Zone as dropoff_zone,
    COUNT(*) as trip_count,
    ROUND(AVG(t.total_amount), 2) as avg_fare
FROM yellow_trips t
JOIN taxi_zones pz ON t.PULocationID = pz.LocationID
JOIN taxi_zones dz ON t.DOLocationID = dz.LocationID
GROUP BY pz.Zone, dz.Zone
ORDER BY trip_count DESC
LIMIT 20;

-- 9. Airport trips analysis
SELECT 
    z.Zone as airport,
    COUNT(*) as trips,
    ROUND(AVG(t.trip_distance), 2) as avg_distance,
    ROUND(AVG(t.total_amount), 2) as avg_fare,
    ROUND(AVG(t.tip_amount), 2) as avg_tip
FROM yellow_trips t
JOIN taxi_zones z ON t.DOLocationID = z.LocationID
WHERE z.Zone LIKE '%Airport%' OR z.Zone = 'JFK Airport' OR z.Zone = 'LaGuardia Airport' OR z.Zone = 'Newark Airport'
GROUP BY z.Zone;

-- =====================================================
-- ADVANCED ANALYTICS
-- =====================================================

-- 10. Tip percentage analysis
SELECT 
    CASE 
        WHEN tip_amount = 0 THEN 'No Tip'
        WHEN tip_amount / fare_amount < 0.10 THEN 'Under 10%'
        WHEN tip_amount / fare_amount < 0.15 THEN '10-15%'
        WHEN tip_amount / fare_amount < 0.20 THEN '15-20%'
        WHEN tip_amount / fare_amount < 0.25 THEN '20-25%'
        ELSE 'Over 25%'
    END as tip_bracket,
    COUNT(*) as trips,
    ROUND(AVG(tip_amount), 2) as avg_tip
FROM yellow_trips
WHERE fare_amount > 0 AND payment_type = 1  -- Credit card only (tips recorded)
GROUP BY 
    CASE 
        WHEN tip_amount = 0 THEN 'No Tip'
        WHEN tip_amount / fare_amount < 0.10 THEN 'Under 10%'
        WHEN tip_amount / fare_amount < 0.15 THEN '10-15%'
        WHEN tip_amount / fare_amount < 0.20 THEN '15-20%'
        WHEN tip_amount / fare_amount < 0.25 THEN '20-25%'
        ELSE 'Over 25%'
    END
ORDER BY trips DESC;

-- 11. Window function - Running daily total
SELECT 
    trip_date,
    daily_trips,
    SUM(daily_trips) OVER (ORDER BY trip_date) as cumulative_trips
FROM (
    SELECT 
        DATE(tpep_pickup_datetime) as trip_date,
        COUNT(*) as daily_trips
    FROM yellow_trips
    GROUP BY DATE(tpep_pickup_datetime)
) daily
ORDER BY trip_date;

-- 12. Peak hours by borough
SELECT 
    z.Borough,
    HOUR(t.tpep_pickup_datetime) as hour,
    COUNT(*) as trips
FROM yellow_trips t
JOIN taxi_zones z ON t.PULocationID = z.LocationID
GROUP BY z.Borough, HOUR(t.tpep_pickup_datetime)
ORDER BY z.Borough, trips DESC;

-- 13. Trip duration analysis
SELECT 
    CASE 
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 5 THEN 'Under 5 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 15 THEN '5-15 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 30 THEN '15-30 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 60 THEN '30-60 min'
        ELSE 'Over 60 min'
    END as duration_bracket,
    COUNT(*) as trips,
    ROUND(AVG(total_amount), 2) as avg_fare,
    ROUND(AVG(trip_distance), 2) as avg_distance
FROM yellow_trips
WHERE tpep_dropoff_datetime > tpep_pickup_datetime
GROUP BY 
    CASE 
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 5 THEN 'Under 5 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 15 THEN '5-15 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 30 THEN '15-30 min'
        WHEN (UNIX_TIMESTAMP(tpep_dropoff_datetime) - UNIX_TIMESTAMP(tpep_pickup_datetime)) / 60 < 60 THEN '30-60 min'
        ELSE 'Over 60 min'
    END;

-- 14. Vendor comparison
SELECT 
    VendorID,
    COUNT(*) as trips,
    ROUND(AVG(trip_distance), 2) as avg_distance,
    ROUND(AVG(total_amount), 2) as avg_fare,
    ROUND(SUM(total_amount), 2) as total_revenue
FROM yellow_trips
GROUP BY VendorID;

-- 15. Day of week analysis
SELECT 
    DAYOFWEEK(tpep_pickup_datetime) as day_num,
    CASE DAYOFWEEK(tpep_pickup_datetime)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END as day_name,
    COUNT(*) as trips,
    ROUND(AVG(total_amount), 2) as avg_fare
FROM yellow_trips
GROUP BY DAYOFWEEK(tpep_pickup_datetime)
ORDER BY day_num;

-- =====================================================
-- NYC Yellow Taxi Trip Data - Table Creation
-- =====================================================
-- Dataset: NYC TLC Yellow Taxi Trip Records
-- Source: https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page
-- Format: Parquet files (~40-100M rows per month)
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS nyc_taxi;
USE nyc_taxi;

-- =====================================================
-- TAXI TRIPS TABLE (External Parquet Table)
-- =====================================================
DROP TABLE IF EXISTS yellow_trips;

CREATE EXTERNAL TABLE yellow_trips (
    VendorID                INT         COMMENT 'TPEP provider (1=Creative Mobile, 2=VeriFone)',
    tpep_pickup_datetime    TIMESTAMP   COMMENT 'Meter engaged datetime',
    tpep_dropoff_datetime   TIMESTAMP   COMMENT 'Meter disengaged datetime',
    passenger_count         DOUBLE      COMMENT 'Number of passengers (driver entered)',
    trip_distance           DOUBLE      COMMENT 'Trip distance in miles',
    RatecodeID              DOUBLE      COMMENT 'Rate code (1=Standard, 2=JFK, 3=Newark, 4=Nassau/Westchester, 5=Negotiated, 6=Group)',
    store_and_fwd_flag      STRING      COMMENT 'Store and forward flag (Y/N)',
    PULocationID            INT         COMMENT 'Pickup TLC Taxi Zone',
    DOLocationID            INT         COMMENT 'Dropoff TLC Taxi Zone',
    payment_type            BIGINT      COMMENT 'Payment type (1=Credit, 2=Cash, 3=No charge, 4=Dispute, 5=Unknown, 6=Voided)',
    fare_amount             DOUBLE      COMMENT 'Time-and-distance fare ($)',
    extra                   DOUBLE      COMMENT 'Misc extras and surcharges ($)',
    mta_tax                 DOUBLE      COMMENT 'MTA tax ($0.50)',
    tip_amount              DOUBLE      COMMENT 'Tip amount (credit card only) ($)',
    tolls_amount            DOUBLE      COMMENT 'Tolls paid ($)',
    improvement_surcharge   DOUBLE      COMMENT 'Improvement surcharge ($0.30)',
    total_amount            DOUBLE      COMMENT 'Total charged to passenger ($)',
    congestion_surcharge    DOUBLE      COMMENT 'Congestion surcharge ($)',
    Airport_fee             DOUBLE      COMMENT 'Airport fee ($)'
)
STORED AS PARQUET
LOCATION '/opt/hive/data/warehouse/nyc_taxi.db/yellow_trips';

-- =====================================================
-- TAXI ZONES LOOKUP TABLE
-- =====================================================
DROP TABLE IF EXISTS taxi_zones;

CREATE TABLE taxi_zones (
    LocationID      INT,
    Borough         STRING,
    Zone            STRING,
    service_zone    STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ('skip.header.line.count'='1');

-- Verify tables
SHOW TABLES;
DESCRIBE yellow_trips;

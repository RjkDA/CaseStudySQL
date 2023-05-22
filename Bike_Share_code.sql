
CREATE DATABASE Bike_Share

/* Check data looks correct. Total for all rows is 5,754,248. */
SELECT * FROM dbo.[202202-divvy-tripdata]
SELECT COUNT(*) FROM dbo.[202202-divvy-tripdata] AS Total
SELECT * FROM dbo.[202203-divvy-tripdata]

/* Create table to insert all records into for the last 12 months. */
DROP TABLE dbo.previous_year_tripdata
TRUNCATE TABLE dbo.previous_year_tripdata
CREATE TABLE dbo.previous_year_tripdata (
	ride_id NVARCHAR(20),
	rideable_type NVARCHAR(14),
	started_at DATETIME2(7),
	ended_at DATETIME2(7),
	start_station_name NVARCHAR(65),
	start_station_id NVARCHAR(37),
	end_station_name NVARCHAR(64),
	end_station_id NVARCHAR(37),
	start_lat FLOAT,
	start_lng FLOAT,
	end_lat FLOAT,
	end_lng FLOAT,
	member_casual NVARCHAR(7)
	)

INSERT INTO dbo.previous_year_tripdata
SELECT * FROM dbo.[202202-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202203-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202204-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202205-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202206-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202207-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202208-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202209-divvy-publictripdata]
UNION ALL
SELECT * FROM dbo.[202210-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202211-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202212-divvy-tripdata]
UNION ALL
SELECT * FROM dbo.[202301-divvy-tripdata]
SELECT COUNT(*) FROM dbo.previous_year_tripdata
--5,754,248

/* Now that I have all of the data in one table and the record count matches, it's time to clean the data. I will start with the first column, ride_id. */

--Ride_ID
SELECT 
	LEN(ride_id) AS Ride_id_length, COUNT(DISTINCT ride_id) AS Length_of_id
FROM 
	dbo.previous_year_tripdata
GROUP BY
	LEN(ride_id)
/* I have a problem as some ride_id values are not 16 characters long and are either 8 or 9 characters long. 5,750,405 records are 16, and I only want these records. I will be removing 3,843 records. */

DELETE FROM
	dbo.previous_year_tripdata
WHERE
	LEN(ride_id) < 16
SELECT COUNT(DISTINCT ride_id) FROM dbo.previous_year_tripdata

/* Now I'm going to make sure that all values are unique in the ride_id column. 5,750,405 trips, looks good. */
SELECT DISTINCT 
	ride_id 
FROM 
	dbo.previous_year_tripdata

--Rideable_type
SELECT DISTINCT 
	rideable_type AS Type_of_bike, COUNT(rideable_type) AS Count_of_trips
FROM 
	dbo.previous_year_tripdata
GROUP BY
	rideable_type

SELECT
	rideable_type
FROM
	dbo.previous_year_tripdata
WHERE
	rideable_type != rideable_type OR rideable_type IS NULL

--Started_at/ended_at/ride_length/day_of_week
/* Here I am going to subtract the start time from the end to find trip duration. I am going to do this in seconds. Another thing I am doing is extracting the day of the week for each trip. */

ALTER TABLE dbo.previous_year_tripdata
DROP COLUMN IF EXISTS ride_length, day_of_week

ALTER TABLE dbo.previous_year_tripdata
ADD ride_length AS DATEDIFF(SECOND, started_at, ended_at) PERSISTED,
	day_of_week AS DATENAME(WEEKDAY, started_at);
SELECT * FROM dbo.previous_year_tripdata
--5,750,405 trips

SELECT 
	* 
FROM 
	dbo.previous_year_tripdata 
WHERE 
	ride_length <= 60 OR ride_length >= 86400 
ORDER BY 
	ride_length DESC
--176,064 trips which need to be deleted as they are outside of my range of 1 minute minimum and 1 day maximum that I am using for analysis. (In real life project I would ask what parameters they desired)

DELETE FROM
	dbo.previous_year_tripdata
WHERE
	ride_length <= 60 OR ride_length >= 86400
SELECT COUNT(*) FROM dbo.previous_year_tripdata
--5,574,341 trips remain after the 176,064 trips were removed.
SELECT * FROM dbo.previous_year_tripdata

--Start_station_name

SELECT
	start_station_name, 
	COUNT(start_station_name) AS station_occurrence
FROM
	dbo.previous_year_tripdata
GROUP BY
	start_station_name
ORDER BY
	COUNT(start_station_name) DESC

SELECT 
	start_station_name
FROM
	dbo.previous_year_tripdata
WHERE
	start_station_name IS NULL
/* There are 799,747 trips that are NULL and need to be removed. I am then left with 4,774,594 trips. */
DELETE FROM
	dbo.previous_year_tripdata
WHERE
	start_station_name IS NULL
SELECT COUNT(*) FROM dbo.previous_year_tripdata

UPDATE 
	dbo.previous_year_tripdata
SET
	start_station_name = TRIM(start_station_name)

--Start_station_id

SELECT 
	start_station_id
FROM
	dbo.previous_year_tripdata
WHERE
	start_station_id IS NULL
/* There are no trips that are NULL. */

UPDATE 
	dbo.previous_year_tripdata
SET
	start_station_id = TRIM(start_station_id)

--End_station_name

SELECT 
	end_station_name
FROM
	dbo.previous_year_tripdata
WHERE
	end_station_name IS NULL
/* There are 449,562 trips that are NULL and need to be removed. I am then left with 4,325,032 trips. */
DELETE FROM
	dbo.previous_year_tripdata
WHERE
	end_station_name IS NULL
SELECT COUNT(*) FROM dbo.previous_year_tripdata

UPDATE 
	dbo.previous_year_tripdata
SET
	end_station_name = TRIM(end_station_name)

--End_station_id

SELECT 
	end_station_id
FROM
	dbo.previous_year_tripdata
WHERE
	end_station_id IS NULL
/* There are no NULL trips. */

UPDATE 
	dbo.previous_year_tripdata
SET
	end_station_id = TRIM(end_station_id)

--Start_lat/start_lng/end_lat/end_lng

SELECT 
	start_lat, start_lng, end_lat, end_lng
FROM
	dbo.previous_year_tripdata
WHERE
	start_lat IS NULL OR start_lng IS NULL OR end_lat IS NULL OR end_lng IS NULL
/* There are no NULLs. */

SELECT
	start_lng, COUNT(start_lng) AS start_lng_count
FROM 
	dbo.previous_year_tripdata
GROUP BY
	start_lng
ORDER BY
	COUNT(start_lng) DESC

SELECT * FROM dbo.previous_year_tripdata

--Ride_length

SELECT
	ride_length
FROM
	dbo.previous_year_tripdata
WHERE
	ride_length <= 60 OR ride_length >= 86400
/* Double check that there are no trips outside of my parameters. */

--Membership_type

sp_rename 'dbo.previous_year_tripdata.member_casual', 'membership_type', 'COLUMN';

SELECT
	membership_type, 
	COUNT(membership_type) AS Type_count
FROM
	dbo.previous_year_tripdata
GROUP BY
	membership_type
ORDER BY
	COUNT(membership_type) DESC

--Day_of_week

SELECT
	day_of_week, COUNT(day_of_week) AS day_occurrence
FROM
	dbo.previous_year_tripdata
GROUP BY
	day_of_week

/* 
END OF CLEANING. 
There are 4,325,032 trips left to be analyzed.
I removed 1,429,216 trips of dirty data which was about 24.8% of the total data.
There seems to be a huge issue with data collection here.
There were 799,747 trips which had the start station as NULL and 449,562 trips which had the end station as NULL.
That's a total of 1,249,309 NULL start/end station trips or about 21.7% of the total data.
*/
SELECT * FROM dbo.previous_year_tripdata

/* Finding top 10 start stations */
SELECT TOP 10
	start_station_name, COUNT(start_station_name) AS station_count
FROM 
	dbo.previous_year_tripdata
WHERE 
	membership_type = 'casual'
GROUP BY
	start_station_name
ORDER BY 
	COUNT(start_station_name) DESC

/* Finding top 10 end stations */
SELECT TOP 10
	end_station_name, COUNT(end_station_name) AS station_count
FROM 
	dbo.previous_year_tripdata
WHERE 
	membership_type = 'casual'
GROUP BY
	end_station_name
ORDER BY 
	COUNT(end_station_name) DESC


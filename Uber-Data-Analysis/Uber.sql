SELECT TOP 10 *
FROM uber;

--total trips requested
SELECT COUNT(*) total_trips_requested
FROM uber;

--total trips by status
SELECT
    status,
    COUNT(status) AS Count,
    (COUNT(status) * 100.00 / (SELECT COUNT(*) FROM uber)) AS Percentage
FROM uber
GROUP BY status
ORDER BY Count DESC;

--number of trips that started at the airport and city, respectively, for each ride time bracket (in minutes). 
WITH 
--Calculate ride time in minutes
  cte AS (
    SELECT 
      Pickup_point, 
      DATEDIFF(MINUTE, Request_timestamp, Drop_timestamp) AS RideTime
    FROM 
      uber
    WHERE 
      status = 'Trip Completed'
  ),
  
--Group ride times into brackets of 10 minutes each
  Category AS (
    SELECT 
      Pickup_point, 
      CEILING(RideTime * 1.0 / 10) * 10 AS Bracket
    FROM 
      cte
  ),
--Count airport trips by bracket
  airport AS (
    SELECT 
      DISTINCT Bracket, 
      COUNT(*) AS airport_count
    FROM 
      Category
    WHERE 
      Pickup_point = 'Airport'
    GROUP BY 
      Bracket
  ),
--Count city trips by bracket
  city AS (
    SELECT 
      DISTINCT Bracket, 
      COUNT(*) AS city_count
    FROM 
      Category
    WHERE 
      Pickup_point = 'City'
    GROUP BY 
      Bracket
  )

--Join airport and city results on Bracket
SELECT 
  a.Bracket, 
  a.airport_count, 
  b.city_count
FROM 
  airport a
  FULL JOIN city b ON a.Bracket = b.Bracket;



--Trip status by hour from aiport to city
WITH

--Completed Trips by Hour
Completed AS (
    SELECT 
        DATEPART(hour, Request_timestamp) AS Hour, 
        COUNT(*) AS Completed_Count
    FROM 
        uber
    WHERE 
        status = 'Trip Completed' 
        AND Pickup_point = 'Airport'
    GROUP BY 
        DATEPART(hour, Request_timestamp)
),

--Cancelled Trips by Hour
Cancelled AS (
    SELECT 
        DATEPART(hour, Request_timestamp) AS Hour, 
        COUNT(*) AS Cancelled_Count
    FROM 
        uber
    WHERE 
        status = 'Cancelled' 
        AND Pickup_point = 'Airport'
    GROUP BY 
        DATEPART(hour, Request_timestamp)
),

--No Cars Available by Hour
No_Cars_Available AS (
    SELECT 
        DATEPART(hour, Request_timestamp) AS Hour, 
        COUNT(*) AS No_Cars_Available_Count
    FROM 
        uber
    WHERE 
        status = 'No Cars Available' 
        AND Pickup_point = 'Airport'
    GROUP BY 
        DATEPART(hour, Request_timestamp)
)

--Join the results
SELECT 
    a.Hour, 
    a.Completed_Count, 
    b.Cancelled_Count, 
    c.No_Cars_Available_Count
FROM 
    Completed a
    LEFT JOIN Cancelled b ON a.Hour = b.Hour
    LEFT JOIN No_Cars_Available c ON a.Hour = c.Hour
ORDER BY 
    1 ASC;

WITH

--Completed Trips by Hour
Completed AS (
SELECT
DATEPART(hour, Request_timestamp) AS Hour,
COUNT(*) AS Completed_Count
FROM
uber
WHERE
status = 'Trip Completed'
AND Pickup_point = 'City'
GROUP BY
DATEPART(hour, Request_timestamp)
),

--Cancelled Trips by Hour
Cancelled AS (
SELECT
DATEPART(hour, Request_timestamp) AS Hour,
COUNT(*) AS Cancelled_Count
FROM
uber
WHERE
status = 'Cancelled'
AND Pickup_point = 'City'
GROUP BY
DATEPART(hour, Request_timestamp)
),

-- No Cars Available by Hour
No_Cars_Available AS (
SELECT
DATEPART(hour, Request_timestamp) AS Hour,
COUNT(*) AS No_Cars_Available_Count
FROM
uber
WHERE
status = 'No Cars Available'
AND Pickup_point = 'City'
GROUP BY
DATEPART(hour, Request_timestamp)
)

-- Join the results
SELECT
a.Hour,
a.Completed_Count,
b.Cancelled_Count,
c.No_Cars_Available_Count
FROM
Completed a
LEFT JOIN Cancelled b ON a.Hour = b.Hour
LEFT JOIN No_Cars_Available c ON a.Hour = c.Hour
ORDER BY
1 ASC;

--Supply and Demand from City
WITH

 --Calculate Demand and Supply by Hour
cte AS (
SELECT
DATEPART(hour, Request_timestamp) AS Hour,
COUNT(*) AS Demand,
COUNT(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Supply
FROM
uber
WHERE
Pickup_point = 'City'
GROUP BY
DATEPART(hour, Request_timestamp)
)

-- Calculate Fulfillment Rate
SELECT
Hour,
Demand,
Supply,
Supply * 100.00 / Demand AS FulfillmentRate
FROM
cte
ORDER BY
1 ASC;

--Supply and Demand from Airport
WITH

--Calculate Demand and Supply by Hour
cte AS (
SELECT
DATEPART(hour, Request_timestamp) AS Hour,
COUNT(*) AS Demand,
COUNT(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Supply
FROM
uber
WHERE
Pickup_point = 'Airport'
GROUP BY
DATEPART(hour, Request_timestamp)
)

--Calculate Fulfillment Rate
SELECT
Hour,
Demand,
Supply,
Supply * 100.00 / Demand AS FulfillmentRate
FROM
cte
ORDER BY
1 ASC;


--Overall Fullfillment rate from city 
WITH
 --Calculate Demand and Supply
cte AS (
SELECT
COUNT(*) AS Demand,
COUNT(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Supply
FROM
uber
WHERE
Pickup_point = 'City'
)

-- Calculate Fulfillment Rate
SELECT
Demand,
Supply,
(Supply * 100.00 / Demand) AS FulfillmentRate
FROM
cte;



--Overall Fullfillment rate from airport
WITH

 --Calculate Demand and Supply
cte AS (
SELECT
COUNT(*) AS Demand,
COUNT(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Supply
FROM
uber
WHERE
Pickup_point = 'Airport'
)

-- Calculate Fulfillment Rate
SELECT
Demand,
Supply,
Supply * 100.00 / Demand AS FulfillmentRate
FROM
cte;


--Number of Drivers
select count(distinct(Driver_id)) as Number_of_drivers from uber;


--Driver Performance Metrics where pickup is Airport

WITH

-- Calculate Driver Metrics
cte AS (
SELECT DISTINCT
Driver_id,
SUM(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Trips_completed,
SUM(CASE WHEN status = 'Cancelled' THEN 1 END) AS Trips_Cancelled,
COUNT(*) AS Number_of_trips_requested
FROM
uber
WHERE
Driver_id NOT LIKE 'NA%' and Pickup_point = 'Airport'
GROUP BY
Driver_id
)

-- Driver Performance Report
SELECT
Driver_id,
Trips_completed,
Trips_Cancelled,
Number_of_trips_requested,
Trips_completed * 100.00 / Number_of_trips_requested AS Completion_Rate,
Trips_Cancelled * 100.00 / Number_of_trips_requested AS Cancellation_Rate
FROM
cte
ORDER BY
Number_of_trips_requested DESC;

--Driver Performance Metrics where pickup is City
WITH

-- Calculate Driver Metrics
cte AS (
SELECT DISTINCT
Driver_id,
SUM(CASE WHEN status = 'Trip Completed' THEN 1 END) AS Trips_completed,
SUM(CASE WHEN status = 'Cancelled' THEN 1 END) AS Trips_Cancelled,
COUNT(*) AS Number_of_trips_requested
FROM
uber
WHERE
Driver_id NOT LIKE 'NA%' and Pickup_point = 'City'
GROUP BY
Driver_id
)

-- Driver Performance Report
SELECT
Driver_id,
Trips_completed,
Trips_Cancelled,
Number_of_trips_requested,
Trips_completed * 100.00 / Number_of_trips_requested AS Completion_Rate,
Trips_Cancelled * 100.00 / Number_of_trips_requested AS Cancellation_Rate
FROM
cte
ORDER BY
Number_of_trips_requested DESC;



-- Airport Pickups Analysis

WITH
-- Calculate trip time in minutes
cte AS (
SELECT
Driver_id,
DATEDIFF(minute, Request_timestamp, Drop_timestamp) AS Trip_time_in_minutes
FROM
Uber
WHERE
Pickup_point = 'Airport'
AND
Status = 'Trip Completed'
)

-- Calculate driver metrics
SELECT
Driver_id,
SUM(Trip_time_in_minutes) AS Total_trips_in_minutes,
COUNT(*) AS Number_of_trips,
SUM(Trip_time_in_minutes) * 1.00 / COUNT(*) AS Avg_trip_time
FROM
cte
GROUP BY
Driver_id
ORDER BY
Number_of_trips DESC;

-- City Pickups Analysis

WITH
-- Calculate trip time in minutes
cte AS (
SELECT
Driver_id,
DATEDIFF(minute, Request_timestamp, Drop_timestamp) AS Trip_time_in_minutes
FROM
Uber
WHERE
Pickup_point = 'City'
AND
Status = 'Trip Completed'
)

-- Calculate driver metrics
SELECT
Driver_id,
SUM(Trip_time_in_minutes) AS Total_trips_in_minutes,
COUNT(*) AS Number_of_trips,
SUM(Trip_time_in_minutes) * 1.00 / COUNT(*) AS Avg_trip_time
FROM
cte
GROUP BY
Driver_id
ORDER BY
Number_of_trips DESC;
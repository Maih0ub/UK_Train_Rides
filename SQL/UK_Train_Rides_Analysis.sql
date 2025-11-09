-- show first 10 rows to ensure that data has been uploaded successfully.
SELECT TOP 10 *
FROM dbo.TrainRides;
-- columns info( names, nulls, keys...)
EXEC sp_help 'dbo.TrainRides';

-- check missing values
SELECT 
    SUM(CASE WHEN Transaction_ID IS NULL THEN 1 ELSE 0 END) AS Missing_Transaction_ID,
    SUM(CASE WHEN Date_of_Purchase IS NULL THEN 1 ELSE 0 END) AS Missing_Date_of_Purchase,
    SUM(CASE WHEN Price IS NULL THEN 1 ELSE 0 END) AS Missing_Price,
    SUM(CASE WHEN Actual_Arrival_Time IS NULL THEN 1 ELSE 0 END) AS Missing_Actual_Arrival_Time,
    SUM(CASE WHEN Railcard IS NULL THEN 1 ELSE 0 END) AS Missing_Railcard,
    SUM(CASE WHEN Refund_Request IS NULL THEN 1 ELSE 0 END) AS Missing_Refund_Request
FROM dbo.TrainRides;

-- checking unique values in text columns 
SELECT 
    'Purchase Type' AS Column_Name, 
    LTRIM(RTRIM([Purchase_Type])) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM([Purchase_Type]))

UNION ALL

SELECT 
    'Payment Method' AS Column_Name, 
    LTRIM(RTRIM([Payment_Method])) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM([Payment_Method]))

UNION ALL

SELECT 
    'Railcard' AS Column_Name, 
    LTRIM(RTRIM(Railcard)) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM(Railcard))

UNION ALL

SELECT 
    'Ticket Class' AS Column_Name, 
    LTRIM(RTRIM([Ticket_Class])) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM([Ticket_Class]))

UNION ALL

SELECT 
    'Ticket Type' AS Column_Name, 
    LTRIM(RTRIM([Ticket_Type])) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM([Ticket_Type]))

UNION ALL

SELECT 
    'Journey Status' AS Column_Name, 
    LTRIM(RTRIM([Journey_Status])) AS Unique_Value, 
    COUNT(*) AS Count_Of_Value 
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM([Journey_Status]));

-- Analyize Cardinality of (Departure_Station)
--i)count of unique stations
SELECT 
    'Total Unique Stations' AS Metric, 
    COUNT(DISTINCT LTRIM(RTRIM(Departure_Station))) AS Value
FROM dbo.TrainRides;

-- ii) The longest station text
SELECT 
    'Max Station Name Length' AS Metric, 
    MAX(LEN(LTRIM(RTRIM(Departure_Station)))) AS Value
FROM dbo.TrainRides

-- iii) The most 10 depatrure station
SELECT TOP 10
    'Top 10 Departure Station' AS Metric, 
    LTRIM(RTRIM(Departure_Station)) AS Value,
    COUNT(*) AS Frequency
FROM dbo.TrainRides
GROUP BY LTRIM(RTRIM(Departure_Station))
ORDER BY LTRIM(RTRIM(Departure_Station)) DESC;

-- 3. Standardize casing and clean up textual inconsistencies
-- A. Unify casing for Low Cardinality columns
UPDATE dbo.TrainRides
SET 
    Purchase_Type = UPPER(LTRIM(RTRIM(Purchase_Type))),
    Payment_Method = UPPER(LTRIM(RTRIM(Payment_Method))),
    Railcard = UPPER(LTRIM(RTRIM(Railcard))),
    Ticket_Class = UPPER(LTRIM(RTRIM(Ticket_Class))),
    Ticket_Type = UPPER(LTRIM(RTRIM(Ticket_Type))),
    Journey_Status = UPPER(LTRIM(RTRIM(Journey_Status)));

-- B. Clean up and unify Station columns (High Cardinality)
-- Convert to UPPER case and remove periods to handle naming inconsistencies (e.g. 'St. Pancras' to 'ST PANCRAS')
UPDATE dbo.TrainRides
SET 
    Departure_Station = UPPER(REPLACE(LTRIM(RTRIM(Departure_Station)), '.', '')),
    Arrival_Destination = UPPER(REPLACE(LTRIM(RTRIM(Arrival_Destination)), '.', ''));

-- 4. Re-check unique count to confirm standardization effectiveness
SELECT 
    'Unique Departure Stations After Cleaning' AS Metric, 
    COUNT(DISTINCT Departure_Station) AS Value
FROM dbo.TrainRides;

SELECT
    -- A. Check for non-valid prices (e.g., negative prices)
    SUM(CASE 
        WHEN ISNUMERIC(Price) = 1 AND CAST(Price AS DECIMAL) < 0 THEN 1 
        ELSE 0 
    END) AS Negative_Prices_Count,
    
    -- B. Check for impossible journey logic (Actual Arrival Time before Departure Time)
    -- FIX: Using TRY_CAST to return NULL for invalid time strings, preventing the crash.
    SUM(CASE 
        WHEN DATEDIFF(SECOND, 
                      TRY_CAST(Departure_Time AS TIME), 
                      TRY_CAST(Actual_Arrival_Time AS TIME)) < 0 
        THEN 1 
        ELSE 0 
    END) AS Actual_Arrival_Before_Departure_Count,
    
    -- C. Check for potential inconsistent data (Refund Request for On-Time Journeys)
    -- The CAST to VARCHAR prevents the BIT conversion error.
    SUM(CASE 
        WHEN CAST(Refund_Request AS VARCHAR(10)) = 'YES' AND CAST(Journey_Status AS VARCHAR(10)) = 'ON TIME' THEN 1 
        ELSE 0 
    END) AS Unjustified_Refund_Count
FROM dbo.TrainRides;

-- 6. Neutralize invalid/impossible time data by replacing it with an empty string ('')
-- This respects the NOT NULL constraint while isolating the dirty data.

UPDATE dbo.TrainRides
SET
    Departure_Time = '',
    Actual_Arrival_Time = ''
WHERE
    -- Condition 1: Structurally invalid time strings (failed TRY_CAST previously)
    TRY_CAST(Departure_Time AS TIME) IS NULL
OR
    TRY_CAST(Actual_Arrival_Time AS TIME) IS NULL
OR
    -- Condition 2: Logically impossible times (Arrival before Departure - the 916 records)
    (TRY_CAST(Departure_Time AS TIME) IS NOT NULL AND
     TRY_CAST(Actual_Arrival_Time AS TIME) IS NOT NULL AND
     DATEDIFF(SECOND, TRY_CAST(Departure_Time AS TIME), TRY_CAST(Actual_Arrival_Time AS TIME)) < 0);

	SELECT
    A.Min_Price,
    A.Max_Price,
    A.Average_Price,
    B.Median_Price
FROM
    ( -- Standard Aggregates: MIN, MAX, AVG (Calculated first)
    SELECT
        MIN(CAST(Price AS DECIMAL)) AS Min_Price,
        MAX(CAST(Price AS DECIMAL)) AS Max_Price,
        AVG(CAST(Price AS DECIMAL)) AS Average_Price
    FROM dbo.TrainRides
    WHERE ISNUMERIC(Price) = 1
    ) AS A
CROSS JOIN
    ( -- Median Calculation: PERCENTILE_CONT (Calculated separately)
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) 
            OVER () AS Median_Price
    FROM dbo.TrainRides
    WHERE ISNUMERIC(Price) = 1
    ) AS B;

	SELECT DISTINCT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER () AS Q1_Price,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER () AS Q3_Price
FROM dbo.TrainRides
WHERE ISNUMERIC(Price) = 1;

SELECT COUNT(*) AS Outlier_Count
FROM dbo.TrainRides
WHERE ISNUMERIC(Price) = 1 AND CAST(Price AS DECIMAL) > 80;

-- 7. Cap the outlier prices (above 80) at the statistical upper bound (80)

UPDATE dbo.TrainRides
SET Price = 80
WHERE 
    ISNUMERIC(Price) = 1 
    AND CAST(Price AS DECIMAL) > 80;

	SELECT
    MAX(CAST(Price AS DECIMAL)) AS Max_Price_After_Capping
FROM dbo.TrainRides
WHERE ISNUMERIC(Price) = 1;

-- 8. Create and populate Journey_Duration_Minutes
-- 8.1. Create Journey_Duration_Minutes column
ALTER TABLE dbo.TrainRides
ADD Journey_Duration_Minutes INT;

-- 8.2. Create Delay_Duration_Minutes column
ALTER TABLE dbo.TrainRides
ADD Delay_Duration_Minutes INT;

-- 8.3. Create Is_Cancelled (Binary Feature) column
ALTER TABLE dbo.TrainRides
ADD Is_Cancelled BIT;

-- 8.4. Populate Journey_Duration_Minutes
UPDATE dbo.TrainRides
SET Journey_Duration_Minutes = 
    CASE 
        -- Calculate only for rows with valid, non-neutralized time values
        WHEN Departure_Time <> '' AND Actual_Arrival_Time <> '' THEN
            DATEDIFF(MINUTE, 
                     TRY_CAST(Departure_Time AS TIME), 
                     TRY_CAST(Actual_Arrival_Time AS TIME))
        ELSE NULL -- Set to NULL if the time data was marked as dirty ('')
    END;

-- 8.5. Populate Delay_Duration_Minutes
UPDATE dbo.TrainRides
SET Delay_Duration_Minutes = 
    CASE
        -- Calculate for 'DELAYED' status using valid times
        WHEN Journey_Status = 'DELAYED' AND Departure_Time <> '' AND Actual_Arrival_Time <> '' THEN
            DATEDIFF(MINUTE, 
                     TRY_CAST(Arrival_Time AS TIME), 
                     TRY_CAST(Actual_Arrival_Time AS TIME))
        -- If On Time or Cancelled/Dirty Data, the delay is 0
        ELSE 0 
    END;

-- 8.6. Populate Is_Cancelled (Binary Feature)
UPDATE dbo.TrainRides
SET Is_Cancelled = 
    CASE 
        WHEN Journey_Status = 'CANCELLED' THEN 1 
        ELSE 0 
    END;

	SELECT
    A.Final_Average_Price,
    B.Final_Median_Price,
    A.Min_Duration_Mins,
    A.Max_Duration_Mins,
    A.Average_Duration_Mins,
    A.Total_Cancelled_Journeys,
    A.Total_Delayed_Journeys,
    A.Average_Delay_Mins_For_Delayed
FROM
    ( -- Subquery A: Standard Aggregates
    SELECT
        AVG(CAST(Price AS DECIMAL)) AS Final_Average_Price,
        MIN(Journey_Duration_Minutes) AS Min_Duration_Mins,
        MAX(Journey_Duration_Minutes) AS Max_Duration_Mins,
        AVG(Journey_Duration_Minutes) AS Average_Duration_Mins,
        -- FIX: Explicitly CAST Is_Cancelled to INT before SUM
        SUM(CAST(Is_Cancelled AS INT)) AS Total_Cancelled_Journeys,
        COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END) AS Total_Delayed_Journeys,
        AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END) AS Average_Delay_Mins_For_Delayed
    FROM dbo.TrainRides
    WHERE Journey_Duration_Minutes IS NOT NULL
    ) AS A
CROSS JOIN
    ( -- Subquery B: Window Function (Median Price)
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER () AS Final_Median_Price
    FROM dbo.TrainRides
    WHERE Journey_Duration_Minutes IS NOT NULL
    ) AS B;

	-- 10. Re-verification of Cancellation Count
SELECT 
    'Count from Status' AS Metric,
    COUNT(*) AS Value
FROM dbo.TrainRides
WHERE Journey_Status = 'CANCELLED' -- Should return 1880

UNION ALL

SELECT
    'Count from Is_Cancelled Feature (Re-checking)' AS Metric,
    SUM(CAST(Is_Cancelled AS INT)) AS Value
FROM dbo.TrainRides; -- Should also return 1880

WITH ClassAggregates AS (
    -- Subquery 1: Calculate standard aggregates (COUNT, AVG, MAX) using GROUP BY
    SELECT
        Ticket_Class,
        Ticket_Type,
        COUNT(*) AS Total_Tickets,
        AVG(CAST(Price AS DECIMAL)) AS Avg_Capped_Price,
        MAX(CAST(Price AS DECIMAL)) AS Max_Capped_Price
    FROM dbo.TrainRides
    GROUP BY Ticket_Class, Ticket_Type
),
MedianCalculation AS (
    -- Subquery 2: Calculate Median using the Window Function
    SELECT DISTINCT
        Ticket_Class,
        Ticket_Type,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) 
            OVER (PARTITION BY Ticket_Class, Ticket_Type) AS Median_Capped_Price
    FROM dbo.TrainRides
)

-- Final Query: Join the aggregates and the median calculation
SELECT
    A.Ticket_Class,
    A.Ticket_Type,
    A.Total_Tickets,
    A.Avg_Capped_Price,
    B.Median_Capped_Price,
    A.Max_Capped_Price
FROM ClassAggregates AS A
INNER JOIN MedianCalculation AS B
    ON A.Ticket_Class = B.Ticket_Class 
    AND A.Ticket_Type = B.Ticket_Type
ORDER BY A.Ticket_Class, A.Ticket_Type;

SELECT
    Departure_Station,
    COUNT(*) AS Total_Journeys,
    SUM(CAST(Is_Cancelled AS INT)) AS Total_Cancellations,
    COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END) AS Total_Delays,
    COALESCE(
    AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END),
    0
) AS Avg_Delay_Mins
FROM dbo.TrainRides
GROUP BY Departure_Station
ORDER BY Total_Journeys DESC;

-- Most 3  stations have delay
SELECT TOP 3
    Arrival_Destination,
    COUNT(*) AS Total_Delayed_Journeys,
    AVG(Delay_Duration_Minutes) AS Avg_Delay_Mins
FROM dbo.TrainRides
WHERE 
    Departure_Station = 'MANCHESTER PICCADILLY'
    AND Journey_Status = 'DELAYED'
GROUP BY Arrival_Destination
ORDER BY Total_Delayed_Journeys DESC;

-- Model prdicts the most high risk journeys
SELECT TOP 5
    Departure_Station,
    Arrival_Destination,
    COUNT(*) AS Total_Journeys_on_Segment,
    
    -- Total number of unreliable events (Delays + Cancellations)
    (SUM(CAST(Is_Cancelled AS INT)) + COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END)) AS Total_Unreliable_Events,

    -- Average delay duration for delayed journeys on this segment
    COALESCE(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END), 0) AS Avg_Delay_Mins_Segment,
    
    -- COMPOSITE RISK SCORE: (Total Unreliable Events) * (Avg Delay Mins)
    -- This score prioritizes routes with frequent and severe issues.
    (SUM(CAST(Is_Cancelled AS INT)) + COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END)) *
    COALESCE(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END), 0) AS Composite_Risk_Score
FROM dbo.TrainRides
GROUP BY Departure_Station, Arrival_Destination
HAVING 
    COUNT(*) > 50 -- Filter out very low-volume routes for stability
ORDER BY Composite_Risk_Score DESC;

--- Final insights 

-- Price (financial insight)
WITH AvgCalc AS (
    -- 1. Calculate the overall Average Price
    SELECT
        CAST(AVG(CAST(Price AS DECIMAL)) AS DECIMAL(10, 2)) AS Final_Avg_Price
    FROM dbo.TrainRides
    WHERE ISNUMERIC(Price) = 1
),
OverallMedianCalc AS (
    -- 2. Calculate the Overall Median Price
    SELECT DISTINCT
        CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER () AS DECIMAL(10, 2)) AS Overall_Median
    FROM dbo.TrainRides WHERE ISNUMERIC(Price) = 1
),
StandardMedianCalc AS (
    -- 3. Calculate the Standard Class Median Price
    SELECT DISTINCT
        CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER (PARTITION BY Ticket_Class) AS DECIMAL(10, 2)) AS Standard_Median
    FROM dbo.TrainRides WHERE Ticket_Class = 'STANDARD' AND ISNUMERIC(Price) = 1
),
FirstClassMedianCalc AS (
    -- 4. Calculate the First Class Median Price
    SELECT DISTINCT
        CAST(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(Price AS DECIMAL)) OVER (PARTITION BY Ticket_Class) AS DECIMAL(10, 2)) AS First_Class_Median
    FROM dbo.TrainRides WHERE Ticket_Class = 'FIRST CLASS' AND ISNUMERIC(Price) = 1
)

-- Final Report Structure using UNION ALL
SELECT 
    '1. Final Average Price' AS Metric, 
    T1.Final_Avg_Price AS Value,
    'Euros' AS Unit
FROM AvgCalc AS T1

UNION ALL

SELECT 
    '2. Overall Median Price' AS Metric, 
    T2.Overall_Median AS Value,
    'Euros' AS Unit
FROM OverallMedianCalc AS T2

UNION ALL

SELECT 
    '3. Standard Class Median Price' AS Metric, 
    T3.Standard_Median AS Value,
    'Euros' AS Unit
FROM StandardMedianCalc AS T3

UNION ALL

SELECT 
    '4. First Class Median Price' AS Metric, 
    T4.First_Class_Median AS Value,
    'Euros' AS Unit
FROM FirstClassMedianCalc AS T4
ORDER BY Metric;
--2. Operational Risk Ranking
SELECT TOP 5
    ROW_NUMBER() OVER (ORDER BY (SUM(CAST(Is_Cancelled AS INT)) + COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END)) *
                                COALESCE(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END), 0) DESC) AS Risk_Rank,
    Departure_Station,
    Arrival_Destination,
    (SUM(CAST(Is_Cancelled AS INT)) + COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END)) AS Unreliable_Events,
    COALESCE(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END), 0) AS Avg_Delay_Mins_Segment,
    ((SUM(CAST(Is_Cancelled AS INT)) + COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END)) * COALESCE(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END), 0)) AS Composite_Risk_Score
FROM dbo.TrainRides
GROUP BY Departure_Station, Arrival_Destination
HAVING 
    COUNT(*) > 50
ORDER BY Composite_Risk_Score DESC;

--3. Key Performance Indicators (KPIs)
SELECT
    COUNT(*) AS Total_Analyzed_Journeys,
    SUM(CAST(Is_Cancelled AS INT)) AS Total_Cancellations,
    CAST(SUM(CAST(Is_Cancelled AS INT)) * 100.0 / COUNT(*) AS DECIMAL(5, 2)) AS Cancellation_Rate_Pct,
    
    COUNT(CASE WHEN Journey_Status = 'DELAYED' THEN 1 END) AS Total_Delayed_Journeys,
    
    CAST(AVG(Journey_Duration_Minutes) AS DECIMAL(5, 1)) AS Avg_Journey_Duration_Mins,
    
    -- Average delay for ONLY the journeys that were delayed
    CAST(AVG(CASE WHEN Journey_Status = 'DELAYED' THEN Delay_Duration_Minutes ELSE NULL END) AS DECIMAL(5, 1)) AS Avg_Delay_Mins_If_Delayed
FROM dbo.TrainRides
WHERE Journey_Duration_Minutes IS NOT NULL;
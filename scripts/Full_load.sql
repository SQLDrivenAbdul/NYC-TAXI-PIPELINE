/*

This script creates the database and schema objects for the three layers of the ETL process.
If there is any database with the name,it deletes it and create another one.
*/


IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Nyc_DataWarehouse')
BEGIN
    ALTER DATABASE Nyc_DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Nyc_DataWarehouse;
END;

CREATE DATABASE Nyc_DataWarehouse;
GO

USE Nyc_DataWarehouse;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO


/*
TABLE CREATION

*/

CREATE TABLE bronze.yellow_taxi(
	VendorID INT NULL,
	tpep_pickup_datetime VARCHAR(30) NULL,
	tpep_dropoff_datetime VARCHAR(30) NULL,
	passenger_count FLOAT NULL,
	trip_distance FLOAT NULL,
	RatecodeID FLOAT NULL,
	store_and_fwd_flag CHAR(10) NULL,
	PULocationID INT NULL,
	DOLocationID INT NULL,
	payment_type INT NULL,
	fare_amount FLOAT NULL,
	extra FLOAT NULL,
	mta_tax FLOAT NULL,
	tip_amount FLOAT NULL,
	tolls_amount FLOAT NULL,
	improvement_surcharge FLOAT NULL,
	total_amount FLOAT NULL,
	congestion_surcharge FLOAT NULL,
	airport_fee] [float] NULL
)

/*
 Designed a stored procedure that load all 2024 data to the bronze table. To use, simply run 
EXEC bronze.load_nycbronze in your management system and the bronze table will be populated with data.
  */

CREATE PROCEDURE [bronze].[load_nycbronze]
AS
BEGIN
	DECLARE @load_start_time DATETIME , @load_end_time DATETIME

SET @load_start_time = GETDATE()

PRINT 'January data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-01.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'February data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-02.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'March data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-03.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'April data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-04.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'May data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-05.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'June data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-06.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'July data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-07.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'August data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-08.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'September data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-09.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'October data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-10.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'November data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-11.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);

PRINT 'December data'
BULK INSERT bronze.yellow_taxi
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-12.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
)
END

SET @load_end_time = GETDATE()
PRINT 'Load_time: ' + CAST(DATEDIFF(SECOND,@load_end_time,@load_start_time)AS VARCHAR) + 'seconds'


/*
SILVER LAYER
*/
SELECT
			VendorID,
			CASE 
				WHEN VendorID = 1 THEN 'Creative Mobility Technologies, LLC'
				WHEN VendorID = 2 THEN 'Curb Mobility, LLC'
				WHEN VendorID = 6 THEN 'Myle Technologies Inc'
				WHEN VendorID = 7 THEN 'Helix'
			END AS vendor_name,
			TRY_CONVERT(datetime2,TRIM(tpep_pickup_datetime),120) AS tpep_pickup_datetime,
			TRY_CONVERT(datetime2,TRIM(tpep_dropoff_datetime),120) AS tpep_dropoff_datetime,
			CAST(passenger_count AS INT) AS passenger_count,
			trip_distance,
			CASE 
				WHEN RatecodeID = 1.0 THEN 'Standard'
				WHEN RatecodeID = 2.0 THEN 'JFK'
				WHEN RatecodeID = 3.0 THEN 'Newark'
				WHEN RatecodeID = 4.0 THEN 'Nassau or Westchester'
				WHEN RatecodeID = 5.0 THEN 'Negotiated fare'
				WHEN RatecodeID = 6.0 THEN 'Group ride'
				WHEN RatecodeID = 99.0 THEN 'Unknown'
			END AS fare_category,
			CASE 
				WHEN TRIM(UPPER(store_and_fwd_flag)) = 'Y' THEN 'Yes'
				WHEN TRIM(UPPER(store_and_fwd_flag)) = 'N' THEN 'No'
			END AS store_and_fwd_flag,
			PULocationID,
			DOLocationID,
			CASE 
				WHEN payment_type = 0 THEN 'Flex fare trip'
				WHEN payment_type = 1 THEN 'Credit card'
				WHEN payment_type = 2 THEN  'Cash'
				WHEN payment_type = 3 THEN  'No charge'
				WHEN payment_type = 4 THEN  'Dispute'
				WHEN payment_type = 5 THEN  'Unknown'
				WHEN payment_type = 6 THEN  'Voided trip'
			END AS payment_type,
			ABS(fare_amount) AS fare_amount,
			ABS(extra) AS extra,
			ABS(mta_tax) AS mta_tax,
			ABS(tip_amount) AS tip_amount,
			ABS(tolls_amount)  AS tolls_amount,
		    ABS(improvement_surcharge) AS improvement_surcharge,
			ABS(total_amount) AS total_amount,
			ABS(congestion_surcharge) AS congestion_surcharge,
			ABS(airport_fee) AS airport_fee,
			CASE
				WHEN TRY_CONVERT(datetime,TRIM(tpep_dropoff_datetime),120) < TRY_CONVERT(datetime, TRIM(tpep_pickup_datetime),120) THEN 'Invalid'
				WHEN TRY_CONVERT(datetime,TRIM(tpep_dropoff_datetime),120) = TRY_CONVERT(datetime, TRIM(tpep_pickup_datetime),120)THEN 'Cancelled'
				ELSE 'Valid'
			END AS trip_status
	INTO silver.yellow_taxi
	FROM bronze.yellow_taxi
	;

/*
GOLD LAYER
*/
	
CREATE VIEW gold.yellowtaxi_weekday
AS
SELECT DATENAME(WEEKDAY,tpep_pickup_datetime) AS Day_of_Week ,COUNT(*) AS trips
FROM silver.yellow_taxi
GROUP BY DATENAME(WEEKDAY,tpep_pickup_datetime)

---

CREATE VIEW  gold.yellowtaxi_payment_type
AS
SELECT payment_type,COUNT(*) AS transactions
FROM silver.yellow_taxi
GROUP BY payment_type


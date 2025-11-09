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
 Designed a strored procedure that load all  2024 data to the bronze table. To use, simple run 
EXEC bronze.load_nycbronze in your management and the bronze table  will be populated.
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

*/

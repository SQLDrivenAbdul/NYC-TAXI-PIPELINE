/*
=======INCREMENTAL LOADING STRATEGY=======
This script creates the database and  schemas for the 3 layers
*/


CREATE DATABASE Nyc_Inc;
GO

USE Nyc_Inc;
GO

  CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

/*
The following sql script creates the bronze and silver layer tables.
*/

CREATE TABLE bronze.nyc_inc(
	VendorID INT NULL,
	tpep_pickup_datetime VARCHAR(30) NULL,
	tpep_dropoff_datetime VARCHAR(30) NULL,
	passenger_count FLOAT NULL,
	trip_distance FLOAT NULL,
	RatecodeID FLOAT NULL,
	store_and_fwd_flag [char](10) NULL,
	PULocationID [int] NULL,
	DOLocationID [int] NULL,
	payment_type [int] NULL,
	fare_amount FLOAT NULL,
	extra FLOAT NULL,
	mta_tax FLOAT NULL,
	tip_amount FLOAT NULL,
	tolls_amount FLOAT NULL,
	improvement_surcharge FLOAT NULL,
	total_amount FLOAT NULL,
	congestion_surcharge FLOAT NULL,
	airport_fee FLOAT NULL
)
-----------------------------------------
  CREATE TABLE [silver].[nyc_inc](
	VendorID INT NULL,
	vendor_name VARCHAR(50) NULL,
	tpep_pickup_datetime datetime2(7) NULL,
	tpep_dropoff_datetime datetime2(7) NULL,
	passenger_count INT NULL,
	trip_distance FLOAT NULL,
	fare_category VARCHAR(50) NULL,
	store_and_fwd_flag CHAR(10) NULL,
	PULocationID INT NULL,
	DOLocationID INT NULL,
	payment_type VARCHAR(50) NULL,
	fare_amount FLOAT NULL,
	extra FLOAT NULL,
	mta_tax FLOAT NULL,
	tip_amount FLOAT NULL,
	tolls_amount FLOAT NULL,
	improvement_surcharge FLOAT NULL,
	total_amount FLOAT NULL,
	congestion_surcharge FLOAT NULL,
	airport_fee FLOAT NULL,
	trip_status VARCHAR(50) NULL,
	load_datetime datetime NULL
)
/*
An After Insert trigger is attached to the bronze table, which ensures that whenever there is new data in it, it is transformed and loaded to the silver table.
 The script of the trigger is attached below
*/

CREATE TRIGGER bronze.AfterInsert ON bronze.nyc_inc
AFTER INSERT
AS
BEGIN

IF TRIGGER_NESTLEVEL() > 1 RETURN;
SET NOCOUNT ON;


	INSERT INTO silver.nyc_inc (VendorID, vendor_name, tpep_pickup_datetime, tpep_dropoff_datetime, passenger_count, trip_distance, fare_category, store_and_fwd_flag, PULocationID, DOLocationID,
	payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge, total_amount, congestion_surcharge, airport_fee, trip_status, load_datetime)


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
			END AS trip_status,
			GETDATE() AS load_datetime
	FROM INSERTED
END


/*
GOLD LAYER

The aggregation change dynamically has new data is loaded into the pipeline
*/

CREATE VIEW gold.yellowtaxi_weekday_inc
AS
SELECT DATENAME(WEEKDAY,tpep_pickup_datetime) AS Day_of_Week ,COUNT(*) AS trips
FROM silver.nyc_inc
GROUP BY DATENAME(WEEKDAY,tpep_pickup_datetime)



CREATE VIEW  gold.yellowtaxi_payment_type_inc
AS
SELECT payment_type,COUNT(*) AS transactions
FROM silver.nyc_inc
GROUP BY payment_type



/*
THE META-DATA TABLE CREATION
This table keep logs of every successful data loaded. It assigns a log_id to every load and keep date and time each batch finished loading
*/

CREATE TABLE metadata_table(
	log_id INT IDENTITY(1,1)  PRIMARY KEY,
	load_datetime datetime)



/*
THE LOAD_META TRIGGER
I created a trigger that fires the meta_data table once the bronze layer is populated.
Attached is the script below
*/
CREATE TRIGGER [bronze].[load_meta] ON [bronze].[nyc_inc]
AFTER INSERT 
AS
BEGIN
INSERT INTO metadata_table
SELECT
	
	MAX(GETDATE()) FROM INSERTED
END



/*
Data loading script. 
The FIRE_TRIGGERS option is key when using a bulk insert, else the trigger will not be fired; also means the target table not be loaded.
*/
BULK INSERT bronze.nyc_inc
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-01.csv' --testing with january data
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK,
FIRE_TRIGGERS
);


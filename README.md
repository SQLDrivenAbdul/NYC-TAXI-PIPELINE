# NYC-TAXI-PIPELINE


**Introduction**
<p align="justify">
The goal of this project is to develop and implement a SQL-based data pipeline, that ingest, transform, and aggregate NYC Yellow Taxi data for the year 2024. The dataset consist of month-by-month operational data on yellow taxi trips. It has 20 columns that describes operations of the taxis in 2024, the datasets columns include vendorID, trip_start_datetime, trip_end_datetime, fare_amount among others that can be used to uncover insights and track trends.
<p>


#### Data Source
**NYC Taxi and Limousine Commission** website  
**Link:** https://www.nyc.gov/site/tlc/index.page  


## Project Requirements
- Design a clear data architecture that shows the flow of data in the pipeline.
- It should demonstrate both full and incremental loading strategies

---
  
# Data Architecture  


<p align="center">
  <img src="architecture%20diagrams/NYC%20Data%20Architecture.jpg" alt="NYC Data Architecture" />
</p>
 

---

I downloaded all the datasets as parquet files using the python script below  


```python
import requests
import os

# 🔹 Base URL pattern for NYC TLC 2024 yellow taxi data
base_url = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-{month:02d}.parquet"

# 🔹 Folder where files will be saved
download_folder = r"C:\Users\USER\OneDrive\Desktop\New folder"

# Create folder if it doesn't exist
os.makedirs(download_folder, exist_ok=True)

# 🔹 Loop through all 12 months
for month in range(1, 13):
    url = base_url.format(month=month)
    filename = url.split("/")[-1]
    save_path = os.path.join(download_folder, filename)

    print(f"⬇️ Downloading {filename} ...")
    try:
        response = requests.get(url, stream=True)
        response.raise_for_status()
        with open(save_path, "wb") as file:
            for chunk in response.iter_content(chunk_size=8192):
                file.write(chunk)
        print(f"✅ Saved: {save_path}\n")
    except Exception as e:
        print(f"❌ Failed to download {filename}: {e}\n")

print("🎉 All downloads completed!")

```
---

<p align="justify">
I converted the datasets to CSV using the script below not for any performance reason but because I am not familiar with parquet as at the time of the project, so I chose to work with what I am familiar with.  
<p>
  
```python
for filename in os.listdir(source_folder):
    if filename.endswith(".parquet"):
        parquet_path = os.path.join(source_folder, filename)
        csv_filename = filename.replace(".parquet", ".csv")
        csv_path = os.path.join(destination_folder, csv_filename)

        print(f"🔄 Converting {filename} to CSV...")

        # Read Parquet and write to CSV
        try:
            df = pd.read_parquet(parquet_path)
            df.to_csv(csv_path, index=False)
            print(f"✅ Saved: {csv_path}\n")
        except Exception as e:
            print(f"❌ Error converting {filename}: {e}\n")

print("🎉 All conversions completed successfully!")

```
---

## Data Loading Strategies
---
<p align="justify">
  
**Full Load:** This approach of data loading means that all data has to be loaded at once - from January to December.
To achieve this in my data pipeline, I did the following:
- I wrote a stored procedure which once executed, populates the bronze layer with data.
- Clean the data in the bronze layer, then leveraged SQL Server ``SELECT INTO`` to create a silver layer and save the cleaned data into it on a fly.
- The cleaned data are used to perform some analytical aggregations that are then saved into the gold layer.

To use the procedure, simply run the code below in your data management system.

```SQL
EXEC bronze.load_nycbronze
```
<p>

  
Link to script: [Full_load.sql](./scripts/Full_load.sql)


---

<p align="justify">
Incremental Load: This approach takes the monthly data one at a time. As new data goes into the pipeline, they are appended to the already existing ones. The pipeline is also required to track and store last successful load date using a metadata table. At first, I created a seperate architecture for this approach, showing how data flow across layers in the pipeline and the objects that influence it. The architecture diagram is attached below.
</p>


<p align="center">
  <img src="architecture%20diagrams/incremental%20architecture.jpg" alt="Incremental Architecture" />
</p>

To achieve this, I created the following:

**STAGING TABLE:** This table is the entry point of the pipeline where all data first land. A trigger named ``load_bronze`` is attached to  this table. The job of the trigger is simple, using a ``MERGE STATEMENT`` it simply check data coming from the staging table that are not existing in the bronze layer, when found, they  are inserted into the bronze layer of the pipeline.

**BRONZE LAYER:** This table receives the raw data from the staging table. It also has two triggers attached to it, both performing different functions.

 (a) ``load_silver``: This trigger transform and cleans new data in the bronze layer and insert into the silver layer.  
 (b) ``load_meta``: This trigger tracks data loading into the bronze layer using a metadata table. It records the last successful load datetime dynamically. Any attempt to insert data that's already existing in the bronze leads to the metadata table adding a new record but without a datetime(NULL) because the operation was not successful.
 
**GOLD LAYER:**  The cleaned data in the silver layer are queried to answer some analytical questions saved as views in the gold layer. Examples attached below:

```SQL
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
```
Link to script: [Incremental Load SQL Script](https://github.com/SQLDrivenAbdul/NYC-TAXI-PIPELINE/blob/main/scripts/Incremental%20load.sql)

---

**DATA LOADING**

This is the only manual task in running the pipeline. Once the data is loaded, it pass through all the steps till it reaches the gold layer automatically.
```SQL
BULK INSERT bronze.staging
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-01.csv'
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK,
FIRE_TRIGGERS
);
```

## Key Learning
* Understanding the implementation difference between full load and incremental loading
* Triggers - using triggers to automate data loading and log keeping
  


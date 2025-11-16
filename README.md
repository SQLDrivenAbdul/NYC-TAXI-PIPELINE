# NYC-TAXI-PIPELINE


**Introduction**
<p align="justify">
I was contracted by the Data Engineering Community (DEC) to develop and implement a SQL-based data pipeline, that ingest, transform, and aggregate the  NYC Yellow Taxi data for the year 2024. The datasets consist of month-by-month operational data on yellow taxi trips. It has 20 columns that describes operations of the taxis in 2024; the columns include vendorID, trip_start_datetime, trip_end_datetime, fare_amount among others that can be used to uncover insights and track trends.
<p>


#### Data Source
**NYC Taxi and Limousine Commission** website  
**Link:** https://www.nyc.gov/site/tlc/index.page  


## Project Requirements
- Design a clear data architecture that shows the flow of data in the pipeline.
- It should demonstrate both full and incremental loading strategies

---
  
# Data Architecture  


[![NYC Yellow Taxi Data Architecture](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)  

---

I downloaded the datasets all as parquet files using the python script below  


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
I converted the datasets to CSV using the script below not for any performance reason but because i am not familiar with parquet as at the time of the project, so i chose to work with what i am familiar with.  
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


### Data Loading Strategies

<p align="justify">
  
**Full Load:** This approach of data loading means that all data has to be loaded at once - from January to December data. To achieve this in my data pipeline, I wrote a script to load all data of 2024 wrapped as a stored procedure. This procedure, once executed, populates the bronze layer with data.

<p>

  
The script that form the stored procedure can be found here: [Full_load.sql](./scripts/Full_load.sql)

To use the procedure, simply run the code below in your data management system.

```SQL
EXEC bronze.load_nycbronze
```
Once the bronze is populated, the data is transformed and loaded into silver layer.  
The cleaned data is then leveraged to answer some analytical questions saved into the gold layer.

---

<p align="justify">
  
**Incremental Load:** This approach takes the monthly data one at a time. As new data goes into the pipeline, they are appended to the already existing data in the pipeline.
For instance, the February data when loaded will be added to the January that is already existing in the pipeline.

<p>
  
Since i will be loading a single file at a time, i use a simply bulk insert statement for loading the data to the bronze layer 

```SQL
BULK INSERT bronze.nyc_inc
FROM 'C:\Users\USER\OneDrive\Desktop\NYC_ETL_PRROJECT FILE\yellow_tripdata_2024-01.csv' 
WITH
(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK,
FIRE_TRIGGERS
);
```
<p align="justify">
An AFTER-INSERT TRIGGER has been attached to the bronze layer that ensures that as new data comes into it, it is transformed and a silver layer is created with the cleaned data. Then aggregations are performed on the cleaned data and saved to the gold layer. As these new data come in and they are transformed, the aggregation changes dynamically to reflect the changes that comes with the new data. It is interesting how the only manual operation in this process is the data loading. 
<p>
  
Find the code of the trigger here  [Incremental_load.sql](./scripts/Incremental_load.sql)  

---

## META-DATA Management 

I created a metadata table that houses logs of every successful data loading event. It assigns a log_id and keeps the date and time each batch finish loading.


```SQL
CREATE TABLE metadata_table(
	log_id INT IDENTITY(1,1)  PRIMARY KEY,
	load_datetime datetime)
```


THE LOAD_META TRIGGER  


I created a trigger that fires/feeds the meta_data table once the bronze layer is populated.
Attached is the script below

```SQL
CREATE TRIGGER [bronze].[load_meta] ON [bronze].[nyc_inc]
AFTER INSERT 
AS
BEGIN
INSERT INTO metadata_table
SELECT
	
	MAX(GETDATE()) FROM INSERTED
END
```
---

**Query Examples**
 
```SQL
-- Trip volume by Weekday 
CREATE VIEW gold.yellowtaxi_weekday_inc
AS
SELECT DATENAME(WEEKDAY,tpep_pickup_datetime) AS Day_of_Week ,COUNT(*) AS trips
FROM silver.nyc_inc
GROUP BY DATENAME(WEEKDAY,tpep_pickup_datetime)


-- Payment_types performance
CREATE VIEW  gold.yellowtaxi_payment_type_inc
AS
SELECT payment_type,COUNT(*) AS transactions
FROM silver.nyc_inc
GROUP BY payment_type
```


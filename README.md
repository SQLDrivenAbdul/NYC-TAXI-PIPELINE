# NYC-TAXI-PIPELINE


**Introduction**
<p align="justify">
I was contracted by the Data Engineering Community (DEC) to develop and implement a SQL-based data pipeline, that ingest, transform, and aggregate the  NYC Yellow Taxi data for the year 2024. The dataset contains month-by-month operational data on yellow taxi trips. It has 20 columns that describes each operation of the taxis in 2024; the columns include vendorID, trip_start_datetime, trip_end_datetime, fare_amount among others that can be used to uncover insights and track trends.
<p>


#### Data Source
**NYC Taxi and Limousine Commission** website  
**Link:** https://www.nyc.gov/site/tlc/index.page  


## Project Requirements
- Design a clear data architecture that shows the flow of data in the pipeline.
- It should demonstrate both full and incremental loading strategies

  
# Data Architecture  


[![NYC Yellow Taxi Data Architecture](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)  


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


I converted to CSV using the script below not for any performance reason but because i am not familiar with parquet as at the time of the project, so i chose to work with what i am familiar with.  

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

### Data Loading Strategies

Full Load: This approach of data loading means that all data has to be loaded at once - from January to December data. To achieve this in my data pipeline, I wrote a script to load all data 2024 wrapped as a stored procedure. This procedure, once executed, populates the bronze layer with data.

The script that form the stored procedure can be found in [scripts](./[folder-name](https://github.com/SQLDrivenAbdul/NYC-TAXI-PIPELINE/blob/main/scripts/Full_load.sql)/)


To run the procedure, simply run the code below in your data management system.

```SQL
EXEC bronze.load_nycbronze
```





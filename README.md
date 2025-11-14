# NYC-TAXI-PIPELINE


**Introduction**

This project is all about development of SQL-based data pipeline. The goal of the pipeline is to extract the data from it source, transform it and make it ready for analytics.






## Data Architecture 

[![NYC Yellow Taxi Data Architecture](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)



The architecture shows how the data flows through the data pipeline. The NYC yellow taxi datasets for the 2024 was downloaded from the NYC Taxi and Limousine Commission website, all as parquet files. I decided to convert them to CSV files not for a performance reason but because i was not familiar with parquet.

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

I converted to CSV using the script below

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
LOADING STRATEGIES

The data pipeline is designed to demonstrate two loading strategies. They are as follows:

Full Load: Using this approach, all 12 months data into the pipeline. To easy loading , i wrapped the code in a stored procedure aliased bronze.load






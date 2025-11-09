# NYC-TAXI-PIPELINE

##Introduction

This project designing a simple SQL-based data pipeline using the NYC taxi data of year 2024. Focused on developing a pipeline with two different loading strategies (full and incremental).
I leveraged SQL stored procedures and triggers for automating loading processes across layers in the pipeline.


### Data Source
The dataset downloaded from New York City Taxi and Limosine Commission. It houses information of yellow_taxi trips in NYC - includes fields like trip start_time, end_time, fare_amount among others.

### Data Architecture
Below is the diagram showing the flow of data through the pipeline - from source,ingestion, to consumption.


[![NYC Yellow Taxi Data Architecture](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)](docs/NYC%20Yellow_Taxi%20Data%20Architecture.PNG)


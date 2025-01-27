# Motion Detection Data Pipline (MDDP)

MDDP is a high-throughput, scalable streaming Extract-Transform-Load (ETL) solution designed to continuously ingest and process video files in real time. By monitoring a filesystem directory, MDDP automatically detects new video data, performs motion detection on incoming video frames, and generates actionable insights. The pipeline leverages Apache NiFi for flow-based orchestration, Apache Kafka for event streaming, Elasticsearch for low-latency indexing and querying, and Python microservices for high-performance, algorithmic computations.

## Features
- **Continuous Data Ingestion**: Automatically detects, processes, and handles video files from a specific directory.
- **Low-Latency Processing**: Real-time motion detection using OpenCV and NumPy for efficient video frame analysis.
- **Event-Driven Alerts**: Publishes motion alerts to Apache Kafka for real-time downstream consumption.
- **Scalable Architecture**: Uses Kafka and NiFi to handle large-scale data ingestion for high throughput, and high horizontal scalability.
- **Elasticsearch Integration**: Integrates with Elasticsearch to index motion detection events, enabling powerful and flexible queries.
- **Python Microservices**: Includes lightweight Python microservices for handling algorithmic computations. 

## Technology Stack
   - Apache NiFi: Data ingestion and processing.
   - Apache Kafka: High-throughput event streaming platform.
- OpenCV & NumPy: Efficiency vision and numerical libraries for rapid, accurate motion detection. Already efficient out of the box for most modern hardware.
- Elasticsearch: Low-latency indexing, search, and analytics.
- Python Microservices: REST endpoints for frame extraction and motion detection using FastAPI and uvicorn.

##  Architecture Overview
<img src="https://github.com/user-attachments/assets/756c794e-1709-46e5-a61f-2d9a74da32b0" width="750">
<img src="https://github.com/user-attachments/assets/68b77e78-cf5b-4b84-90a2-570a5d4118be" width="750">


## Quick start

1. Clone repository:
```
git clone https://github.com/rackd/mddp
cd mddp
```

2. Import flow definition (```flow.json```) into Apache NiFi using either web interface or API.

3. Optionally use pre-configured configuration files:
```
cp preconfig/KAFKA_server.properties KAFKA_HOME/config/server.properties
```

4. Setup development environment:
4a. Note that the following environmental variables must be defined: JAVA_HOME, KAFKA_HOME, NIFI_HOME, and ELASTICSEARCH_IP
```
./setup.sh
```

5. Start development environment:
```
./start.sh
```

6. Stop development environment:
```
 ./stop.sh
```
## Reconfiguring & Production Tips
- For production, Apache NiFi and Apache Kafka will have to be reconfigured. This includes security methods, network addresses, clustering (if applicable), etc.



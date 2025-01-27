#!/bin/bash

sudo echo "Setting up for debug enviorment"

if [ -z "$JAVA_HOME" ]; then
  echo "Error: JAVA_HOME is not set. Please set it and try again."
  exit 1
fi

if [ -z "$KAFKA_HOME" ]; then
  echo "Error: KAFKA_HOME is not set. Please set it and try again."
  exit 1
fi

if [ -z "$NIFI_HOME" ]; then
  echo "Error: NIFI_HOME is not set. Please set it and try again."
  exit 1
fi

if [ -z "$ELASTICSEARCH_IP" ]; then
  echo "Error: ELASTICSEARCH_IP is not set. Please set it and try again."
  exit 1
fi

echo "JAVA_HOME=$JAVA_HOME"
echo "KAFKA_HOME=$KAFKA_HOME"
echo "NIFI_HOME=$NIFI_HOME"
echo  "ELASTICSEARCH_IP=$ELASTICSEARCH_IP"

if [ -ne "$KAFKA_HOME/bin/kafka-topics.sh" ]; then
  echo "Error: Bad KAFKA_HOME."
  exit 1
fi

if [ -ne "$NIFI_HOME/bin/kafka-topics.sh" ]; then
  echo "Error: Bad NIFI_HOME."
  exit 1
fi

curl -s --head --request GET "$ELASTICSEARCH_IP" | grep "200 OK" > /dev/null
if [ $? -ne 0 ]; then
    echo "Error: Elasticsearch not running."
fi

echo "Creating directories"
dir=/public/write_only/videos
sudo mkdir -p $dir
sudo chmod -R 777 $dir

tmp_dir=/frames
sudo mkdir -p $tmp_dir
sudo chmod -R 777 $tmp_dir

rm -rf .venv
echo "Setting up Python env"
python -m venv .venv
if [ $? -ne 0 ]; then
  exit 1
fi

# Show user we aren't using global site repo
.venv/bin/python -m pip --version
.venv/bin/python -m pip install fastapi ffmpeg-python uvicorn pydantic numpy opencv-python

echo "Creating kafka topics"
"$KAFKA_HOME"/bin/kafka-topics.sh --create --topic video_metadata --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
"$KAFKA_HOME"/bin/kafka-topics.sh --create --topic motion_alerts --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

echo "Setting up EleasticSearch"
curl -X PUT "localhost:9200/motion_alerts" -H "Content-Type: application/json" -d "{\"mappings\":{\"properties\":{\"filename\":{\"type\":\"text\",\"fields\":{\"keyword\":{\"type\":\"keyword\"}}},\"absolute.path\":{\"type\":\"text\",\"fields\":{\"keyword\":{\"type\":\"keyword\"}}},\"file.lastModifiedTime\":{\"type\":\"date\",\"format\":\"yyyy-MM-dd'T'HH:mm:ssZ\"},\"frame_count\":{\"type\":\"integer\"},\"motion_detected\":{\"type\":\"boolean\"},\"motions\":{\"type\":\"nested\",\"properties\":{\"0\":{\"type\":\"integer\"},\"1\":{\"type\":\"integer\"}}}}}}"



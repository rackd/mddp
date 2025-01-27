#!/bin/bash

set -e

handle_failure() {
  echo "Error: $1 failed to start."
  echo "Running ./stop.sh to clean up."
  ./stop.sh
  echo "Command failed. Please check the logs for more information."
  exit 1
}

check_directory() {
  if [ ! -d "$1" ]; then
    echo "Error: Directory $1 does not exist."
    exit 1
  fi
}

check_executable() {
  if [ ! -x "$1" ]; then
    echo "Error: Executable $1 not found or not executable."
    exit 1
  fi
}

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

VENV_DIR=".venv"
if [ ! -d "$VENV_DIR" ]; then
  echo "Error: Virtual environment directory '$VENV_DIR' does not exist. Run ./setup.sh"
  exit 1
fi

PYTHON_EXEC="$VENV_DIR/bin/python"
if [ ! -x "$PYTHON_EXEC" ]; then
  echo "Error: Bad python."
  exit 1
fi

echo "JAVA_HOME=$JAVA_HOME"
echo "KAFKA_HOME=$KAFKA_HOME"
echo "NIFI_HOME=$NIFI_HOME"
echo "VIRTUAL_ENV=$VENV_DIR"

# rm -f "$NIFI_HOME"/logs/*  # The data engineer NiFi cheat code

mkdir -p logs/python  # For Python script logs

echo "Starting Zookeeper..."
"$KAFKA_HOME"/bin/zookeeper-server-start.sh "$KAFKA_HOME"/config/zookeeper.properties > "$KAFKA_HOME"/logs/zookeeper.log 2>&1 &
ZOOKEEPER_PID=$!
sleep 3

if ! kill -0 "$ZOOKEEPER_PID" 2>/dev/null; then
  handle_failure "Zookeeper"
fi
echo "Zookeeper started with PID $ZOOKEEPER_PID."

echo "Starting Kafka..."
"$KAFKA_HOME"/bin/kafka-server-start.sh "$KAFKA_HOME"/config/server.properties > "$KAFKA_HOME"/logs/kafka.log 2>&1 &
KAFKA_PID=$!
sleep 3

if ! kill -0 "$KAFKA_PID" 2>/dev/null; then
  handle_failure "Kafka"
fi
echo "Kafka started with PID $KAFKA_PID."

echo "Starting NiFi..."
"$NIFI_HOME"/bin/nifi.sh start > "$NIFI_HOME"/logs/nifi.log 2>&1 &
NIFI_PID=$!
sleep 5

if ! "$NIFI_HOME"/bin/nifi.sh status | grep -q "Running"; then
  handle_failure "NiFi"
fi
echo "NiFi started successfully."

echo "Starting Python scripts..."

"$PYTHON_EXEC" ./start_detector.py > logs/python/start_detector.log 2>&1 &
DETECTOR_PID=$!
sleep 2

if ! kill -0 "$DETECTOR_PID" 2>/dev/null; then
  handle_failure "start_detector.py"
fi
echo "start_detector.py started with PID $DETECTOR_PID."

"$PYTHON_EXEC" ./start_extractor.py > logs/python/start_extractor.log 2>&1 &
EXTRACTOR_PID=$!
sleep 2

if ! kill -0 "$EXTRACTOR_PID" 2>/dev/null; then
  handle_failure "start_extractor.py"
fi
echo "start_extractor.py started with PID $EXTRACTOR_PID."

# Clear the terminal for a clean start
clear

echo "All services started successfully."
echo "Zookeeper PID: $ZOOKEEPER_PID"
echo "Kafka PID: $KAFKA_PID"
echo "NiFi PID: $NIFI_PID"
echo "start_detector.py PID: $DETECTOR_PID"
echo "start_extractor.py PID: $EXTRACTOR_PID"
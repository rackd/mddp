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

echo "JAVA_HOME=$JAVA_HOME"
echo "KAFKA_HOME=$KAFKA_HOME"
echo "NIFI_HOME=$NIFI_HOME"

"$NIFI_HOME"/bin/nifi.sh stop

"$KAFKA_HOME"/bin/kafka-server-stop.sh

"$KAFKA_HOME"/bin/zookeeper-server-stop.sh

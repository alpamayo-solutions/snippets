#!/bin/sh

publish_service_details() {
  if [ -z "$SERVICE_ID" ]; then
    echo "ERROR: SERVICE_ID is required but not set"
    exit 1
  fi
  
  if [ -z "$SERVICE_DISPLAY_NAME" ]; then
    echo "ERROR: SERVICE_DISPLAY_NAME is required but not set"
    exit 1
  fi
  
  if [ -z "$SERVICE_TYPE" ]; then
    echo "ERROR: SERVICE_TYPE is required but not set"
    exit 1
  fi
  
  if [ -z "$SERVICE_VERSION" ]; then
    echo "ERROR: SERVICE_VERSION is required but not set"
    exit 1
  fi
  
  if [ -z "$SERVICE_HIERARCHY" ]; then
    echo "ERROR: SERVICE_HIERARCHY is required but not set"
    exit 1
  fi

  if [ -z "$SERVICE_METADATA" ]; then
    SERVICE_METADATA="{}"
  fi
  
  MQTT_IP=${MQTT_IP:-"broker"}
  MQTT_USERNAME=${MQTT_USERNAME}
  MQTT_PASSWORD=${MQTT_PASSWORD}
  
  JSON_PAYLOAD=$(cat <<EOF
{
  "id": "$SERVICE_ID",
  "display_name": "$SERVICE_DISPLAY_NAME",
  "version": "$SERVICE_VERSION",
  "metadata": $SERVICE_METADATA,
  "service_type": "$SERVICE_TYPE",
  "hierarchy": $SERVICE_HIERARCHY
}
EOF
)
  
  echo "Publishing service details for service $SERVICE_DISPLAY_NAME to broker..."
  
  if ! mosquitto_pub -h "$MQTT_IP" -p 1883 -u "$MQTT_USERNAME" -P "$MQTT_PASSWORD" -t "alp/v1/_ServiceDetails/$SERVICE_ID" -m "$JSON_PAYLOAD" -r; then
    echo "ERROR: Failed to publish service details to MQTT broker"
    exit 1
  fi
  
  echo "Service details published successfully."
}

publish_service_details

# Execute the command passed as arguments
exec "$@"

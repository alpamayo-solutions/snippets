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
  MQTT_PORT=${MQTT_PORT:-1883}
  MQTT_USERNAME=${MQTT_USERNAME}
  MQTT_PASSWORD=${MQTT_PASSWORD}
  USE_SSL=${USE_SSL:-false}

  # TLS paths (only used if USE_SSL=true)
  TLS_CERT_FILE=${TLS_CERT_FILE:-/etc/certs/service.pem}
  TLS_KEY_FILE=${TLS_KEY_FILE:-/etc/certs/service.key}
  CA_CERT_FILE=${CA_CERT_FILE:-/etc/ca/ca.crt}

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

  echo "Publishing service details for $SERVICE_DISPLAY_NAME to MQTT broker at $MQTT_IP:$MQTT_PORT..."

  # Compose base command
  CMD="mosquitto_pub -h \"$MQTT_IP\" -p \"$MQTT_PORT\" -u \"$MQTT_USERNAME\" -P \"$MQTT_PASSWORD\" -t \"alp/v1/_ServiceDetails/$SERVICE_ID\" -m '$JSON_PAYLOAD' -r"

  if [ "$USE_SSL" = "true" ]; then
    echo "🔐 USE_SSL=true — TLS client authentication required"

    # Check file presence
    for f in "$TLS_CERT_FILE" "$TLS_KEY_FILE" "$CA_CERT_FILE"; do
      if [ ! -f "$f" ]; then
        echo "❌ ERROR: Required TLS file '$f' not found!"
        exit 1
      fi
    done

    # Update port and add TLS options
    MQTT_PORT=8883
    CMD="$CMD --cafile \"$CA_CERT_FILE\" --cert \"$TLS_CERT_FILE\" --key \"$TLS_KEY_FILE\""
  else
    echo "⚠️  USE_SSL=false — MQTT traffic is unencrypted"
  fi

  # Execute
  if ! eval $CMD; then
    echo "❌ ERROR: Failed to publish service details to MQTT broker"
    exit 1
  fi

  echo "✅ Service details published successfully."
}

publish_service_details

# Execute the command passed as arguments
exec "$@"

#!/bin/sh

# #!/bin/sh -e
# set -x

LOGFILE="/tmp/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/tmp/log/nodogsplash_data_usage.json"

# Function to update purchase log with token if missing
update_purchase_log_with_token() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.token)"')
  # echo "Updating Purchase Log with Tokens"  # Debugging line

  echo "$client_usage" | while read -r mac token; do
    jq --arg mac "$mac" --arg token "$token" '
    map(if .mac == $mac and (.token | length) == 0 then .token = $token else . end)
    ' "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
  done
}

# Function to update usage log with entries from purchase log
update_usage_log_with_purchases() {
  purchases=$(jq -r '.[] | "\(.mac) \(.token)"' "$LOGFILE")
  # echo "Updating Usage Log with Purchases"  # Debugging line

  echo "$purchases" | while read -r mac token; do
    current_entry=$(jq --arg token "$token" '.[$token] // empty' "$USAGE_LOGFILE")
    if [ -z "$current_entry" ]; then
      jq --arg mac "$mac" --arg token "$token" '
      .[$token] = {
        "mac": $mac,
        "duration": 0,
        "token": $token
      }' "$USAGE_LOGFILE" > "${USAGE_LOGFILE}.tmp" && mv "${USAGE_LOGFILE}.tmp" "$USAGE_LOGFILE"
    fi
  done
}

# Function to remove elements without tokens or with token "null"
remove_elements_without_tokens() {
  # Remove elements without tokens or with token "null" in the purchase log
  jq 'map(select(.token != "" and .token != "null"))' "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"

  # Remove elements without tokens or with token "null" in the usage log
  jq 'with_entries(select(.value.token != "" and .value.token != "null"))' "$USAGE_LOGFILE" > "${USAGE_LOGFILE}.tmp" && mv "${USAGE_LOGFILE}.tmp" "$USAGE_LOGFILE"
}

# Main
update_purchase_log_with_token
update_usage_log_with_purchases
remove_elements_without_tokens


#!/bin/sh

##!/bin/sh -e
# set -x

LOGFILE="/tmp/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/tmp/log/nodogsplash_data_usage.json"

METHOD="$1"
MAC="$2"
USERNAME="$3"  # Here, USERNAME represents either the e-cash value or LNURLW
PASSWORD="$4"  # Password might not be used in this case

# Log all arguments to /tmp/arguments_log.md
echo "METHOD: $METHOD, MAC: $MAC, USERNAME: $USERNAME, PASSWORD: $PASSWORD" >> /tmp/arguments_log.md

# Ensure the usage log file exists
if [ ! -f "$USAGE_LOGFILE" ]; then
  echo "{}" > "$USAGE_LOGFILE"
fi

# Pricing model
MSAT_PER_KB=3
SECONDS_PER_SAT=5

# Function to check if the internet gateway is reachable
check_internet_gateway() {
  echo "Checking internet gateway..."
  if ! ping -c 1 -W 3 google.com > /dev/null 2>&1; then
    echo "Internet gateway is not reachable. Aborting."
    echo "Internet gateway is not reachable. Aborting." >> /tmp/arguments_log.md
    exit 1
  fi
  [ "$VERBOSE" = "true" ] && echo "Internet gateway is reachable."
}

case "$METHOD" in
  auth_client)
    check_internet_gateway  # Check if the internet gateway is reachable before proceeding

    ECASH="$USERNAME"
    echo "Auth Client - ECASH: $ECASH" >> /tmp/arguments_log.md

    if echo "$ECASH" | grep -q "^LNURL"; then
      # Handle LNURLW
      RESPONSE=$(/www/cgi-bin/redeem_lnurlw.sh "$ECASH" 2>&1)
      CURL_EXIT_CODE=$?
      echo "Curl request - LNURLW: $ECASH, Exit Code: $CURL_EXIT_CODE" >> /tmp/arguments_log.md
      echo "Redeem response: $RESPONSE" >> /tmp/arguments_log.md

      if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl request failed with exit code $CURL_EXIT_CODE" >> /tmp/arguments_log.md
        exit 1
      fi

      # Check if the response contains "status":"OK"
      if echo "$RESPONSE" | jq -e '.status == "OK"' > /dev/null; then
        echo "Received response: $RESPONSE" >> /tmp/arguments_log.md
        PAID_AMOUNT=$(echo "$RESPONSE" | jq -r '.total_amount | tonumber')
        TOTAL_AMOUNT_MSAT=$((PAID_AMOUNT * 1000))
        echo "Amount paid: $PAID_AMOUNT" >> /tmp/arguments_log.md
        echo "Total amount msat: $TOTAL_AMOUNT_MSAT" >> /tmp/arguments_log.md
        DATA_AMOUNT=$(awk "BEGIN {print $TOTAL_AMOUNT_MSAT / $MSAT_PER_KB}")
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        SESSION_TIME=$((PAID_AMOUNT * SECONDS_PER_SAT))
        
        # Read existing JSON, append new entry, and write back
        if [ -f "$LOGFILE" ]; then
          jq --arg timestamp "$TIMESTAMP" --arg mac "$MAC" --arg data_amount "$DATA_AMOUNT" --arg sessiontime "$SESSION_TIME" \
            '. += [{"timestamp": $timestamp, "mac": $mac, "data_amount": $data_amount, "sessiontime": $sessiontime}]' \
            "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        else
          echo "[{\"timestamp\": \"$TIMESTAMP\", \"mac\": \"$MAC\", \"data_amount\": \"$DATA_AMOUNT\", \"sessiontime\": \"$SESSION_TIME\"}]" > "$LOGFILE"
        fi
        
        echo "Connection approved: LNURLW redeemed successfully, sessiontime $SESSION_TIME" >> /tmp/arguments_log.md

        echo $SESSION_TIME 0 0
        exit 0
      else
        echo "Connection rejected: LNURLW redemption failed" >> /tmp/arguments_log.md
        exit 1
      fi
    else
      # Handle e-cash
      RESPONSE=$(/www/cgi-bin/./curl_request.sh "$ECASH" 2>&1)
      CURL_EXIT_CODE=$?
      echo "Curl request - ECASH: $ECASH, Exit Code: $CURL_EXIT_CODE" >> /tmp/arguments_log.md
      echo "Redeem response: $RESPONSE" >> /tmp/arguments_log.md

      if [ $CURL_EXIT_CODE -ne 0 ]; then
        echo "Curl request failed with exit code $CURL_EXIT_CODE" >> /tmp/arguments_log.md
        exit 1
      fi

      # Check if the response contains "paid":true
      if echo "$RESPONSE" | grep -q '"paid": true'; then
        echo "Received response: $RESPONSE" >> /tmp/arguments_log.md
        PAID_AMOUNT=$(echo "$RESPONSE" | sed -n 's/.*"total_amount": $[0-9]*$.*/\1/p')
        TOTAL_AMOUNT_MSAT=$((PAID_AMOUNT * 1000))
        echo "Amount paid: $PAID_AMOUNT" >> /tmp/arguments_log.md
        echo "Total amount msat: $TOTAL_AMOUNT_MSAT" >> /tmp/arguments_log.md
        DATA_AMOUNT=$(awk "BEGIN {print $TOTAL_AMOUNT_MSAT / $MSAT_PER_KB}")
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        SESSION_TIME=$((PAID_AMOUNT * SECONDS_PER_SAT))
        
        # Read existing JSON, append new entry, and write back
        if [ -f "$LOGFILE" ]; then
          jq --arg timestamp "$TIMESTAMP" --arg mac "$MAC" --arg data_amount "$DATA_AMOUNT" --arg sessiontime "$SESSION_TIME" \
            '. += [{"timestamp": $timestamp, "mac": $mac, "data_amount": $data_amount, "sessiontime": $sessiontime}]' \
            "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
        else
          echo "[{\"timestamp\": \"$TIMESTAMP\", \"mac\": \"$MAC\", \"data_amount\": \"$DATA_AMOUNT\", \"sessiontime\": \"$SESSION_TIME\"}]" > "$LOGFILE"
        fi
        
        echo "Connection approved: Token redeemed successfully, sessiontime $SESSION_TIME" >> /tmp/arguments_log.md
        echo $SESSION_TIME 0 0
        exit 0
      else
        echo "Connection rejected: Token redemption failed" >> /tmp/arguments_log.md
        exit 1
      fi
    fi
    ;;
  client_auth|client_deauth|idle_deauth|timeout_deauth|ndsctl_auth|ndsctl_deauth|shutdown_deauth)
    INGOING_BYTES="$3"
    OUTGOING_BYTES="$4"
    # SESSION_START="$5"
    # SESSION_END="$6"
    # Log the details of client actions
    # echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES, SESSION_START: $SESSION_START, SESSION_END: $SESSION_END" >> /tmp/arguments_log.md
    echo "METHOD: $METHOD, MAC: $MAC, INGOING_BYTES: $INGOING_BYTES, OUTGOING_BYTES: $OUTGOING_BYTES" >> /tmp/arguments_log.md
    ;;
esac

# /www/cgi-bin/./update_purchase_log_with_token.sh

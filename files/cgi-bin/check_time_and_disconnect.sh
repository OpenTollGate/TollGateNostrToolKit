#!/bin/sh

# #!/bin/sh -e
# set -x

LOGFILE="/tmp/log/nodogsplash_data_purchases.json"
USAGE_LOGFILE="/tmp/log/nodogsplash_data_usage.json"

# Function to get the total data paid for each token
get_paid_data() {
  data=$(jq -r '.[] | "\(.mac) \(.data_amount) \(.sessiontime) \(.token)"' "$LOGFILE")
  echo "jq output: $data"  # Debugging line
  echo "$data" | awk '
  {
    token[$4] = $0
  }
  END {
    for (t in token) {
      print token[t]
    }
  }'
}

compare_and_update_usage_log() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.duration) \(.value.token)"')
  echo "Client Usage: $client_usage"  # Debugging line

  echo "$client_usage" | while read -r mac duration token; do
    current_duration=$(jq -r --arg token "$token" '.[$token].duration // 0' "$USAGE_LOGFILE")
    echo "Current Duration: $current_duration"  # Debugging line

    if [ "$duration" -gt "$current_duration" ]; then
      update_usage_log "$mac" "$duration" "$token"
    fi
  done
}

update_usage_log() {
  local mac="$1"
  local duration="$2"
  local token="$3"

  read_usage_log

  new_entry=$(jq -n --arg mac "$mac" --argjson duration "$duration" --arg token "$token" '{
    ($token): {
      "mac": $mac,
      "duration": $duration,
      "token": $token
    }
  }')

  updated_usage=$(echo "$usage_data" | jq --argjson new_entry "$new_entry" 'reduce ($new_entry | to_entries[]) as $i (.; .[$i.key] |= . + $i.value)')

  echo "$updated_usage" > "$USAGE_LOGFILE"
}

read_usage_log() {
  if [ ! -f "$USAGE_LOGFILE" ]; then
    echo "{}" > "$USAGE_LOGFILE"
  fi

  usage_data=$(cat "$USAGE_LOGFILE")
}

disconnect_clients_if_exceeded_time() {
  client_usage=$(ndsctl json | jq -r '.clients | to_entries[] | "\(.value.mac) \(.value.duration) \(.value.token)"')
  echo "Client Usage: $client_usage"  # Debugging line

  echo "$client_usage" | while read -r mac duration token; do
    associated_entry=$(echo "$paid_data" | awk -v token="$token" '$4 == token {print $0}' | head -n 1)
    session_time=$(echo "$associated_entry" | awk '{print $3}')
    echo "Checking MAC: $mac, Duration: $duration, Token: $token, Session Time: $session_time"

    if [ -z "$associated_entry" ]; then
      continue
    fi

    if [ "$duration" -gt "$session_time" ]; then
      echo "Disconnecting $mac: duration $duration exceeded session_time $session_time"
      ndsctl deauth "$mac"
    fi
  done
}

# Main
/www/cgi-bin/./add_accesstoken.sh
paid_data=$(get_paid_data)
echo "Paid Data: $paid_data"
compare_and_update_usage_log
disconnect_clients_if_exceeded_time


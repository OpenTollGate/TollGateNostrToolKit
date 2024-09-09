# #!/bin/sh

#!/bin/sh -e
set -x


# Path to the nodogsplash data purchases log
LOGFILE="/tmp/log/nodogsplash_data_purchases.json"

# Path to the nodogsplash data usage log
USAGE_LOGFILE="/tmp/log/nodogsplash_data_usage.json"

# Function to get the total data paid for each MAC address
get_paid_data() {
  jq -r '.[] | "\(.mac) \(.data_amount) \(.token // empty)"' "$LOGFILE" | awk '
    {
      mac[$1] += $2
      token[$1] = $3
    }
    END {
      for (m in mac) {
        print m, mac[m], token[m]
      }
    }'
}

# Function to get the current data usage of each client
get_client_usage() {
  ndsctl json | jq -r '.clients | to_entries[] | "\(.key) \(.value.downloaded) \(.value.uploaded) \(.value.token)"'
}

# Function to read the usage log
read_usage_log() {
  if [ ! -f "$USAGE_LOGFILE" ]; then
    echo "{}" > "$USAGE_LOGFILE"
  fi
  cat "$USAGE_LOGFILE" | jq '.'
}

# Function to update the usage log
update_usage_log() {
  local mac="$1"
  local downloaded="$2"
  local uploaded="$3"
  local token="$4"

  usage_data=$(read_usage_log)

  new_entry=$(jq -n --arg mac "$mac" --argjson downloaded "$downloaded" --argjson uploaded "$uploaded" --arg token "$token" \
    '{
      ($token): {
        "mac": $mac,
        "downloaded": $downloaded,
        "uploaded": $uploaded,
        "token": $token
      }
    }')

  updated_usage=$(echo "$usage_data" | jq --argjson new_entry "$new_entry" \
    'reduce ($new_entry | to_entries[]) as $i (.; .[$i.key] |= . + $i.value)')

  echo "$updated_usage" > "$USAGE_LOGFILE"
}

# Function to update token in the purchases log if necessary
update_token_in_purchases_log() {
  local mac="$1"
  local token="$2"

  jq --arg mac "$mac" --arg token "$token" '
    map(if .mac == $mac and (.token == null or .token == "") then .token = $token else . end)' "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
}

# Function to compare and update the usage log if necessary
compare_and_update_usage_log() {
  client_usage=$(get_client_usage)

  echo "$client_usage" | while read -r mac downloaded uploaded token; do
    current_downloaded=$(jq -r --arg token "$token" '.[$token].downloaded // 0' "$USAGE_LOGFILE")
    current_uploaded=$(jq -r --arg token "$token" '.[$token].uploaded // 0' "$USAGE_LOGFILE")

    if [ "$downloaded" -gt "$current_downloaded" ] || [ "$uploaded" -gt "$current_uploaded" ]; then
      update_usage_log "$mac" "$downloaded" "$uploaded" "$token"
    fi
  done
}

# Get the paid data
paid_data=$(get_paid_data)

# Get the client usage and update usage log
compare_and_update_usage_log

# Verbose flag
VERBOSE=true

# Compare and disconnect if necessary
client_usage=$(get_client_usage)
echo "$client_usage" | while read -r mac downloaded uploaded token; do
  total_data_used=$(awk "BEGIN {print $downloaded + $uploaded}")
  total_data_paid=$(echo "$paid_data" | awk -v mac="$mac" '$1 == mac {print $2}')
  associated_token=$(echo "$paid_data" | awk -v mac="$mac" '$1 == mac {print $3}')
  
  if [ -z "$associated_token" ]; then
    update_token_in_purchases_log "$mac" "$token"
  fi

  if [ -n "$total_data_paid" ] && [ "$(awk "BEGIN {print ($total_data_used > $total_data_paid)}")" -eq 1 ]; then
    echo "Disconnecting $mac: Used $total_data_used KB, Paid for $total_data_paid KB"
    ndsctl deauth "$mac"
  else
    if [ "$VERBOSE" = true ]; then
      data_left=$(awk "BEGIN {print $total_data_paid - $total_data_used}")
      echo "$mac: Used $total_data_used KB, Paid for $total_data_paid KB, Data left $data_left KB"
    fi
  fi
done



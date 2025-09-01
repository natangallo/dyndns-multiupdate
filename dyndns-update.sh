#!/bin/bash
###############################################################################
# Script: dyndns-update.sh
# Description: Automatically updates DynDNS hosts when the server's public IP
#              changes. Logs changes and prints human-readable output.
# Author: Natan Gallo
# Date: 2025-09-01
# Version: 1.0
# Requirements: curl, bash
# License: MIT License
#
# Notes:
# - Reads host credentials from dyndns-credentials.csv
# - Maintains IP history in dyndns-ip-records.txt
# - Logs IP changes in dyndns-update.log
# - Checks the server's public IP using api.ipify.org
###############################################################################

# === CONFIGURATION ===
ROOT_FOLDER="/your/folder/dyndns"
CRED_FILE="$ROOT_FOLDER/dyndns-credentials.csv"
LOG_FILE="$ROOT_FOLDER/dyndns-update.log"
IP_RECORD_FILE="$ROOT_FOLDER/dyndns-ip-records.txt"

mkdir -p "$ROOT_FOLDER"

# === FUNCTIONS ===

# Get the current public IP of the server
get_public_ip() {
  curl -s https://api.ipify.org
}

# Update the IP record file
update_ip_record() {
  host=$1
  ip=$2
  executions=$3
  first_seen=$4
  date=$(date "+%Y-%m-%d %H:%M:%S")
  sed -i "/^$host /d" "$IP_RECORD_FILE"
  echo "$host $ip $date $executions $first_seen" >> "$IP_RECORD_FILE"
}

# Calculate time difference in human-readable format
time_diff_pretty() {
  last_change=$1
  current_time=$(date +%s)

  if [[ "$last_change" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
    last_time=$(date -d "$last_change" +%s)
    diff=$(( current_time - last_time ))

    if [ $diff -lt 3600 ]; then
      echo "$(( diff / 60 )) minutes"
    elif [ $diff -lt 86400 ]; then
      echo "$(( diff / 3600 )) hours"
    else
      echo "$(( diff / 86400 )) days"
    fi
  else
    echo "0 minutes"
  fi
}

# Print to screen and log simultaneously
log_and_print() {
  echo "$1" | tee -a "$LOG_FILE"
}

# === MAIN LOOP ===
while IFS=',' read -r host user pass; do
  [ -z "$host" ] && continue  # skip empty lines

  current_ip=$(get_public_ip)

  if [ -z "$current_ip" ]; then
    log_and_print "[$(date)] Host: $host - ERROR retrieving server public IP"
    continue
  fi

  # Retrieve previous record
  record=$(grep "^$host " "$IP_RECORD_FILE")
  last_ip=$(echo "$record" | awk '{print $2}')
  last_date=$(echo "$record" | awk '{print $3, $4}')
  executions=$(echo "$record" | awk '{print $5}')
  first_seen=$(echo "$record" | awk '{print $6, $7}')

  # First run for this host
  if [ -z "$last_ip" ]; then
    update_ip_record "$host" "$current_ip" 1 "$(date '+%Y-%m-%d %H:%M:%S')"
    log_and_print "[$(date)] Host: $host - First detection, IP $current_ip"
    continue
  fi

  # IP unchanged
  if [ "$current_ip" == "$last_ip" ]; then
    executions=$((executions+1))
    update_ip_record "$host" "$current_ip" "$executions" "$first_seen"

    diff_readable=$(time_diff_pretty "$last_date")
    echo "Host: $host - IP unchanged ($current_ip) for $diff_readable"
    continue
  fi

  # IP changed → update DynDNS
  diff_readable=$(time_diff_pretty "$last_date")
  curl_output=$(curl -s "https://update.dyndns.it/nic/update?hostname=$host&username=$user&password=$pass")

  log_and_print "[$(date)] Host: $host - IP changed from $last_ip to $current_ip"
  log_and_print "  Stable period: $first_seen → $last_date ($executions executions, duration $diff_readable)"
  log_and_print "  DynDNS response: $curl_output"
  log_and_print ""

  update_ip_record "$host" "$current_ip" 1 "$(date '+%Y-%m-%d %H:%M:%S')"

done < "$CRED_FILE"
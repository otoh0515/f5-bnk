#! /bin/bash

LOG_FILE="/var/log/bnk-deployment.log"

event="${1:-"command to succeed"}"
timeout="${2:-300}"
start_time=$(date +%s)
echo "Waiting for up to ${timeout}s for ${event} "
while true; do
#  wait_for_command
  current_time=$(date +%s)
  elapsed_time=$((current_time - start_time))
  if [[ -n "$(wait_for_command 2> /dev/null)" ]]; then
    echo "$(date) DEBUG wait_for ${event} READY after ${elapsed_time}s" | sudo tee -a ${LOG_FILE} > /dev/null
    echo "Ready!"
    break
  fi
  if [ $elapsed_time -ge $timeout ]; then
    echo "$(date) DEBUG wait_for ${event} TIMEOUT after ${elapsed_time}s" | sudo tee -a ${LOG_FILE} > /dev/null
    echo "Timeout reached - aborting"
#    exit 1
     break
  fi
  echo "not ready... (${elapsed_time}s)"
  sleep 5
done

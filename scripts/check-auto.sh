#!/bin/bash

## check-auto.sh

# this script checks if automatic.sh is already running
# in the background. Running multiple instances of 
# deploy.sh concurrently will cause issues.

SCRIPT_NAME="automatic.sh"
CURRENT_PID=$$
pids=$(pgrep -f "${SCRIPT_NAME}")
if [[ -n "$(echo ${pids} | grep -v "^${CURRENT_PID}\$")" ]]; then
  echo "${SCRIPT_NAME} is already running PID: ${pids}"
  exit 1
fi

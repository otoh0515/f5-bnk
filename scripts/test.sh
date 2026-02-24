#! /bin/bash

## test.sh

export LOG_FILE="/var/log/bnk-deployment.log"
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/"

ssh client curl -Lskm1 http://red.demo.net
ssh client curl -Lskm1 http://red2.demo.net
ssh client curl -Lskm1 http://blue.demo.net
ssh client curl -Lskm1 http://blue2.demo.net
ssh client curl -Lskm1 https://blue.secure-demo.net
ssh client curl -Lskm1 https://red.secure-demo.net

pass_result="1-2-3-4-5-6-7"
for arg in "$@"; do
    if [[ "$arg" == "--fw" ]]; then
        pass_result="1-2-3-4-5-6-7-8"
    fi
done


### test egress
kubectl -n red exec deployments/nginx-deployment -c netshoot -- curl -Lskm1 10.2.30.101

fw_pass=""
if [[ -z "$(ssh client curl -Lskm1 --interface 10.2.30.101 http://red.demo.net)" ]]; then
  echo "Red/10.2.30.101 BLOCKED"
  fw_pass="-8"
fi

echo "testing deployment..."
pass=""

test="$(ssh client curl -Lskm1 http://red.demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}1"
fi

test="$(ssh client curl -Lskm1 http://red2.demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-2"
fi

test="$(ssh client curl -Lskm1 http://blue.demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-3"
fi

test="$(ssh client curl -Lskm1 http://blue2.demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-4"
fi

test="$(ssh client curl -Lskm1 https://blue.secure-demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-5"
fi

test="$(ssh client curl -Lskm1 https://red.secure-demo.net/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-6"
fi

test="$(kubectl -n red exec deployments/nginx-deployment -c netshoot -- curl -Lskm1 10.2.30.101/flag)"
if [ -n "${test}" ]; then
  pass="${pass}-7"
fi

# Temporary
#echo "DEBUG: Firewall test bypassed"
#fw_pass="-8"

pass="${pass}${fw_pass}"
#version="$(bash ${SCRIPT_DIR}version.sh)"
version="$(bash /home/ubuntu/udf-cne/cne-tools/bin/cne-version.sh)" # use cne-tools

if [ "${pass}" == "${pass_result}" ]; then
  echo "$(date) INFO Test OK - ${version} - tests passed:${pass}" | sudo tee -a "${LOG_FILE}"
  result=0
else
  echo "$(date) ERROR Test failed - ${version} - tests passed:${pass}" | sudo tee -a "${LOG_FILE}"
  echo "hint: test again with bnk-test after re-starting cne-controller with"
  echo "kubectl rollout restart deployment f5-cne-controller -n f5-bnk"
  if [ -f "${SCRIPT_DIR}stop-on-failure" ]; then
    echo "$(date) INFO Breakpoint triggered" | sudo tee -a "${LOG_FILE}"
    exit 1
  fi
  result=1
fi


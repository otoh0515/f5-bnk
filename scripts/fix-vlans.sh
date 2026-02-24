#! /bin/bash

export LOG_FILE="/var/log/bnk-deployment.log"
  
vlans_up () {
  vlans="$(kubectl get f5-spk-vlans.k8s.f5net.com -A | grep "programmed" | kubectl get f5-spk-vlans.k8s.f5net.com -A | grep "default" | wc -l)"
  return "${vlans}"
}

kick_cne () {
  cne="$(kubectl get pods -n default | grep "^f5-cne-controller-" | sed "s| .*$||")"
  echo "$(date) INFO $cne - connectivity failed - restarting" | sudo tee -a "${LOG_FILE}" > /dev/null
  kubectl delete pod $cne -n default
  kubectl wait --for=condition=Ready pod $cne --timeout=300s

  wait_for () { source /home/ubuntu/udf-cne/cne-tools/bin/wait_for.sh "$@" ; } # call directly in case cne-tools not available
  
  wait_for_command () {
    if [ "$(vlans_up)" == "4" ]; then
      echo "vlans ok"
    fi
  }
  wait_for "all vlans established"
}

if [ "$(vlans_up)" != "4" ]; then
  kick_cne
fi


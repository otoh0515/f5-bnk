#! /bin/bash

version=$(kubectl get bnkgatewayclass.k8s.f5.com -A -o jsonpath='{.items[].spec.manifestVersion}' 2>/dev/null)

case "$version" in
  2.0.0-*)         
    echo "BNK release: 2.0.0" 
    source ~/udf-cne/bnk-2.2.0-ga/scripts/full-remove.sh
    ;;

  2.1.0-*)
    echo "BNK release: 2.1.0"
    source ~/udf-cne/bnk-2.2.0-ga/scripts/full-remove.sh
    ;;
  *)                          
    path="$(cat ~/.bash_aliases  | grep "scripts/deploy/additional-jumphost-aliases" | sed "s|\(^.*/udf-cne/.*/\)deploy/additional-jumphost-aliases.*$|\1|")"
    echo "Unknown BNKgatewayclass manifest: ${version}, recommend ${path}full-remove.sh" 
    #source ${path}full-remove.sh
    ;;
esac


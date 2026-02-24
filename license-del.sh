#!/bin/sh

NS=${NS:="f5-utils"}

kubectl delete secret -n $NS activationmessage
kubectl delete secret -n $NS activationstatus
kubectl delete secret -n $NS activationtimestamp
kubectl delete secret -n $NS configreport
kubectl delete secret -n $NS configreportsignedackresponse
kubectl delete secret -n $NS context
kubectl delete secret -n $NS csr
kubectl delete secret -n $NS customerprovidedid
kubectl delete secret -n $NS digitalassetid
kubectl delete secret -n $NS digitalassetname
kubectl delete secret -n $NS digitalassetversion
kubectl delete secret -n $NS entitlements
kubectl delete secret -n $NS initialregistrationstatus
kubectl delete secret -n $NS licensekey
kubectl delete secret -n $NS licensestatus
kubectl delete secret -n $NS modeofoperation
kubectl delete secret -n $NS previousreportname
kubectl delete secret -n $NS previousreportverifieddate
kubectl delete secret -n $NS productname
kubectl delete secret -n $NS statehistory
kubectl delete secret -n $NS statesofdecay
kubectl delete secret -n $NS switchlicensestatus
kubectl delete secret -n $NS telemetrystatus

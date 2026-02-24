#! /bin/bash

## 041-remove-flo.sh
echo "## 041-remove-flo.sh"

helm uninstall flo -n f5-bnk
kubectl delete -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml # uninstall FLO first
helm uninstall f5-spk-crds-common # not required in v2.1
helm uninstall f5-spk-crds-service-proxy # not required in v2.1

# kubectl get crds | grep "k8s.f5.com" | sed "s|\([^ ]*\).*$|kubectl delete crds \1|" | bash
# kubectl get crds | grep "k8s.f5net.com" | sed "s|\([^ ]*\).*$|kubectl delete crds \1|" | bash
# kubectl get crds | grep "fic.f5.com" | sed "s|\([^ ]*\).*$|kubectl delete crds \1|" | bash

kubectl delete -f far-secret.yaml -n f5-bnk
kubectl delete -f far-secret.yaml -n f5-utils
kubectl delete -f far-secret-ehf.yaml -n f5-bnk
kubectl delete -f far-secret-ehf.yaml -n f5-utils

# remove secrets not removed by FLO
kubectl delete secrets f5-observer-cert-secret -n f5-bnk
kubectl delete secrets f5-observer-operator-cert-secret -n f5-bnk
kubectl delete secrets f5-observer-receiver-cert-secret -n f5-bnk
kubectl delete secrets tls-blobd-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-blobd-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-debug-amqp-clt-secret -n f5-bnk
kubectl delete secrets tls-debug-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-debug-mds-clt-secret -n f5-bnk
kubectl delete secrets tls-dynamic-routing-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5-afm-pccd-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5-controller-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5-debug-sidecar-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5-lic-helper-amqp-clt-secret -n f5-bnk
kubectl delete secrets tls-f5-lic-helper-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5-tmrouted-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-f5ingress-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-f5ingress-webhookvalidating-svr-secret -n f5-bnk
kubectl delete secrets tls-otel-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-pccd-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-pccd-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-qkview-blobd-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-tmm-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-tmm-mds-clt-secret -n f5-bnk
kubectl delete secrets tls-tmm-qkview-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-tmstatsd-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-toda-logging-grpc-svr-secret -n f5-bnk
kubectl delete secrets tls-tpm-grpc-clt-secret -n f5-bnk
kubectl delete secrets tls-tpm-grpc-svr-secret -n f5-bnk


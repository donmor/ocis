#!/bin/bash

NAMESPACE="ocis"
INGRESS_NAME="proxy"
TIMEOUT=100   # Timeout in seconds (5 minutes)
INTERVAL=5    # Check every 5 seconds

echo "Waiting for ingress '$INGRESS_NAME' in namespace '$NAMESPACE' to get an external IP..."

SECONDS_WAITED=0
while true; do
    ADDRESS=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    # If IP is not set, try getting hostname (used by some cloud providers)
    if [ -z "$ADDRESS" ]; then
        ADDRESS=$(kubectl get ingress "$INGRESS_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    fi

    if [ -n "$ADDRESS" ]; then
        echo "✅ Ingress is ready! ADDRESS: $ADDRESS"
        break
    fi

    if [ "$SECONDS_WAITED" -ge "$TIMEOUT" ]; then
        echo "❌ Timeout: Ingress address not assigned after $TIMEOUT seconds."
        # exit 1
    fi

    echo "⏳ Still waiting... ($SECONDS_WAITED/$TIMEOUT seconds)"
    kubectl get ingress -n ocis
    kubectl get svc -n ingress
    kubectl describe ingress proxy
    sleep "$INTERVAL"
    SECONDS_WAITED=$((SECONDS_WAITED + INTERVAL))
done

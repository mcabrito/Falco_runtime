#!/usr/bin/env bash
set -euo pipefail

# Stream Falco logs for the presentation
NAMESPACE="falco"
LABEL="app.kubernetes.io/name=falco"

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Error: kubectl not found in PATH"
  exit 1
fi

echo "Streaming Falco logs (namespace: $NAMESPACE). Press Ctrl+C to stop."

# If no Falco pods exist, give guidance and exit non-zero
if ! kubectl get ns >/dev/null 2>&1 || ! kubectl get ns | grep -q "^$NAMESPACE"; then
  echo "Namespace '$NAMESPACE' not found. Install Falco first (see scripts/README.md)."
  exit 2
fi

pods=$(kubectl get pods -n "$NAMESPACE" -l "$LABEL" --no-headers 2>/dev/null || true)
if [ -z "$pods" ]; then
  echo "No Falco pods found with label '$LABEL' in namespace '$NAMESPACE'."
  echo "Install Falco or wait until pods appear."
  exit 3
fi

kubectl logs -f -n "$NAMESPACE" -l "$LABEL" --tail=200

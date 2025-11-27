#!/usr/bin/env bash
set -euo pipefail

# Demo attacker script — runs a sequence of simulated attacker actions inside `victim-pod`.
# Usage: ./scripts/demo_attacker.sh [--exec]
#  - default: runs non-interactive sequence of commands
#  - --exec : open an interactive shell inside the victim pod (kubectl exec -it)

VICTIM_POD="victim-pod"
IMAGE="busybox"
SLEEP_CMD="sleep 3600"

function check_kubectl() {
  if ! command -v kubectl >/dev/null 2>&1; then
    echo "Error: kubectl not found in PATH"
    exit 1
  fi
}

function ensure_victim() {
  # If pod not Running, recreate it
  status=$(kubectl get pod "$VICTIM_POD" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$status" != "Running" ]; then
    echo "Victim pod not running (status: $status). Creating $VICTIM_POD..."
    kubectl delete pod "$VICTIM_POD" --ignore-not-found=true >/dev/null 2>&1 || true
    kubectl run "$VICTIM_POD" --image="$IMAGE" --restart=Never -- $SLEEP_CMD
    echo "Waiting for $VICTIM_POD to be Ready (60s timeout)..."
    kubectl wait --for=condition=Ready pod/$VICTIM_POD --timeout=60s >/dev/null 2>&1 || true
  else
    echo "Victim pod is already Running"
  fi
  kubectl get pod "$VICTIM_POD" -o wide || true
}

function run_sequence() {
  echo "Running simulated attacker sequence inside $VICTIM_POD (non-interactive)."

  cmds=(
    "echo ATTACK: read serviceaccount token; cat /var/run/secrets/kubernetes.io/serviceaccount/token || true"
    "echo ATTACK: create suspicious file; touch /etc/iam-a-backdoor 2>/dev/null || true"
    "echo ATTACK: create executable in /tmp; echo malicious > /tmp/backdoor && chmod +x /tmp/backdoor || true"
    "echo ATTACK: list processes; ps aux | head -n 10 || true"
    "echo ATTACK: ping (short); ping -c 1 8.8.8.8 2>/dev/null || true"
    "echo ATTACK: search config files; find / -name '*.conf' 2>/dev/null | head -5 || true"
  )

  for c in "${cmds[@]}"; do
    echo "--> $c"
    kubectl exec -i "$VICTIM_POD" -- sh -c "$c"
    # give Falco a moment to process the event so logs appear in the defender terminal
    sleep 1
  done

  echo "Simulated attacker sequence complete."
}

function open_shell() {
  echo "Opening interactive shell in $VICTIM_POD (exit to return)"
  kubectl exec -it "$VICTIM_POD" -- /bin/sh
}

# Main
check_kubectl
ensure_victim

if [ "${1:-}" = "--exec" ]; then
  open_shell
else
  run_sequence
fi

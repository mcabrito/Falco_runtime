Demo scripts for the Falco presentation

Files:
- `demo_defender.sh`: Stream Falco logs for the demo (requires Falco installed in namespace `falco`).
- `demo_attacker.sh`: Run simulated attacker actions against `victim-pod`. Supports non-interactive mode (default) and interactive shell (`--exec`).

Quick usage (two terminals):

Terminal 1 — Defender (stream Falco logs):

```bash
# Make executable if needed
chmod +x scripts/demo_defender.sh
./scripts/demo_defender.sh
```

Terminal 2 — Attacker (run scripted attacks):

```bash
chmod +x scripts/demo_attacker.sh
# Non-interactive (recommended for demo):
./scripts/demo_attacker.sh

# Or open an interactive shell inside the victim pod:
./scripts/demo_attacker.sh --exec
```

Notes and troubleshooting:
- Ensure Falco is installed before streaming logs. Install with Helm:

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm upgrade --install falco falcosecurity/falco --namespace falco --create-namespace --set driver.kind=modern_ebpf --set tty=true
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=falco -n falco --timeout=180s || true
```

- If `modern_ebpf` driver fails on Docker Desktop, try `--set driver.kind=userspace`.
- The attacker script will recreate `victim-pod` if it is not Running.
- Allow 1–2 seconds between attacker commands so Falco has time to capture and emit alerts to the logs.

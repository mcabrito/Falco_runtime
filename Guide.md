# Team Presentation Guide: Falco + CKS Runtime Security Demo

This guide shows how to present the Falco + CKS runtime security concepts to your team using the automated Makefile setup.

---

## Before the Presentation

### 1. Setup Your Environment (15-20 minutes before)
Run this once to ensure everything is ready:

```bash
cd /path/to/apresentacao
make setup
```

**Expected output:**
```
✅ Setup Concluído!
Para rodar a demo, abra dois terminais e rode:
  make demo-defender (Terminal 1)
  make demo-attacker (Terminal 2)
```

### 2. Verify Everything Works
```bash
# Check Falco is running
kubectl get pods -n falco

# Check victim pod exists
kubectl get pod victim-pod

# Start monitoring
make demo-defender
# (In another terminal)
make demo-attacker
```

---

## Live Presentation Flow (20-30 minutes)

### Part 1: Introduction (3 minutes)
**What You'll Show:**
- Explain what runtime security is
- Why Falco is important for CKS
- How it detects threats in real-time

**Talking Points:**
> "Today we're going to see runtime security in action. Falco is an open-source runtime security tool that monitors system calls and detects suspicious behavior in real-time. This is crucial for the Certified Kubernetes Security (CKS) exam."

---

### Part 2: Setup Demonstration (2 minutes)

**Show the one-command setup:**
```bash
make setup
```

**Explain what's happening:**
- ✅ Checking kubectl and helm are installed
- ✅ Starting Docker Desktop with Kubernetes
- ✅ Installing Falco as a DaemonSet via Helm
- ✅ Creating a test/victim pod

**Key Point:**
> "This single command does everything: installs Falco monitoring, creates a test pod, and is ready for security demonstrations."

---

### Part 3: Infrastructure Overview (2 minutes)

**Show the architecture:**
```bash
kubectl get all -n falco
kubectl get pod victim-pod
```

**Explain:**
- Falco runs as a DaemonSet (one pod per node)
- Uses modern_ebpf driver for efficient syscall monitoring
- Victim pod is ready for testing
- All in Docker Desktop's single-node cluster

```
┌─────────────────────────────────────────┐
│     Docker Desktop Kubernetes           │
│  ┌──────────────────────────────────┐   │
│  │  Falco DaemonSet                 │   │
│  │  ├─ System Call Monitoring      │   │
│  │  ├─ Rule Engine                 │   │
│  │  └─ Alert Generation            │   │
│  │                                  │   │
│  │  Victim Pod (busybox)            │   │
│  │  └─ Target for Demonstrations   │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

---

### Part 4: Defender View - Live Monitoring (5 minutes)

**Terminal 1: Start monitoring**
```bash
make demo-defender
```

**What appears:**
- Live Falco logs streaming
- Security events in JSON format
- Real-time threat detection

**Explain to audience:**
> "This is Falco's monitoring view. It's continuously watching all system calls in the cluster. When suspicious activity is detected, you see an alert here. The logs show metadata about what happened, who did it, and why it's suspicious."

**Keep this terminal open** - you'll monitor alerts here.

---

### Part 5: Attacker View - Simulate Threats (15 minutes)

**Terminal 2: Enter the victim pod**
```bash
make demo-attacker
```

You're now inside the busybox pod. Slowly run these attacks, pausing between each to let the team see the alerts:

#### Attack 1: Read Kubernetes Secrets (1 minute)
**What it demonstrates:** Unauthorized access to service account tokens

```bash
# In attacker terminal
cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

**Watch Terminal 1** for alerts:
- Falco detects: "Read sensitive file"
- Shows: File path, user, container ID, timestamp

**Explain:**
> "This is a classic threat: someone reading the Kubernetes service account token. With this token, they could authenticate to the API server. Falco caught it immediately."

---

#### Attack 2: Modify System Files (2 minutes)
**What it demonstrates:** Backdoor installation attempts

```bash
# In attacker terminal
touch /etc/iam-a-backdoor
cat > /tmp/suspicious-script.sh << 'EOF'
#!/bin/bash
echo "This is suspicious"
EOF
chmod +x /tmp/suspicious-script.sh
```

**Watch Terminal 1** for alerts:
- Falco detects: "Write below etc"
- Shows: File modifications, directory traversal

**Explain:**
> "Modifying system files is a classic backdoor technique. Falco's file integrity monitoring caught both the creation attempt and the modification."

---

#### Attack 3: Suspicious Network Connections (3 minutes)
**What it demonstrates:** Command and control (C2) communication

```bash
# In attacker terminal (if curl available)
# Try to connect to suspicious domains
wget http://malicious-domain.com 2>&1 | head -20
# or
curl http://api.suspicious.local 2>&1 | head -20
```

**Watch Terminal 1** for alerts:
- Network policy violations
- Unusual outbound connections
- DNS queries to suspicious domains

**Explain:**
> "Falco can detect network anomalies. If your policies say only certain outbound connections are allowed, unauthorized ones get flagged immediately. This is crucial for preventing data exfiltration."

---

#### Attack 4: Privilege Escalation Attempts (2 minutes)
**What it demonstrates:** Unauthorized privilege escalation

```bash
# In attacker terminal
sudo su 2>&1 || echo "Not allowed (expected)"
id
cat /etc/shadow 2>&1 | head
```

**Watch Terminal 1** for alerts:
- Privilege escalation attempts
- Unauthorized sudo usage
- Access to restricted files

**Explain:**
> "Attempting to escalate privileges is a common attack. Falco watches these attempts and can block them if you configure restrictive policies. This is one of the CKS exam requirements - preventing unauthorized privilege escalation."

---

#### Attack 5: Suspicious Process Execution (2 minutes)
**What it demonstrates:** Unexpected process execution

```bash
# In attacker terminal
# Create and execute a suspicious script
echo "#!/bin/sh" > /tmp/evil.sh
echo "echo pwned" >> /tmp/evil.sh
sh /tmp/evil.sh

# Or try unusual commands
find / -name "*.conf" 2>/dev/null | head -5
```

**Watch Terminal 1** for alerts:
- Unexpected child processes
- File execution from suspicious locations
- Anomalous command patterns

**Explain:**
> "Falco's behavioral monitoring detects when processes do unexpected things. Even if the process names look normal, the behavior pattern can reveal attacks."

---

### Part 6: Review and Recap (5 minutes)

**Go back through what happened:**

1. **Show the detection timeline:**
   ```bash
   # Scroll through Terminal 1 to show all detected events
   ```

2. **Explain the Falco rules that triggered:**
   - File integrity rules
   - Network policy rules
   - Process execution rules
   - Privilege escalation rules

3. **Connect to CKS concepts:**
   - Pod Security Standards
   - Network Policies
   - RBAC
   - Runtime Security
   - Supply Chain Security

**Key Takeaway:**
> "This is why runtime security matters in CKS. You can't rely on just network policies or RBAC. You need to monitor what containers actually do at runtime. Falco gives you that visibility."

---

## Cleanup After Demo

```bash
make clean
```

This safely removes all demo resources.

---

## Troubleshooting During Presentation

### If Falco Logs Stop Appearing
```bash
# Restart monitoring
# Press Ctrl+C in Terminal 1
make demo-defender
```

### If Can't Enter Victim Pod
```bash
# Recreate the pod
kubectl delete pod victim-pod
make deploy-victim
```

### If Kubernetes Gets Stuck
```bash
# Restart everything
make clean
sleep 10
make setup
```

---

## Key Discussion Points

### Why Runtime Security?
- Network policies only control network traffic
- RBAC only controls API access
- You need visibility into actual container behavior
- Falco provides that visibility

### How It Works
1. **Hook into syscalls** - monitor what processes do
2. **Compare against rules** - check behavior against known good patterns
3. **Generate alerts** - immediate notification of anomalies
4. **Take action** - can auto-block/kill suspicious containers

### For CKS Exam Context
- **Runtime Security** is one of the domains
- Falco is the recommended open-source tool
- Know how to deploy it in Kubernetes
- Understand detection rules
- Be able to interpret Falco logs

---

## FAQ for Your Team

**Q: Doesn't this impact performance?**
A: Falco uses eBPF which is extremely efficient. Overhead is typically 1-2% CPU per node. Modern_ebpf driver doesn't require kernel module compilation.

**Q: Can we customize the detection rules?**
A: Yes! Falco has built-in rules and you can write custom rules. It's very flexible for different security policies.

**Q: Does this work in production?**
A: Absolutely. Falco is production-ready and used by major enterprises. It has minimal overhead and can forward alerts to multiple systems.

**Q: How do we integrate with our logging system?**
A: Falco outputs to JSON and can send to Slack, Kafka, Syslog, email, and more via plugins.

**Q: What about false positives?**
A: You tune the rules to your environment. Falco comes with a good baseline, and you can allow-list known good behaviors.

---

## Advanced Talking Points

### For Experienced Audience

**Show the rules file:**
```bash
kubectl get configmap -n falco -o yaml | grep -A 100 "rules:"
```

**Explain rule structure:**
- Macros for reusable conditions
- Rules for specific threats
- Conditions combine macros into policies
- Actions when triggered

**Show the syscalls being monitored:**
```bash
# List what syscalls Falco cares about
grep "syscall" /etc/falco/falco_rules.yaml | head -20
```

### For Security Engineers

**Discuss:**
- Signal-to-noise ratio
- Rule tuning vs. false positives
- Integration with SIEM systems
- Anomaly detection vs. signature-based
- Cost of monitoring at scale

---

## Presentation Slides Notes

### Slide 1: Introduction
- Show the Falco logo
- Brief definition: "Runtime security monitoring"

### Slide 2: The Problem
- Show traditional security gaps
- Diagram: network policies vs. runtime behavior

### Slide 3: The Solution
- Show Falco architecture
- Syscall -> Rules -> Alerts

### Slide 4: Demo Setup
- Show the Makefile command
- Explain Docker Desktop + Kubernetes

### Slide 5-9: Live Demo
- Each attack scenario on its own slide
- Show the Falco alert response

### Slide 10: Key Takeaways
- Runtime visibility is critical
- Falco is powerful and simple
- CKS exam requirement
- Production-ready tool

### Slide 11: Q&A

---

## Recording Tips

If you want to record this demo:

1. **Open both terminals side-by-side** for screen recording
2. **Zoom to 120-150%** so audience can see small text
3. **Slow down your typing** - use bash history (arrow keys)
4. **Pause between attacks** - let alerts appear before moving on
5. **Narrate what you're doing** - explain the security implications
6. **Save the terminal output** for later reference

```bash
# Record terminal output
script demo-session.log

# Run your demo...

# Exit to save
exit
```

---

## Team Exercise (Optional)

After the demo, give your team a challenge:

**Exercise:** "Write a Falco rule that detects when someone reads the `/etc/passwd` file"

This helps them understand:
- How rules work
- Practical security monitoring
- The thinking behind threat detection

---

## Resources to Share

- **Falco Official:** https://falco.org
- **CKS Exam Handbook:** https://github.com/walidshaari/Certified-Kubernetes-Security-Specialist
- **Falco Rules Repository:** https://github.com/falcosecurity/rules
- **Kubernetes Security Best Practices:** https://kubernetes.io/docs/concepts/security/

---

## Estimated Timings

| Section | Duration |
|---------|----------|
| Introduction | 3 min |
| Setup Demo | 2 min |
| Architecture Explanation | 2 min |
| Defender View Setup | 1 min |
| Attack 1: Read Secrets | 2 min |
| Attack 2: File Modification | 2 min |
| Attack 3: Network Anomalies | 2 min |
| Attack 4: Privilege Escalation | 2 min |
| Attack 5: Process Execution | 2 min |
| Review & Recap | 3 min |
| Q&A | 5 min |
| **TOTAL** | **~27 min** |

---

## After the Presentation

1. **Share the files:**
   - Send them the Makefile
   - Share README.md for setup instructions
   - Provide Guide.md for reference

2. **Let them try it:**
   - Give them time to run `make setup`
   - Have them execute attacks themselves
   - Encourage experimentation

3. **Follow up with:**
   - Key learnings document
   - Falco rules examples
   - CKS exam prep resources

---

**Good luck with your presentation! 🎯**

**Remember:** The key to a great security demo is enthusiasm and clear explanation. Take your time, let the audience see the alerts appear, and explain the security implications. They'll remember the experience much more than the details.

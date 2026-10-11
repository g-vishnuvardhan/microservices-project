#!/usr/bin/env bash
# ==============================================================================
# Automated Microservices Deployment Script (Bash)
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================================${NC}"
echo -e "${GREEN} Automated Microservices Deployment to Kubernetes (DevOps Lab)${NC}"
echo -e "${CYAN}=================================================================${NC}"

# 1. Pre-flight checks
echo -e "\n${YELLOW}[STEP 1/5] Checking Prerequisites (Docker & Kubernetes)...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Docker CLI not installed.${NC}"; exit 1; }
docker info >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Docker daemon is not running.${NC}"; exit 1; }
echo -e "${GREEN}[OK] Docker daemon is active.${NC}"

command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}[ERROR] kubectl CLI not installed.${NC}"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Kubernetes cluster is unreachable.${NC}"; exit 1; }
echo -e "${GREEN}[OK] Kubernetes cluster is reachable.${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 2. Build Maven Artifacts
echo -e "\n${YELLOW}[STEP 2/5] Building Maven Artifacts...${NC}"
(cd "$PROJECT_ROOT/user-service" && chmod +x ./mvnw && ./mvnw clean package -DskipTests)
(cd "$PROJECT_ROOT/product-service" && chmod +x ./mvnw && ./mvnw clean package -DskipTests)
echo -e "${GREEN}[OK] Maven artifacts built.${NC}"

# 3. Build Docker Images
echo -e "\n${YELLOW}[STEP 3/5] Building Docker Images...${NC}"
docker build -t ghcr.io/g-vishnuvardhan/user-service:latest "$PROJECT_ROOT/user-service"
docker build -t ghcr.io/g-vishnuvardhan/product-service:latest "$PROJECT_ROOT/product-service"
docker build -t ghcr.io/g-vishnuvardhan/frontend-service:latest "$PROJECT_ROOT/frontend-service"
echo -e "${GREEN}[OK] Docker images built.${NC}"

# 4. Apply Kubernetes Manifests
echo -e "\n${YELLOW}[STEP 4/5] Deploying Manifests to Kubernetes...${NC}"
kubectl apply -f "$PROJECT_ROOT/k8s"
echo -e "${GREEN}[OK] Manifests applied.${NC}"

# 5. Check Rollout Status
echo -e "\n${YELLOW}[STEP 5/5] Verifying Pod Rollouts...${NC}"
kubectl rollout status deployment/user-service --timeout=120s
kubectl rollout status deployment/product-service --timeout=120s
kubectl rollout status deployment/frontend-service --timeout=120s

echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN} Microservices Deployed Successfully!${NC}"
echo -e "${GREEN}=======================================================${NC}"
kubectl get pods -l 'app in (user-service, product-service, frontend-service)' -o wide
kubectl get svc -l 'app in (user-service, product-service, frontend-service)' -o wide
echo -e "\n${YELLOW}Web Interface:${NC} ${CYAN}http://localhost:30080${NC}"

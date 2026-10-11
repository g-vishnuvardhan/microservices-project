#!/usr/bin/env bash
# ==============================================================================
# Automated Deployment Script for CloudMart Microservices on Kubernetes
# ==============================================================================

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}=================================================================${NC}"
echo -e "${GREEN} CloudMart: Automated Microservices Deployment Script (DevOps Lab)${NC}"
echo -e "${CYAN}=================================================================${NC}"

# 1. Pre-flight checks
echo -e "\n${YELLOW}[STEP 1/5] Checking Prerequisites (Docker & Kubernetes)...${NC}"
command -v docker >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Docker CLI not installed.${NC}"; exit 1; }
docker info >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Docker daemon is not running.${NC}"; exit 1; }
echo -e "${GREEN}[OK] Docker daemon is active.${NC}"

command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}[ERROR] kubectl CLI not installed.${NC}"; exit 1; }
kubectl cluster-info >/dev/null 2>&1 || { echo -e "${RED}[ERROR] Kubernetes cluster is unreachable.${NC}"; exit 1; }
echo -e "${GREEN}[OK] Kubernetes cluster is reachable.${NC}"

# 2. Build Docker images
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo -e "\n${YELLOW}[STEP 2/5] Building Microservice Docker Images...${NC}"
docker build -t cloudmart-product:v1 "$PROJECT_ROOT/services/product-service"
docker build -t cloudmart-order:v1 "$PROJECT_ROOT/services/order-service"
docker build -t cloudmart-frontend:v1 "$PROJECT_ROOT/services/frontend"
echo -e "${GREEN}[OK] Images built successfully.${NC}"

# 3. Apply manifests
echo -e "\n${YELLOW}[STEP 3/5] Deploying Manifests to Kubernetes...${NC}"
K8S_DIR="$PROJECT_ROOT/k8s"
kubectl apply -f "$K8S_DIR/00-namespace.yaml"
kubectl apply -f "$K8S_DIR/01-configmap-secrets.yaml"
kubectl apply -f "$K8S_DIR/02-postgres-pvc.yaml"
kubectl apply -f "$K8S_DIR/03-postgres-deployment.yaml"
kubectl apply -f "$K8S_DIR/04-product-service.yaml"
kubectl apply -f "$K8S_DIR/05-order-service.yaml"
kubectl apply -f "$K8S_DIR/06-frontend-service.yaml"
kubectl apply -f "$K8S_DIR/07-hpa.yaml"
echo -e "${GREEN}[OK] All manifests applied.${NC}"

# 4. Wait for Rollouts
echo -e "\n${YELLOW}[STEP 4/5] Waiting for Pod Rollouts & Probes...${NC}"
kubectl rollout status deployment/postgres-db -n microservices-lab --timeout=90s
kubectl rollout status deployment/product-service -n microservices-lab --timeout=90s
kubectl rollout status deployment/order-service -n microservices-lab --timeout=90s
kubectl rollout status deployment/frontend-service -n microservices-lab --timeout=90s
echo -e "${GREEN}[OK] All microservices are ready!${NC}"

# 5. Display Summary
echo -e "\n${YELLOW}[STEP 5/5] Cluster Status Summary:${NC}"
kubectl get all -n microservices-lab

echo -e "\n${GREEN}=======================================================${NC}"
echo -e "${GREEN} CloudMart Microservices Deployed Successfully!${NC}"
echo -e "${GREEN}=======================================================${NC}"
echo -e "${YELLOW} Access URL: ${CYAN}http://localhost:30080${NC}"
echo -e " Port-forward alternative: kubectl port-forward svc/frontend-service 5000:5000 -n microservices-lab"

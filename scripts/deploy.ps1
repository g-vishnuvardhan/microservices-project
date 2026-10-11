<#
.SYNOPSIS
    Automated Deployment Script for CloudMart Microservices on Kubernetes
.DESCRIPTION
    Builds container images, applies declarative manifests, verifies rollout status, 
    and validates cluster health.
#>

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "`n=======================================================" -ForegroundColor Cyan
    Write-Host "[STEP] $Message" -ForegroundColor Yellow
    Write-Host "=======================================================" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Magenta
}

Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CloudMart: Automated Microservices Deployment Script (DevOps Lab)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Pre-Flight Checks
Write-Step "Checking Prerequisites (Docker & Kubernetes)"

# Check Docker CLI
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker CLI is not installed or not in your system PATH."
}
Write-Success "Docker CLI found."

# Check if Docker daemon is running
try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw $dockerInfo
    }
    Write-Success "Docker daemon is active and running."
} catch {
    Write-Host "`n[ERROR] Docker daemon is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and ensure the engine has fully started." -ForegroundColor Yellow
    Write-Host "If using Docker Desktop on Windows, right-click the Docker tray icon and start it." -ForegroundColor Yellow
    exit 1
}

# Check Kubectl CLI
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in your system PATH."
}
Write-Success "kubectl found."

# Check Kubernetes cluster connectivity
try {
    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw $clusterInfo
    }
    Write-Success "Kubernetes cluster is reachable."
} catch {
    Write-Host "`n[ERROR] Kubernetes cluster is unreachable!" -ForegroundColor Red
    Write-Host "Please enable Kubernetes in Docker Desktop (Settings -> Kubernetes -> Enable Kubernetes)" -ForegroundColor Yellow
    Write-Host "Or start Minikube: 'minikube start'" -ForegroundColor Yellow
    exit 1
}

# 2. Build Container Images
Write-Step "Building Microservice Docker Images"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "Building Product Service image..." -ForegroundColor Cyan
docker build -t cloudmart-product:v1 "$projectRoot/services/product-service"
Write-Success "Built cloudmart-product:v1"

Write-Host "Building Order Service image..." -ForegroundColor Cyan
docker build -t cloudmart-order:v1 "$projectRoot/services/order-service"
Write-Success "Built cloudmart-order:v1"

Write-Host "Building Frontend Service image..." -ForegroundColor Cyan
docker build -t cloudmart-frontend:v1 "$projectRoot/services/frontend"
Write-Success "Built cloudmart-frontend:v1"

# 3. Apply Kubernetes Manifests
Write-Step "Deploying Manifests to Kubernetes (Namespace: microservices-lab)"

$k8sDir = Join-Path $projectRoot "k8s"

kubectl apply -f "$k8sDir/00-namespace.yaml"
kubectl apply -f "$k8sDir/01-configmap-secrets.yaml"
kubectl apply -f "$k8sDir/02-postgres-pvc.yaml"
kubectl apply -f "$k8sDir/03-postgres-deployment.yaml"
kubectl apply -f "$k8sDir/04-product-service.yaml"
kubectl apply -f "$k8sDir/05-order-service.yaml"
kubectl apply -f "$k8sDir/06-frontend-service.yaml"
kubectl apply -f "$k8sDir/07-hpa.yaml"

Write-Success "All manifests successfully submitted to Kubernetes cluster."

# 4. Wait for Rollouts
Write-Step "Monitoring Pod Rollouts (Self-Healing & Readiness Checks)"

Write-Host "Waiting for PostgreSQL database to become Ready..." -ForegroundColor Cyan
kubectl rollout status deployment/postgres-db -n microservices-lab --timeout=90s

Write-Host "Waiting for Product Service pods to become Ready..." -ForegroundColor Cyan
kubectl rollout status deployment/product-service -n microservices-lab --timeout=90s

Write-Host "Waiting for Order Service pods to become Ready..." -ForegroundColor Cyan
kubectl rollout status deployment/order-service -n microservices-lab --timeout=90s

Write-Host "Waiting for Frontend Service pods to become Ready..." -ForegroundColor Cyan
kubectl rollout status deployment/frontend-service -n microservices-lab --timeout=90s

Write-Success "All microservice deployments are healthy and running with requested replicas!"

# 5. Display Cluster Summary
Write-Step "Deployment Summary & Cluster State"
kubectl get all -n microservices-lab

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " CloudMart Microservices Deployed Successfully!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host " Access the Frontend Web Application at:" -ForegroundColor Yellow
Write-Host "   URL: http://localhost:30080" -ForegroundColor Cyan
Write-Host "`n (If NodePort 30080 is not mapped directly on your driver, run:)" -ForegroundColor DarkGray
Write-Host "   kubectl port-forward svc/frontend-service 5000:5000 -n microservices-lab" -ForegroundColor DarkGray
Write-Host "   Then open: http://localhost:5000" -ForegroundColor DarkGray
Write-Host "`n To simulate load for Auto-Scaling (HPA):" -ForegroundColor Yellow
Write-Host "   powershell -File scripts/test-traffic.ps1" -ForegroundColor Cyan
Write-Host "`n To clean up the lab cluster:" -ForegroundColor Yellow
Write-Host "   powershell -File scripts/cleanup.ps1" -ForegroundColor Cyan

# ==============================================================================
# Automated Microservices Deployment Script (PowerShell)
# ==============================================================================

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

Clear-Host
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Automated Microservices Deployment to Kubernetes (DevOps Lab)" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Pre-Flight Checks
Write-Step "Checking Prerequisites (Docker & Kubernetes)"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker CLI is not installed or not in your system PATH."
}
Write-Success "Docker CLI found."

try {
    $dockerInfo = docker info 2>&1
    if ($LASTEXITCODE -ne 0) { throw $dockerInfo }
    Write-Success "Docker daemon is active and running."
} catch {
    Write-Host "`n[ERROR] Docker daemon is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and ensure the engine has fully started." -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in your system PATH."
}
Write-Success "kubectl found."

try {
    $clusterInfo = kubectl cluster-info 2>&1
    if ($LASTEXITCODE -ne 0) { throw $clusterInfo }
    Write-Success "Kubernetes cluster is reachable."
} catch {
    Write-Host "`n[ERROR] Kubernetes cluster is unreachable!" -ForegroundColor Red
    Write-Host "Please enable Kubernetes in Docker Desktop (Settings -> Kubernetes -> Enable Kubernetes)" -ForegroundColor Yellow
    Write-Host "Or start Minikube: 'minikube start'" -ForegroundColor Yellow
    exit 1
}

# 2. Build Maven Artifacts
Write-Step "Building Spring Boot Microservices (Maven)"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir

Write-Host "Compiling User Service..." -ForegroundColor Cyan
Push-Location "$projectRoot\user-service"
try {
    .\mvnw.cmd clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "User Service Maven build failed" }
    Write-Success "User Service package created successfully."
} finally {
    Pop-Location
}

Write-Host "Compiling Product Service..." -ForegroundColor Cyan
Push-Location "$projectRoot\product-service"
try {
    .\mvnw.cmd clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { throw "Product Service Maven build failed" }
    Write-Success "Product Service package created successfully."
} finally {
    Pop-Location
}

# 3. Build Docker Images
Write-Step "Building Container Images"

Write-Host "Building user-service image..." -ForegroundColor Cyan
docker build -t ghcr.io/g-vishnuvardhan/user-service:latest "$projectRoot\user-service"
Write-Success "Built user-service image."

Write-Host "Building product-service image..." -ForegroundColor Cyan
docker build -t ghcr.io/g-vishnuvardhan/product-service:latest "$projectRoot\product-service"
Write-Success "Built product-service image."

Write-Host "Building frontend-service image..." -ForegroundColor Cyan
docker build -t ghcr.io/g-vishnuvardhan/frontend-service:latest "$projectRoot\frontend-service"
Write-Success "Built frontend-service image."

# 4. Apply Kubernetes Manifests
Write-Step "Deploying Manifests to Kubernetes Cluster"
kubectl apply -f "$projectRoot\k8s"
Write-Success "All manifests applied to cluster."

# 5. Check Rollout Status
Write-Step "Verifying Pod Rollouts & Health Probes"
Write-Host "Waiting for user-service rollout..." -ForegroundColor Cyan
kubectl rollout status deployment/user-service --timeout=120s

Write-Host "Waiting for product-service rollout..." -ForegroundColor Cyan
kubectl rollout status deployment/product-service --timeout=120s

Write-Host "Waiting for frontend-service rollout..." -ForegroundColor Cyan
kubectl rollout status deployment/frontend-service --timeout=120s

Write-Success "All microservices are ready and passing probes!"

# 6. Display Cluster Summary
Write-Step "Cluster State Summary"
kubectl get pods -l 'app in (user-service, product-service, frontend-service)' -o wide
kubectl get svc -l 'app in (user-service, product-service, frontend-service)' -o wide
kubectl get hpa

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " Microservices Deployed Successfully!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host " Web Interface: http://localhost:30080" -ForegroundColor Cyan
Write-Host " Port-forward alternative: kubectl port-forward svc/frontend-service 8080:80" -ForegroundColor DarkGray

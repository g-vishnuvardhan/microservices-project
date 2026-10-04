# Automated Microservices Deployment Script (PowerShell)
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host " Automated Microservices Deployment to Kubernetes   " -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# 1. Build Maven artifacts
Write-Host "`n[1/4] Building Maven artifacts..." -ForegroundColor Yellow
cd user-service
.\mvnw.cmd clean package -DskipTests
if ($LASTEXITCODE -ne 0) { Write-Error "User Service Maven build failed"; exit 1 }

cd ..\product-service
.\mvnw.cmd clean package -DskipTests
if ($LASTEXITCODE -ne 0) { Write-Error "Product Service Maven build failed"; exit 1 }
cd ..

# 2. Build Docker images
Write-Host "`n[2/4] Building Docker images..." -ForegroundColor Yellow
docker build -t ghcr.io/g-vishnuvardhan/user-service:latest ./user-service
docker build -t ghcr.io/g-vishnuvardhan/product-service:latest ./product-service

# 3. Apply Kubernetes Manifests
Write-Host "`n[3/4] Deploying to Kubernetes cluster..." -ForegroundColor Yellow
kubectl apply -f k8s/

# 4. Check Rollout Status
Write-Host "`n[4/4] Verifying rollout status..." -ForegroundColor Yellow
kubectl rollout status deployment/user-service --timeout=120s
kubectl rollout status deployment/product-service --timeout=120s

Write-Host "`n Deployment complete! Current Pods:" -ForegroundColor Green
kubectl get pods -l 'app in (user-service, product-service)'
kubectl get svc -l 'app in (user-service, product-service)'

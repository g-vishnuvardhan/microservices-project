#!/usr/bin/env bash
set -e

echo "====================================================="
echo " Automated Microservices Deployment to Kubernetes   "
echo "====================================================="

# 1. Build Maven artifacts
echo -e "\n[1/4] Building Maven artifacts..."
cd user-service
chmod +x ./mvnw
./mvnw clean package -DskipTests
cd ../product-service
chmod +x ./mvnw
./mvnw clean package -DskipTests
cd ..

# 2. Build Docker images
echo -e "\n[2/4] Building Docker images..."
docker build -t ghcr.io/g-vishnuvardhan/user-service:latest ./user-service
docker build -t ghcr.io/g-vishnuvardhan/product-service:latest ./product-service

# 3. Apply Kubernetes Manifests
echo -e "\n[3/4] Deploying to Kubernetes cluster..."
kubectl apply -f k8s/

# 4. Check Rollout Status
echo -e "\n[4/4] Verifying rollout status..."
kubectl rollout status deployment/user-service --timeout=120s
kubectl rollout status deployment/product-service --timeout=120s

echo -e "\nDeployment complete! Current Pods:"
kubectl get pods -l 'app in (user-service, product-service)'
kubectl get svc -l 'app in (user-service, product-service)'

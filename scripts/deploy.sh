#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-kubernetes}"
password="${DB_PASSWORD:-cloudmart-lab-change-me}"
docker info --format '{{.ServerVersion}}'
if [[ "$mode" == compose ]]; then
  [[ -f .env ]] || printf 'DB_PASSWORD=%s\n' "$password" > .env
  docker compose up -d --build --wait --wait-timeout 240
  curl --fail --silent http://localhost:5000/api/inspector
  printf '\nOpen http://localhost:5000\n'
  exit 0
fi
[[ "$mode" == kubernetes ]] || { echo 'Usage: bash scripts/deploy.sh [compose|kubernetes]'; exit 1; }
context=$(kubectl config current-context)
case "$context" in docker-desktop|minikube|kind-*) ;; *) echo "Select a local Docker Desktop, Minikube or Kind context. Current: $context";exit 1;; esac
kubectl cluster-info
for pair in frontend:frontend product-service:product order-service:order; do
  service=${pair%%:*}; image="cloudmart-${pair##*:}:v1"
  docker build -t "$image" "services/$service"
  if [[ "$context" == kind-* ]];then kind load docker-image "$image" --name "${context#kind-}";fi
  if [[ "$context" == minikube ]];then minikube image load "$image";fi
done
kubectl apply -f k8s/00-namespace.yaml
kubectl create secret generic cloudmart-secret -n microservices-lab --from-literal="DB_PASSWORD=$password" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl apply -k k8s
for name in product-service order-service frontend-service;do kubectl rollout restart "deployment/$name" -n microservices-lab;done
for name in postgres-db product-service order-service frontend-service;do kubectl rollout status "deployment/$name" -n microservices-lab --timeout=240s;done
kubectl get pods,svc,pvc,hpa -n microservices-lab
url=http://localhost:30080
if [[ "$context" == minikube ]];then url=$(minikube service frontend-service -n microservices-lab --url | head -n 1);fi
if [[ "$context" == kind-* ]];then
  echo 'In another terminal: kubectl port-forward -n microservices-lab svc/frontend-service 5000:80'
else curl --fail --silent "$url/api/inspector";printf '\nOpen %s\n' "$url";fi

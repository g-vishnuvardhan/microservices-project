#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Tearing down microservices Kubernetes resources..."
kubectl delete -f "$PROJECT_ROOT/k8s" --ignore-not-found
echo "Teardown complete. All pods, services, and HPAs cleaned up."

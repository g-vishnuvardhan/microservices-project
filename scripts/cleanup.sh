#!/usr/bin/env bash
set -e

echo "Tearing down microservices-lab Kubernetes resources..."
kubectl delete namespace microservices-lab --timeout=60s
echo "Teardown complete. All pods, services, and volumes cleaned up."

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode=${1:-kubernetes}; delete_data=${2:-keep-data}
[[ "$delete_data" == keep-data || "$delete_data" == --delete-data ]] || { echo 'Second argument: keep-data or --delete-data';exit 1; }
if [[ "$mode" == compose ]];then
  if [[ "$delete_data" == --delete-data ]];then docker compose down --volumes;else docker compose down;fi
elif [[ "$mode" == kubernetes ]];then
  if [[ "$delete_data" == --delete-data ]];then kubectl delete namespace microservices-lab --ignore-not-found;else kubectl delete deployment,service,hpa --all -n microservices-lab;echo 'PVC and credentials retained.';fi
else echo 'Usage: bash scripts/cleanup.sh [compose|kubernetes] [keep-data|--delete-data]';exit 1;fi

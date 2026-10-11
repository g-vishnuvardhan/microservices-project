# College demonstration guide

**Presenter: K. Rishi · Roll No: 24H51A05T6**

## Before the presentation

1. Copy the project to the college computer. Connect to the internet for the first image build or Python dependency installation. Fonts have local fallbacks, so the UI remains readable offline.
2. Start Docker Desktop. Run `docker info`. For the full orchestration demonstration, also enable Kubernetes and run `kubectl cluster-info`.
3. Run the appropriate deployment script from README. Check all services before class. Initial downloads and cluster startup can take several minutes.
4. Prepare two windows: browser and terminal. Increase terminal font size. Use a browser zoom level at which all controls remain readable.
5. Keep the README and this guide available. Avoid resetting the database before recording evidence.

## Recommended 7-minute script

| Time | Action | What to explain |
|---|---|---|
| 0:00–0:45 | Show the catalog | “CloudMart divides a storefront into frontend, catalog and order services. PostgreSQL stores completed orders.” |
| 0:45–2:00 | Filter Books, clear the filter, add headphones and handbook, adjust quantity | “The browser keeps the cart. Checkout sends product IDs and quantities, not trusted prices.” |
| 2:00–2:45 | Place order and open Order history | “The order API checks the catalog and calculates the bill. It writes the order to the database.” |
| 2:45–3:45 | Open Live inspector and refresh | “These are real responding hosts and readiness checks. The latency is measured from the frontend to the backend.” |
| 3:45–5:00 | Show Kubernetes pods and delete one frontend pod | “The Deployment maintains two replicas and creates a replacement when a pod disappears.” |
| 5:00–6:15 | Show PVC and restart database | “Database files live on persistent storage, so a pod restart does not erase the order.” |
| 6:15–7:00 | Show HPA and summarize | “Autoscaling reacts to measured CPU utilization. It depends on Metrics Server and sufficient sustained load.” |

## Exact Kubernetes demonstration commands

Use only the isolated `microservices-lab` namespace created for this lab. Keep a separate terminal watching changes:

```powershell
kubectl get pods -n microservices-lab -w
```

In the first terminal:

```powershell
kubectl get pods,svc,pvc,hpa -n microservices-lab
$demoPod = kubectl get pods -n microservices-lab -l app=frontend-service -o jsonpath='{.items[0].metadata.name}'
kubectl delete pod $demoPod -n microservices-lab
kubectl rollout status deployment/frontend-service -n microservices-lab --timeout=120s
```

Refresh the browser and compare the replacement pod's name with the old one. Do not promise strict hostname alternation or round-robin routing. Connection reuse and Kubernetes networking may send consecutive requests to the same pod.

### Persistence

Place an order first and note its ID. The following action causes temporary database unavailability in this single-database lab:

```powershell
kubectl get pvc -n microservices-lab
kubectl rollout restart deployment/postgres-db -n microservices-lab
kubectl rollout status deployment/postgres-db -n microservices-lab --timeout=120s
```

Wait for backend readiness, then refresh Order history. The same order should remain. Explain that persistence and database high availability are different properties. One PostgreSQL pod is not a highly available database.

### Autoscaling

First verify that metrics work:

```powershell
kubectl top pods -n microservices-lab
kubectl get hpa -n microservices-lab
```

If CPU shows `<unknown>` or `top` fails, use a cluster with Metrics Server already installed. Minikube users can enable its official metrics addon with `minikube addons enable metrics-server`. Do not disable certificate verification as a shortcut.

In one terminal:

```powershell
kubectl get hpa -n microservices-lab -w
```

In PowerShell 7 (`pwsh`), run:

```powershell
./scripts/test-traffic.ps1 -BaseUrl http://localhost:30080 -Seconds 90 -Concurrency 12
```

Use port 5000 when port-forwarding. The bounded `/api/demo/load` request performs CPU work in the order service. HPA observes aggregate CPU over time. It may take several measurement cycles to scale, and it may not scale the lightly loaded frontend. Never claim that one request triggers scaling. A port-forward to one pod also distributes load differently from NodePort access.

## Docker Compose alternative

```powershell
docker compose ps
docker compose restart order-service
docker compose logs --tail 30 order-service
```

Refresh Order history and demonstrate persistence. Compose does not provide Kubernetes pods, HPA or Deployment reconciliation. Explain those concepts using the manifests if a cluster is unavailable.

## No Docker on the college computer

Use the README's local Python mode. It runs real frontend, product and order services with SQLite. Say: “This mode demonstrates the application and persistence. It does not demonstrate Docker or Kubernetes.” The Live inspector explicitly shows local mode and SQLite. Show the configuration files as implementation evidence, not as proof that a cluster is running.

## Troubleshooting during the demo

- Empty catalog: retry, check `product-service` readiness and service logs.
- Checkout fails: keep the bag and retry. The same request key avoids a duplicate order.
- Local port 5000 occupied: stop another local demo before starting Compose or port-forwarding.
- Database unavailable: wait for `/readyz`, verify the password and PVC, then retry.
- NodePort unavailable: use the documented service port-forward. Minikube and Kind networking differ from Docker Desktop.

## A concise viva introduction

“My project is CloudMart, an automated microservices deployment lab. The frontend presents products and checkout. The product API supplies catalog data. The order API verifies quantities and prices, then saves orders. Docker packages each service. Kubernetes controls replicas, readiness, recovery and scaling. Persistent storage protects order data across database pod restarts.”

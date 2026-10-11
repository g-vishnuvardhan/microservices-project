# College demonstration guide

**Presenter: K. Rishi · Roll No: 24H51A05T6**

## Local Kubernetes session (12 October 2026)

CloudMart is deployed on the single-node `kind-cloudmart` context (Kubernetes
1.36.1), inside Docker Desktop. Open **http://localhost:30080** for Kubernetes;
port 5000 still serves the separate Compose stack. The two stacks have separate
PostgreSQL data volumes and order histories.

Metrics Server 0.9.0 is installed. Kubelet serving certificate bootstrap is
enabled, the node's serving CSR was checked against its identity and internal
IP before approval, and Metrics Server trusts the cluster CA using
`--kubelet-certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`.
TLS verification remains enabled. Future serving-certificate renewals also need
verified CSR approval in this local Kind setup.

Run these commands in PowerShell from the checkout:

```powershell
Set-Location E:\sir\microservices-project
kubectl config use-context kind-cloudmart
kubectl get pods,svc,pvc,hpa -n microservices-lab
kubectl top pods -n microservices-lab
```

For self-healing, watch pods in one terminal (`Ctrl+C` stops the watch):

```powershell
kubectl get pods -n microservices-lab -l app=frontend-service -w
```

In another terminal, delete one frontend pod and wait for readiness:

```powershell
$demoPod = kubectl get pods -n microservices-lab -l app=frontend-service -o jsonpath='{.items[0].metadata.name}'
kubectl delete pod $demoPod -n microservices-lab
kubectl wait --for=condition=Ready pod -l app=frontend-service -n microservices-lab --timeout=120s
kubectl get pods -n microservices-lab -l app=frontend-service
Invoke-RestMethod http://127.0.0.1:30080/healthz
```

Expected: the old pod disappears, a new pod name becomes `1/1 Running`, and two
frontend replicas are available. The recorded test replaced a pod in 10.7
seconds; all 39 sampled HTTP health requests returned 200.

For autoscaling, watch HPA in one terminal:

```powershell
kubectl get hpa -n microservices-lab -w
```

In PowerShell 7 in another terminal:

```powershell
.\scripts\test-traffic.ps1 -BaseUrl http://127.0.0.1:30080 -Seconds 120 -Concurrency 16
kubectl get deployments -n microservices-lab
kubectl top pods -n microservices-lab
kubectl describe hpa order-service -n microservices-lab
```

Expected: sustained order-service CPU above the 50% target increases its replica
count from 2 toward the maximum of 5. The frontend may remain at 2 because the
CPU work runs in the order service. The traffic stops automatically; allow the
120-second scale-down stabilization window plus metric/controller delays before
expecting 2 replicas again. These commands demonstrate pod scaling on one local
node, not node autoscaling or recovery from a whole-node failure.

The recorded 120-second, 16-worker test completed 2,315 successful requests with
zero failures. Kubernetes HPA events confirmed order replicas increased from
2 to 4 to 5, and frontend replicas increased from 2 to 3. Both deployments had
all requested replicas ready. HPA CPU percentages are relative to the 50m CPU
request per pod; utilization above 100% is valid and does not mean the whole
machine's CPU was exhausted.

After traffic stopped, both services automatically returned to 2 replicas in
approximately 2.5 minutes, including the stabilization window and controller
delays. The final application health check passed.

References: [Kind configuration](https://kind.sigs.k8s.io/docs/user/configuration/),
[Metrics Server](https://github.com/kubernetes-sigs/metrics-server), and
[Kubernetes HPA behavior](https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/).

`scripts/kind-config.yaml` preserves the cluster's loopback NodePort mapping and
kubelet serving-certificate bootstrap setting. Kind 0.33.0 is installed at
`$env:LOCALAPPDATA\CloudMart\tools\kind.exe`. When rebuilding local images, Docker
Desktop's image store may require exporting only the node platform before loading:

```powershell
$archive = Join-Path $env:TEMP 'cloudmart-images-amd64.tar'
docker image save --platform linux/amd64 -o $archive cloudmart-frontend:v1 cloudmart-product:v1 cloudmart-order:v1 postgres:16-alpine
& "$env:LOCALAPPDATA\CloudMart\tools\kind.exe" load image-archive $archive --name cloudmart
```

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

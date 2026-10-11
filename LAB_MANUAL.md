# Lab manual

## Experiment title

Automated Microservices Deployment Using Docker and Kubernetes

**Name:** K. Rishi
**Roll No:** 24H51A05T6

## Aim

Implement a storefront as independent services, package it in Docker images, deploy it with Compose and Kubernetes, and observe readiness, recovery, persistence and CPU-based scaling.

## Learning outcomes

After completing this experiment, students should be able to explain service decomposition, image/container differences, Kubernetes desired state, service discovery, probes, persistent storage and deployment automation.

## Requirements

| Requirement | Purpose |
|---|---|
| Docker Desktop with Linux containers | Image builds and Compose |
| Docker Desktop Kubernetes, Minikube or Kind | Local orchestration |
| kubectl | Cluster inspection and deployment |
| PowerShell 7 for parallel load script | Windows load demonstration |
| Python 3.11+ | Local mode and tests |
| Internet during initial setup | Download images and dependencies |
| Default dynamic StorageClass | Bind the 1 Gi PVC |
| Metrics Server, for HPA demonstration | Supply CPU metrics |

Allocate enough memory for the local cluster. A laptop with 8 GiB or more is a practical starting point, not a universal guarantee. Close unnecessary workloads if scheduling or memory limits fail.

## Theory

Microservices separate responsibilities behind network APIs. The frontend routes same-origin browser requests to the product and order APIs. The order service uses the product service as the authority for catalog prices. A Decimal bill avoids binary floating-point money arithmetic. PostgreSQL stores each order's item snapshots, amount, timestamp and request key.

Docker builds immutable image layers and runs processes inside containers. Application containers use a non-root UID. Compose connects the four services through `app-network` and waits for dependency health checks during startup.

Kubernetes Deployments manage replaceable application pods. Services provide stable names and select pods by labels. The namespace groups this lab's objects. ConfigMaps hold non-secret settings; a Secret supplies the database password. A PVC requests storage independently of a database pod. Readiness controls traffic eligibility, while liveness determines when an unhealthy container needs a restart. Startup probes allow slow initialization.

The supplied database uses one Deployment with the Recreate strategy and one PVC. It intentionally favors simplicity over database high availability. Production database orchestration generally needs more deliberate stateful operations and backup planning.

## Procedure A: Docker Compose

From the project root:

```powershell
docker info
Copy-Item .env.example .env
# Set your lab password in .env before initializing PostgreSQL.
docker compose config --quiet
docker compose up -d --build --wait --wait-timeout 240
docker compose ps
```

Open http://localhost:5000. Search products, add items, change quantity and place an order. Show the total and Order history. Record the returned order ID.

```powershell
Invoke-RestMethod http://localhost:5000/api/products
Invoke-RestMethod http://localhost:5000/api/inspector
docker compose restart order-service
```

Wait for readiness and refresh history. The order remains in PostgreSQL. Stop the stack with `docker compose down`. Do not add `--volumes` unless you intend to erase the lab database.

## Procedure B: Kubernetes

```powershell
kubectl config use-context docker-desktop
kubectl cluster-info
./scripts/deploy.ps1 -DbPassword 'your-local-lab-password'
kubectl get pods,svc,pvc,hpa -n microservices-lab
```

The script checks the daemon and API, builds images, loads them for Kind/Minikube when needed, creates the namespace and Secret, applies Kustomize resources, restarts application deployments after a local image rebuild, and waits for rollout. Native command failures stop execution.

Frontend service uses NodePort 30080. If it is not reachable, use:

```powershell
kubectl port-forward -n microservices-lab svc/frontend-service 5000:80
```

Open http://localhost:5000 while the port-forward terminal stays running. Minikube users can use `minikube service frontend-service -n microservices-lab`. Kind normally needs port-forwarding unless its node container has a suitable port mapping.

Manual equivalent for a local cluster whose images are already built and available:

```powershell
kubectl apply -f k8s/00-namespace.yaml
kubectl create secret generic cloudmart-secret -n microservices-lab --from-literal=DB_PASSWORD=your-local-lab-password
kubectl apply -k k8s
```

Do not commit real passwords. `01-secret.example.yaml.txt` is an explanatory sample, not an automatically applied credential file. Kubernetes stores Secret data using base64 representation; this representation does not encrypt it.

## Procedure C: Recovery and storage

Use the exact commands in DEMO_GUIDE.md. Observe a deleted frontend pod getting a replacement, then restart the database Deployment and compare the same order ID before and after. Never delete the PVC as part of a persistence demonstration.

## Procedure D: Autoscaling

```powershell
kubectl top pods -n microservices-lab
kubectl get hpa -n microservices-lab -w
# Another PowerShell 7 terminal:
./scripts/test-traffic.ps1 -Seconds 90 -Concurrency 12
```

The policies request 2–5 replicas for frontend and order services at a 50% CPU utilization target. CPU utilization is relative to requested CPU. There is a 120-second scale-down stabilization window. A cluster without Metrics Server cannot demonstrate this policy operating. Record real observed metrics, rather than assuming replicas increase.

## API contract

| Endpoint | Method | Result |
|---|---|---|
| `/api/products` | GET | Catalog list |
| `/api/products/<id>` | GET | Product or 404 |
| `/api/orders` | POST | Validated, stored order |
| `/api/orders` | GET | Latest 100 shared orders |
| `/api/inspector` | GET, frontend | Backend readiness, hosts and latency |
| `/healthz` | GET | Process-level health |
| `/readyz` | GET | Readiness; order service checks database |
| `/api/demo/load` | POST | Optional bounded lab CPU load |

Checkout example:

```powershell
$requestKey = [guid]::NewGuid().ToString()
$body = @{items=@(@{product_id=1;quantity=2})} | ConvertTo-Json -Depth 4
Invoke-RestMethod -Method Post -Uri http://localhost:5000/api/orders -ContentType application/json -Headers @{'Idempotency-Key'=$requestKey} -Body $body
```

Repeat using the same key and body. The same order ID returns. Change the cart under the same key and expect HTTP 409. Invalid quantities return 400. Dependency/storage outages return 503 instead of a fake success.

## Expected observations

These are expected outcomes to verify in the college lab, not fabricated execution logs:

- Compose services become healthy and the catalog contains six products.
- Two headphones produce a ₹4,998.00 total.
- Kubernetes initially requests two replicas for each application service and one database pod.
- PVC should show Bound when a compatible default StorageClass exists.
- Pod deletion changes the pod identity while the Deployment restores its desired count.
- The order remains after an order-service or database pod restart with the same storage.
- HPA reports real CPU metrics only when the metrics API is working.

## Troubleshooting

| Symptom | Investigation and remedy |
|---|---|
| Docker pipe/daemon unavailable | Open Docker Desktop and wait for `docker info` to succeed. |
| API connection refused | Check the selected context and local Kubernetes startup. |
| ImagePullBackOff | Confirm image tag, `IfNotPresent`, and image loading into the selected cluster. |
| CrashLoopBackOff | `kubectl logs` and `kubectl describe pod`; inspect configuration and previous logs. |
| PVC Pending | Inspect StorageClass, PVC events and available capacity. |
| Readiness fails | Verify PostgreSQL startup, database password and service DNS. |
| OOMKilled | Inspect memory use and resource limits; adjust based on measured need. |
| HPA `<unknown>` | Verify Metrics Server and `kubectl top pods`; confirm CPU requests exist. |
| NodePort unreachable | Use the provider-specific URL or service port-forward. |
| Password changed but login fails | The persisted PostgreSQL user retains its original password; use it or explicitly rotate the database credential. |
| Ports already in use | Stop the local demo before using Compose or port-forward on port 5000. |

## Result and submission evidence

Complete the experiment by saving screenshots of catalog, successful order, history, service inspector, pods, Bound PVC and any observed HPA change. Include real terminal output and a note about the deployment mode. Current development verification is recorded separately in VERIFICATION.md.

## References

- https://docs.docker.com/compose/how-tos/startup-order/
- https://kubernetes.io/docs/concepts/services-networking/service/
- https://kubernetes.io/docs/concepts/workloads/pods/probes/
- https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- https://kubernetes.io/docs/concepts/configuration/secret/
- https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/

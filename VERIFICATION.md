# Development verification

## Kubernetes runtime verification — 12 October 2026

These results supersede the infrastructure availability limitations recorded
below for 11 October. Tested on a local single-node Kind cluster inside Docker
Desktop; this does not verify an external or production cluster.

| Check | Result |
|---|---|
| Docker Compose runtime | Four healthy containers; PostgreSQL checkout smoke test passed |
| Kubernetes cluster | Kind 0.33.0, Kubernetes 1.36.1; context `kind-cloudmart`, node Ready |
| App image import | Linux AMD64 archive imported into Kind; all three app images and PostgreSQL present |
| Kubernetes rollout | Frontend, catalog, order and PostgreSQL deployments ready |
| Kubernetes persistent storage | `db-data-pvc` Bound, 1 Gi, local `standard` StorageClass |
| Kubernetes application smoke test | Passed catalog, checkout, server pricing, retry, history and invalid-cart rejection at port 30080 |
| Metrics Server | 0.9.0; `kubectl top` works; verified cluster-signed kubelet serving certificate with CA trust, no insecure TLS flag |
| Self-healing | Deleted frontend pod replaced by a new ready pod in 10.7 seconds; 39/39 sampled health requests returned HTTP 200 |
| Autoscaling under load | 120 seconds, 16 workers, 2,315 successful requests, zero failures; order service 2 → 4 → 5, frontend 2 → 3 |
| Automatic scale-down | Both HPAs returned to 2 current/desired replicas approximately 2.5 minutes after load stopped |
| Kubernetes browser access | `http://localhost:30080`, loopback-mapped NodePort; Compose remains on port 5000 |

The local deployment has its own PostgreSQL PVC; Compose orders are stored in a
separate Docker volume. Repeatable test commands and cluster notes are in
`DEMO_GUIDE.md`. GitHub Actions execution remains unverified.

## Original development checks — 11 October 2026

Recorded for the implementation delivered on 11 October 2026.

| Check | Result |
|---|---|
| Backend automated tests | 14 passed |
| CI Python lint rules | Passed Ruff E9/F63/F7/F82 checks |
| PowerShell automation | Parsed successfully; native argument forwarding checked |
| Manifest selectors and ports | Validated matching deployments, services and HPA references |
| Responsive UI | Desktop and 390 px mobile layout checked, including theme toggle |
| Frontend JavaScript syntax | Passed Node syntax check |
| Live application smoke test | Passed on local three-service SQLite mode |
| Browser checkout | Two products, ₹3,198.00 total, successful saved order |
| Browser order history | Saved order visible |
| Browser category filtering | Books category shows two matching products |
| Compose configuration | `docker compose config --quiet` passed |
| Kubernetes manifest rendering | `kubectl kustomize k8s` passed |
| Docker engine | Unavailable; named engine pipe not found |
| Kubernetes API | Unavailable; selected local endpoint refused connection |
| Docker image build / PostgreSQL runtime | Not verified on this machine |
| Kubernetes rollout / PVC binding / self-healing / HPA | Not verified on this machine |
| GitHub Actions | Definition supplied; no GitHub execution performed |
| GitHub repository | Source prepared for the user-authorized Git push; deployment remains separate |

Screenshots in `screenshots/` show the real local application. They are application evidence, not Kubernetes execution evidence.

The deployment scripts and CI definition supply the remaining runtime checks for a working local Docker/Kubernetes environment. Complete those before claiming an infrastructure demonstration succeeded.

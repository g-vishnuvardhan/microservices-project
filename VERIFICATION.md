# Development verification

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

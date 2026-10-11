# Automated Microservices Deployment Using Docker and Kubernetes

**Application:** CloudMart
**Name:** K. Rishi
**Roll No:** 24H51A05T6
**Department:** ____________________
**Institution:** ____________________
**Guide:** ____________________
**Academic year:** ____________________

## Abstract

CloudMart is a college cloud computing lab application that separates an online storefront into independently runnable frontend, product and order services. Docker packages the applications and PostgreSQL database. Docker Compose supports local multi-container deployment. Kubernetes manifests describe replica management, health probes, service discovery, persistent storage and CPU-based autoscaling. Automated scripts build images, apply configurations and verify rollouts. A modern responsive interface lets the presenter demonstrate catalog browsing, checkout, order history and actual service health. An explicitly labelled local SQLite mode provides an application fallback when container infrastructure is unavailable.

## 1. Problem statement

A single application process hides the operational problems of distributed systems. Students need a concrete example in which services communicate over the network, data survives process replacement and orchestration restores desired state. Manual deployment also makes demonstrations inconsistent. The project addresses these needs through a small, repeatable application and declarative infrastructure.

## 2. Objectives

- Separate application responsibilities behind REST APIs.
- Build reproducible multi-stage Docker images and run application processes as a non-root user.
- Coordinate services with Compose health dependencies and internal networking.
- Describe Kubernetes storage, deployments, configuration, services and HPA.
- Automate deployment, stop on failures and inspect readiness.
- Support a clear college demonstration with documented limitations and troubleshooting.

## 3. Existing system and proposed system

The supplied GitHub repository contains a Spring Boot user/product API showcase. That implementation is preserved in `legacy/`. The active proposed system follows the supplied CloudMart plan: Flask frontend, product catalog, order processing and PostgreSQL persistence. New UI and infrastructure live outside the legacy implementation to avoid mixing incompatible service definitions.

## 4. Architecture and responsibilities

The browser calls only the frontend. The frontend serves the UI and forwards approved API paths to the internal services. Product service owns the seeded catalog. Order service fetches catalog values, validates IDs and quantities, calculates the bill using Decimal and writes an order snapshot. PostgreSQL stores the result. The frontend's inspector makes readiness requests to both backend services and measures response latency.

An order contains a UUID, creation time, total, serialized item snapshots, request key and normalized cart fingerprint. A unique request key prevents repeated submissions from creating duplicates. Reusing a key for a different cart returns a conflict. Clients cannot determine the accepted price by editing browser data.

## 5. Technologies and implementation

| Layer | Technology | Implementation choice |
|---|---|---|
| Interface | HTML, CSS, JavaScript | Responsive layout, accessible controls, light/dark themes |
| Application | Python 3.11, Flask | Separate REST services and gateway |
| Container HTTP runtime | Gunicorn | Two workers and two threads per application image |
| Storage | PostgreSQL 16 Alpine | Persistent order records |
| Local fallback | SQLite | Explicitly identified demo mode |
| Packaging | Docker multi-stage builds | Build wheels separately from runtime image |
| Local coordination | Docker Compose | Health-aware dependencies and named data volume |
| Orchestration | Kubernetes, Kustomize | Declarative objects in an isolated namespace |
| Automation | PowerShell, Bash | Preflight checks, image loading, rollout verification |
| CI | GitHub Actions | Tests, Compose smoke test and disposable Kind rehearsal |

Application images use UID 10001. Kubernetes drops container capabilities and disables automatic service account token mounting. ConfigMap settings include service URLs and deployment mode. The database password enters through a Secret. The repository includes an explanatory sample rather than a committed live secret.

Application Deployments start with two replicas and allow a rolling update to add one pod without intentionally removing an available pod first. This policy supports availability but cannot guarantee it when resource capacity, dependency failures or readiness are inadequate. PostgreSQL runs as a single replica with Recreate to avoid overlapping database processes on the same data volume.

## 6. User experience

The storefront separates shopping from infrastructure inspection. Search and categories narrow the catalog. The bag remains visible on desktop and stacks below products on smaller screens. Product illustrations use a consistent pastel style. Loading, empty, service-error and checkout-success states guide the user. Cart contents survive a browser refresh using local storage. A failed checkout retains the bag and request key for a safe retry.

The UI draws inspiration from Dribbble's e-commerce dashboard patterns and the accessible Collect UI gallery. Original layout, CSS and illustrations were implemented for this project. Specific references appear in DESIGN_REFERENCES.md.

## 7. Deployment and automation

Compose mode builds all applications, starts PostgreSQL, waits for readiness and publishes only the frontend on loopback port 5000. Its named volume retains data after normal shutdown.

Kubernetes mode checks the local Docker daemon and Kubernetes API, builds application images and loads them into Kind or Minikube when required. It creates the namespace and Secret, applies Kustomize definitions, triggers application rollout after local rebuilds and waits for each Deployment. The frontend service exposes NodePort 30080. Service port-forwarding provides a portable alternative.

HPA definitions target frontend and order services with a 2–5 replica range and 50% CPU utilization target. CPU requests establish the utilization denominator. Scaling requires the resource metrics API and sufficient measured load. The traffic script sends bounded CPU demonstration requests, then the presenter watches real HPA status.

## 8. Test strategy and observed results

| Test | Expected behavior | Development verification |
|---|---|---|
| Browse/filter/search | Correct matching products | Browser checked |
| Add products and checkout | Stored order and correct bill | Browser and live smoke test passed |
| Price tampering | Server uses catalog price | Automated test passed |
| Retry same checkout | Same order ID, one stored order | Automated test and smoke test passed |
| Reuse key for changed cart | HTTP 409 | Automated test passed |
| Invalid quantity/product | HTTP 400, no order | Automated tests passed |
| Product outage | HTTP 503, no fake success | Automated test passed |
| Service reinitialization | Existing local orders remain | SQLite persistence test passed |
| Gateway outage reporting | Explicit unavailable status | Automated test passed |
| Compose definition | Valid configuration | Configuration check passed |
| Kustomize definition | Successful manifest rendering | Rendering check passed |
| Live PostgreSQL and container builds | Healthy deployed stack | Not verified: local Docker engine unavailable |
| Kubernetes replacement/PVC/HPA | Observable cluster behavior | Not verified: local Kubernetes API unavailable |

Fourteen backend tests passed during development. The local frontend and APIs were exercised with real HTTP calls using the clearly labelled SQLite fallback. The CI workflow is supplied but has not been executed on GitHub. Update this report with the college machine's actual deployment results and screenshots after performing the lab.

## 9. Limitations

This project is an educational system. It does not authenticate shoppers, process payments or reserve/decrement inventory transactionally. Order history is shared and limited to the latest 100 results. Catalog values are seeded in memory. A single PostgreSQL instance persists data but does not provide database failover. The UI inspector reports service responses, not Kubernetes control-plane objects. Secrets require cluster access controls and proper encryption configuration; base64 alone does not protect credentials.

No permanent remote deployment or image publishing is configured. CI only rehearses deployment in a disposable Kind environment. HPA behavior must be observed on a metrics-enabled cluster.

## 10. Future scope

Add user authorization, transactional inventory updates, database migrations, payment sandbox integration, request tracing, centralized metrics and backups. Use a managed PostgreSQL service or appropriate database operator for production availability. Configure image publishing and controlled deployment environments when permanent delivery is required.

## 11. Conclusion

CloudMart provides a working application for explaining how independent services communicate and how container tooling packages and coordinates them. Its scripts and manifests support a repeatable Docker/Kubernetes lab, while its documentation separates verified application behavior from infrastructure demonstrations that still require a running local cluster.

## References

- Original repository: https://github.com/g-vishnuvardhan/microservices-project
- Docker Compose startup order: https://docs.docker.com/compose/how-tos/startup-order/
- Kubernetes Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Probes: https://kubernetes.io/docs/concepts/workloads/pods/probes/
- Persistent volumes: https://kubernetes.io/docs/concepts/storage/persistent-volumes/
- Secrets: https://kubernetes.io/docs/concepts/configuration/secret/
- HPA: https://kubernetes.io/docs/concepts/workloads/autoscaling/horizontal-pod-autoscale/

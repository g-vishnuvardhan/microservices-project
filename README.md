# 🚀 CloudMart: Automated Microservices Deployment on Docker & Kubernetes

[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.28+-326ce5.svg?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-v24+-2496ed.svg?logo=docker&logoColor=white)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.11-3776ab.svg?logo=python&logoColor=white)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169e1.svg?logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)]()

> **University Lab Project / Academic Portfolio:** A production-grade distributed microservices application engineered to demonstrate containerization, declarative cluster orchestration, fault tolerance, persistent storage, and deployment automation.

---

## 📑 Table of Contents
- [Architecture Overview](#-architecture-overview)
- [Microservices Catalog](#-microservices-catalog)
- [Academic Deliverables](#-academic-deliverables)
- [Project Directory Layout](#-project-directory-layout)
- [Prerequisites](#-prerequisites)
- [Quick Start: 1-Click Automated Deployment](#-quick-start-1-click-automated-deployment)
  - [Option A: Kubernetes Automated Deployment](#option-a-kubernetes-automated-deployment-recommended)
  - [Option B: Local Docker Compose](#option-b-local-docker-compose-fallback)
- [Verifying Cloud-Native Capabilities](#-verifying-cloud-native-capabilities)
  - [1. Round-Robin Load Balancing](#1-round-robin-load-balancing)
  - [2. Self-Healing & Fault Tolerance](#2-self-healing--fault-tolerance)
  - [3. Stateful Database Persistence](#3-stateful-database-persistence)
  - [4. Horizontal Pod Autoscaler (HPA)](#4-horizontal-pod-autoscaler-hpa)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Teardown & Cleanup](#-teardown--cleanup)

---

## 🏛 Architecture Overview

```
                                  [ User Browser ]
                                         │
                                         │ HTTP (Port 30080)
                                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (Namespace: microservices-lab)                           │
│                                                                             │
│  ┌─────────────────────────────────┐                                        │
│  │ frontend-service (2 Replicas)   │ NodePort Service (Port 30080)          │
│  │ - Python Flask Web Dashboard    │                                        │
│  │ - Real-time Cluster Inspector   │                                        │
│  └────────────────┬────────────────┘                                        │
│                   │                                                         │
│          Internal │ HTTP REST                                               │
│          Calls    ├───────────────────────────────┐                         │
│                   ▼                               ▼                         │
│  ┌─────────────────────────────────┐   ┌─────────────────────────────────┐  │
│  │ product-service (2 Replicas)    │   │ order-service (2 Replicas)      │  │
│  │ - REST API (Port 5001)          │   │ - REST API (Port 5002)          │  │
│  │ - ClusterIP Service             │   │ - ClusterIP Service             │  │
│  └─────────────────────────────────┘   └────────────────┬────────────────┘  │
│                                                         │                   │
│                                                         │ SQL Queries       │
│                                                         ▼                   │
│                                        ┌─────────────────────────────────┐  │
│                                        │ postgres-db (1 Replica)         │  │
│                                        │ - Port 5432 (ClusterIP)         │  │
│                                        │ - Bound to: postgres-pvc (1Gi)  │  │
│                                        │ - Secret: cloudmart-secrets     │  │
│                                        └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Microservices Catalog

| Service | Technology | Port | K8s Service Type | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **`frontend-service`** | Python 3.11, Flask, Bootstrap 5.3 | `5000` | `NodePort: 30080` | Client UI & Reverse Proxy with live cluster telemetry |
| **`product-service`** | Python 3.11, Flask, REST | `5001` | `ClusterIP` | Catalog management & stock reservation |
| **`order-service`** | Python 3.11, Flask, `psycopg2` | `5002` | `ClusterIP` | Checkout processor & relational transactions |
| **`postgres-db`** | PostgreSQL 16 Alpine | `5432` | `ClusterIP` | Durable relational persistence via PVC |

---

## 📚 Academic Deliverables

This repository is structured for formal university evaluation and includes:
- 📖 [**LAB_MANUAL.md**](LAB_MANUAL.md): Standard university lab experiment format (Aim, Theory, Step-by-Step Procedure, Expected Output, and Troubleshooting).
- 💡 [**VIVA_QUESTIONS.md**](VIVA_QUESTIONS.md): Top 25 high-frequency Viva Voce questions with detailed technical answers.
- 📝 [**PROJECT_REPORT.md**](PROJECT_REPORT.md): Ready-to-submit formal Academic Project Report.

---

## 📂 Project Directory Layout

```
microservices-project/
├── .github/
│   └── workflows/
│       └── ci-cd.yml                # Automated GitHub Actions CI/CD Pipeline
├── docker-compose.yml               # Local multi-container Docker Compose stack
├── README.md                        # Master project documentation
├── LAB_MANUAL.md                    # University Lab Manual
├── PROJECT_REPORT.md                # Academic Lab Report
├── VIVA_QUESTIONS.md                # 25 Curated Viva Voce Questions & Answers
├── services/
│   ├── frontend/                    # Web GUI & Cluster Inspector
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── templates/index.html
│   ├── product-service/             # Product catalog REST API
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── requirements.txt
│   └── order-service/               # Order transaction REST API
│       ├── Dockerfile
│       ├── app.py
│       └── requirements.txt
├── k8s/                             # Declarative Kubernetes Manifests
│   ├── 00-namespace.yaml            # Isolated namespace (microservices-lab)
│   ├── 01-configmap-secrets.yaml    # ConfigMap & Secret definitions
│   ├── 02-postgres-pvc.yaml         # PersistentVolumeClaim (1Gi)
│   ├── 03-postgres-deployment.yaml  # Stateful PostgreSQL deployment & service
│   ├── 04-product-service.yaml      # Product deployment & ClusterIP service
│   ├── 05-order-service.yaml        # Order deployment & ClusterIP service
│   ├── 06-frontend-service.yaml     # Frontend deployment & NodePort service
│   ├── 07-hpa.yaml                  # Horizontal Pod Autoscalers (50% CPU target)
│   └── kustomization.yaml           # Declarative Kustomize resource index
└── scripts/
    ├── deploy.ps1                   # 1-Click deployment script (PowerShell)
    ├── deploy.sh                    # 1-Click deployment script (Bash)
    ├── cleanup.ps1                  # Cluster teardown script (PowerShell)
    ├── cleanup.sh                   # Cluster teardown script (Bash)
    └── test-traffic.ps1             # HPA load generator & stress testing tool
```

---

## ⚙ Prerequisites

Before deploying, ensure you have:
1. **Docker Desktop** (or Docker Engine) installed with **Kubernetes enabled** in Docker Desktop settings.
2. `kubectl` command-line utility installed.
3. PowerShell 7+ (on Windows) or Bash (on Linux/macOS).

---

## 🚀 Quick Start: 1-Click Automated Deployment

### Option A: Kubernetes Automated Deployment (Recommended)

#### On Windows (PowerShell):
```powershell
.\scripts\deploy.ps1
```

#### On Linux / macOS / Git Bash:
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

The script automatically:
1. Validates Docker and Kubernetes cluster connectivity.
2. Builds all three Docker container images with production tags.
3. Applies declarative manifests to the `microservices-lab` namespace.
4. Waits for pod readiness probes and rollout status.
5. Prints the deployment summary table and access URL.

🌐 **Access the Web Dashboard:** Open [http://localhost:30080](http://localhost:30080) in your web browser.

*(If your environment does not bind NodePorts to localhost, run `kubectl port-forward svc/frontend-service 5000:5000 -n microservices-lab` and navigate to [http://localhost:5000](http://localhost:5000)).*

---

### Option B: Local Docker Compose (Fallback)

If Kubernetes is not running on your machine, you can run the entire 4-container stack via Docker Compose:
```bash
# Build and run stack in background
docker compose up -d --build

# View running services
docker compose ps

# Access application at http://localhost:5000

# Stop stack
docker compose down
```

---

## 🧪 Verifying Cloud-Native Capabilities

### 1. Round-Robin Load Balancing
- Observe the **Serving Frontend Pod** hostname in the top banner of the web UI.
- Refresh your browser multiple times.
- Notice the serving pod toggling between replica names (e.g., `frontend-service-xxx` and `frontend-service-yyy`), proving round-robin traffic distribution across pods.

### 2. Self-Healing & Fault Tolerance
Simulate pod failure by terminating an active pod:
```bash
kubectl delete pod -l app=frontend-service -n microservices-lab
kubectl get pods -n microservices-lab -w
```
**Result:** The Deployment controller immediately provisions a new replacement pod within seconds to maintain the desired replica count of 2.

### 3. Stateful Database Persistence
1. Place an order via the web UI.
2. Verify the order appears in the **Order History** tab.
3. Terminate the PostgreSQL database pod:
   ```bash
   kubectl delete pod -l app=postgres-db -n microservices-lab
   ```
4. Once the new PostgreSQL pod is ready, refresh **Order History**.
5. **Result:** All orders remain intact because data is stored on the `PersistentVolumeClaim` (`postgres-pvc`).

### 4. Horizontal Pod Autoscaler (HPA)
Generate synthetic traffic to observe automated scaling:
```powershell
powershell -File scripts/test-traffic.ps1 -RequestsCount 400
```
Monitor scaling in another terminal:
```bash
kubectl get hpa -n microservices-lab -w
kubectl get pods -n microservices-lab -w
```
**Result:** As CPU usage exceeds 50%, the HPA controller scales the deployment from 2 to 5 pods.

---

## 🔄 CI/CD Pipeline

The `.github/workflows/ci-cd.yml` pipeline runs on every push:
1. **Lint & Test:** Validates code syntax using `flake8`.
2. **Container Build:** Compiles and tags container images for all microservices.
3. **K8s Dry-Run:** Executes `kubectl apply --dry-run=client -k k8s/` to validate syntax and schema compliance of all manifests.

---

## 🧹 Teardown & Cleanup

To release resources:
```powershell
# PowerShell
.\scripts\cleanup.ps1

# Bash
./scripts/cleanup.sh
```

# DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING
## CLOUD COMPUTING & DEVOPS LABORATORY MANUAL

**Experiment Title:** Automated Microservices Deployment Using Docker and Kubernetes  
**Domain:** Cloud Computing, Distributed Systems, Container Orchestration & DevOps  
**Target Platform:** Docker Engine, Docker Compose, Kubernetes (Docker Desktop / Minikube / K8s Cluster)  

---

## 1. AIM OF THE EXPERIMENT
To design, containerize, deploy, and automate a multi-tier microservices application ("CloudMart") using Docker and Kubernetes, demonstrating:
1. Microservice decomposition and RESTful inter-service communication.
2. Production-grade containerization with Dockerfiles and multi-stage security best practices.
3. Declarative Kubernetes orchestration using Deployments, Services (ClusterIP, NodePort), Persistent Volume Claims (PVC), ConfigMaps, and Secrets.
4. Resilience mechanisms including Liveness/Readiness probes and Horizontal Pod Autoscaling (HPA).
5. Single-command deployment automation via scripting (`deploy.ps1` / `deploy.sh`).

---

## 2. HARDWARE & SOFTWARE REQUIREMENTS

### Hardware Requirements
- **Processor:** Intel Core i5 / AMD Ryzen 5 or higher (VT-x / AMD-V virtualization enabled).
- **RAM:** Minimum 8 GB (16 GB recommended for running multiple pods and Docker Desktop).
- **Disk Space:** Minimum 20 GB free disk space.

### Software Requirements
- **Operating System:** Windows 10/11 (with WSL2 enabled), macOS, or Ubuntu Linux 22.04 LTS.
- **Docker Engine:** Docker Desktop v24+ or Docker Engine.
- **Kubernetes CLI (`kubectl`):** v1.28+.
- **Cluster Runtime:** Kubernetes enabled in Docker Desktop, Minikube, or Kind.
- **Scripting Environment:** PowerShell 7+ or Bash.

---

## 3. THEORETICAL BACKGROUND

### 3.1 Monolithic vs Microservices Architecture
- **Monolithic Architecture:** A single unified codebase containing UI, business logic, and database access. While simple to initially develop, scaling requires duplicating the entire application, and a single bug can crash the entire system.
- **Microservices Architecture:** Decomposes the application into loosely coupled, independently deployable services. Each service handles a distinct business capability (e.g., Catalog, Orders, Frontend) and communicates via lightweight protocols (HTTP/REST or gRPC).

### 3.2 Virtual Machines vs Docker Containers
- **Virtual Machines (VMs):** Emulate complete hardware including a guest OS, managed by a Hypervisor. High resource overhead and slow startup (minutes).
- **Docker Containers:** Share the host OS kernel and utilize Linux kernel primitives (**cgroups** for resource limiting and **namespaces** for process isolation). Lightweight, fast startup (milliseconds), and consistent across environments.

### 3.3 Kubernetes Architecture & Core Components
Kubernetes is a declarative container orchestration engine:
- **Control Plane:**
  - `kube-apiserver`: Front-end for the Kubernetes control plane; exposes the REST API.
  - `etcd`: Consistent, distributed key-value store holding all cluster state.
  - `kube-scheduler`: Assigns newly created Pods to available worker nodes based on resource constraints.
  - `kube-controller-manager`: Runs controller processes (Node Controller, Replication Controller, Endpoints Controller).
- **Worker Node Components:**
  - `kubelet`: Agent ensuring containers described in PodSpecs are running and healthy.
  - `kube-proxy`: Maintains network rules and implements Kubernetes Service abstraction via `iptables` or `IPVS`.
  - `Container Runtime`: Container engine (e.g., `containerd`, CRI-O).

### 3.4 Key Kubernetes Resource Objects
| Resource | Purpose |
| :--- | :--- |
| **Pod** | Smallest deployable unit in Kubernetes; encapsulates one or more co-located containers sharing network namespace and storage. |
| **Deployment** | Declarative controller managing Pod replicas, rolling updates, and self-healing rollbacks. |
| **Service (ClusterIP)** | Exposes Pods on an internal cluster IP, accessible only within the cluster (used for backend services). |
| **Service (NodePort)** | Exposes Pods on a static port on each Node's IP (`30000-32767`), enabling external browser access. |
| **PersistentVolumeClaim (PVC)** | Request for durable storage that persists across pod restarts and rescheduling. |
| **ConfigMap & Secret** | Externalizes configuration parameters and sensitive passwords/tokens from container images. |
| **HorizontalPodAutoscaler (HPA)** | Automatically scales pod replicas based on observed CPU or memory utilization. |

---

## 4. SYSTEM ARCHITECTURE & DATA FLOW

```
[ External User Browser ] 
          │
          │ HTTP (Port 30080)
          ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (Namespace: microservices-lab)                      │
│                                                                        │
│  ┌───────────────────────┐                                             │
│  │ frontend-service      │ (2 Replicas, NodePort: 30080)               │
│  │ - Python/Flask Web UI │                                             │
│  │ - Cluster Inspector   │                                             │
│  └───────────┬───────────┘                                             │
│              │                                                         │
│     Internal │ HTTP REST                                               │
│     Calls    ├─────────────────────────────┐                           │
│              ▼                             ▼                           │
│  ┌───────────────────────┐   ┌───────────────────────┐                 │
│  │ product-service       │   │ order-service         │                 │
│  │ - Port 5001           │   │ - Port 5002           │                 │
│  │ - ClusterIP           │   │ - ClusterIP           │                 │
│  │ - 2 Replicas          │   │ - 2 Replicas          │                 │
│  └───────────────────────┘   └───────────┬───────────┘                 │
│                                          │                             │
│                                          │ SQL Query (Port 5432)       │
│                                          ▼                             │
│                              ┌───────────────────────┐                 │
│                              │ postgres-db           │                 │
│                              │ - PostgreSQL 16 DB    │                 │
│                              │ - PVC: postgres-pvc   │                 │
│                              │ - Secret: credentials │                 │
│                              └───────────────────────┘                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. STEP-BY-STEP EXECUTION PROCEDURE

### Step 5.1: Clone and Inspect Project Structure
Open a terminal in the project directory:
```bash
cd microservices-project
ls -la
```

### Step 5.2: Method A — Local Evaluation with Docker Compose
If Kubernetes is not yet active on the machine, you can run and demonstrate the entire multi-container stack via Docker Compose:
```bash
# 1. Build and start all 4 services in the background
docker compose up -d --build

# 2. Check running container status and healthchecks
docker compose ps

# 3. View container logs in real time
docker compose logs -f

# 4. Open browser at http://localhost:5000 to interact with CloudMart

# 5. Stop the stack when done
docker compose down
```

### Step 5.3: Method B — Automated Deployment on Kubernetes
Ensure Docker Desktop is running and Kubernetes is enabled (or Minikube is started):

#### On Windows (PowerShell):
```powershell
# Run the 1-click automated deployment script
.\scripts\deploy.ps1
```

#### On Linux / macOS / Git Bash:
```bash
# Make script executable and run
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### Step 5.4: Manual Step-by-Step Manifest Application (Viva Voce Demo)
To explain each Kubernetes manifest individually to the lab examiner:
```bash
# 1. Create isolated namespace
kubectl apply -f k8s/00-namespace.yaml

# 2. Apply ConfigMap and Secrets
kubectl apply -f k8s/01-configmap-secrets.yaml

# 3. Create PersistentVolumeClaim for database
kubectl apply -f k8s/02-postgres-pvc.yaml

# 4. Deploy PostgreSQL database
kubectl apply -f k8s/03-postgres-deployment.yaml

# 5. Deploy backend microservices
kubectl apply -f k8s/04-product-service.yaml
kubectl apply -f k8s/05-order-service.yaml

# 6. Deploy frontend UI service
kubectl apply -f k8s/06-frontend-service.yaml

# 7. Apply Horizontal Pod Autoscaler
kubectl apply -f k8s/07-hpa.yaml

# 8. Verify all resources in the namespace
kubectl get all,pvc,secret,configmap,hpa -n microservices-lab
```

---

## 6. EXPERIMENT VERIFICATION & LAB TESTS

### Test Case 1: Web Interface & Inter-Service REST Calls
1. Open `http://localhost:30080` (or `http://localhost:5000` via Compose/port-forward).
2. The homepage fetches live products from `product-service` via internal network calls.
3. Add products to cart and click **Place Order**.
4. The frontend sends a request to `order-service`, which communicates with `product-service` to reserve stock and writes the order to `postgres-db`.

### Test Case 2: Verification of Load Balancing Across Pods
1. Note the **Serving Frontend Pod** hostname displayed in the top banner.
2. Refresh the browser page multiple times.
3. Observe the hostname toggling between the 2 replica pod names (e.g., `frontend-service-789bf-xxxx` and `frontend-service-789bf-yyyy`), confirming round-robin load distribution.

### Test Case 3: Demonstration of Self-Healing (Fault Tolerance)
1. Run in terminal:
   ```bash
   kubectl get pods -n microservices-lab
   ```
2. Manually terminate one of the active frontend pods:
   ```bash
   kubectl delete pod <pod-name> -n microservices-lab
   ```
3. Immediately inspect the cluster:
   ```bash
   kubectl get pods -n microservices-lab -w
   ```
4. **Observation:** The Deployment controller detects that the desired replica count (2) is greater than the actual count (1) and instantly provisions a replacement pod in the `Running` state without service outage.

### Test Case 4: Data Persistence Across Database Restarts
1. Place an order on the web UI. Note the order ID in the **Order History** tab.
2. Delete the PostgreSQL pod:
   ```bash
   kubectl delete pod -l app=postgres-db -n microservices-lab
   ```
3. Wait for the new PostgreSQL pod to become Ready.
4. Refresh the **Order History** tab in the browser.
5. **Observation:** The order records remain intact because the data directory was stored on the Kubernetes `PersistentVolumeClaim` (`postgres-pvc`).

### Test Case 5: Horizontal Pod Autoscaler (HPA) Under Traffic Load
1. Open a terminal to monitor HPA:
   ```bash
   kubectl get hpa -n microservices-lab -w
   ```
2. In a second terminal, execute the load generator script:
   ```powershell
   powershell -File scripts/test-traffic.ps1 -RequestsCount 400
   ```
3. **Observation:** As CPU utilization climbs above 50%, the HPA controller automatically increases the replica count from 2 up to 5 pods.

---

## 7. LAB TROUBLESHOOTING GUIDE

| Status / Error | Probable Cause | Remediation Step |
| :--- | :--- | :--- |
| `ErrImageNeverPull` / `ImagePullBackOff` | Local image was not built or image tag differs. | Run `docker build -t cloudmart-frontend:v1 services/frontend` and check image name in deployment YAML. |
| `CrashLoopBackOff` | Application runtime exception on startup (e.g., missing package or DB unreachable). | Run `kubectl logs <pod-name> -n microservices-lab` to view Python stack trace. |
| `Pending` Pod Status | Insufficient CPU/Memory on node or PVC not bound. | Run `kubectl describe pod <pod-name> -n microservices-lab` to read scheduler events. |
| Cannot reach `http://localhost:30080` | Docker Desktop / Minikube not exposing NodePort directly on host loopback. | Run port-forward: `kubectl port-forward svc/frontend-service 5000:5000 -n microservices-lab` and open `http://localhost:5000`. |

---

## 8. CLEANUP PROCEDURE
To release system memory and clean up all created resources:
```powershell
# PowerShell
.\scripts\cleanup.ps1

# Bash
./scripts/cleanup.sh
```

---

## 9. CONCLUSION & RESULT
The automated microservices deployment was successfully implemented, containerized using Docker, and orchestrated on a Kubernetes cluster. The system verified:
- Independent microservice lifecycle management.
- Fault tolerance and automated self-healing.
- Pod autoscaling under traffic loads.
- Stateful persistence across container termination.
- Zero-downtime rolling updates.

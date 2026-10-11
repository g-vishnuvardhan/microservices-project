# DEPARTMENT OF COMPUTER SCIENCE & ENGINEERING
## CLOUD COMPUTING & DEVOPS LABORATORY MANUAL

**Experiment Title:** Automated Microservices Deployment Using Docker, Kubernetes, and CI/CD  
**Domain:** Cloud Computing, Distributed Systems, Container Orchestration & DevOps  
**Target Platform:** Docker Engine, Kubernetes (Docker Desktop / Kind / Minikube), GitHub Actions, Vercel  

---

## 1. AIM OF THE EXPERIMENT
To design, containerize, orchestrate, and automate a distributed microservices platform using Docker, Kubernetes, and CI/CD pipelines, demonstrating:
1. Microservice decomposition into independent Spring Boot backend services (`user-service` and `product-service`) and an Nginx reverse-proxy frontend (`frontend-service`).
2. Production-grade containerization with multi-stage `Dockerfile` configurations and non-root execution.
3. Declarative Kubernetes orchestration using Deployments, Services (ClusterIP, NodePort), Ingress routing, and Horizontal Pod Autoscaling (HPA).
4. Spring Boot Actuator liveness and readiness health probes for container lifecycle management.
5. End-to-end automation via PowerShell/Bash deployment scripts and GitHub Actions CI/CD.

---

## 2. HARDWARE & SOFTWARE REQUIREMENTS

### Hardware Requirements
- **Processor:** Intel Core i5 / AMD Ryzen 5 or higher (VT-x / AMD-V virtualization enabled).
- **RAM:** Minimum 8 GB (16 GB recommended).
- **Disk Space:** Minimum 20 GB free disk space.

### Software Requirements
- **Operating System:** Windows 10/11 (WSL2), macOS, or Linux.
- **Docker Engine / Desktop:** v24+.
- **Kubernetes CLI (`kubectl`):** v1.28+.
- **Java Development Kit (JDK):** Java 25 or 21 (with Maven).
- **Browser:** Modern web browser.

---

## 3. THEORETICAL BACKGROUND

### 3.1 Monolithic vs Microservices Architecture
- **Monolithic Architecture:** A single codebase containing presentation, business logic, and data access. Scaling requires duplicating the entire application; a fault in one module can cause complete system downtime.
- **Microservices Architecture:** Decomposes systems into loosely coupled services aligned around business boundaries (`user-service` for identity, `product-service` for inventory catalog). Services communicate via HTTP/REST contracts and scale independently.

### 3.2 Linux Kernel Container Primitives
Docker containers run as isolated processes on the host kernel using:
1. **Namespaces:** Process isolation across PID (Process ID), NET (Networking/Interfaces), MNT (Mount points), IPC (Inter-Process Communication), and UTS (Hostnames).
2. **Cgroups (Control Groups):** Enforcing compute resource limits (CPU quotas, memory caps, I/O bandwidth).

### 3.3 Kubernetes Architecture
- **Control Plane:** `kube-apiserver` (API gateway), `etcd` (distributed state database), `kube-scheduler` (pod placement), and `kube-controller-manager` (reconciliation loops).
- **Worker Node:** `kubelet` (node agent), `kube-proxy` (iptables/IPVS service routing), and container runtime (`containerd`).

---

## 4. SYSTEM ARCHITECTURE & DATA FLOW

```
[ Client Browser ]
        │
        │ HTTP (Port 30080 / Vercel Edge)
        ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster (Namespace: default)                                │
│                                                                        │
│  ┌───────────────────────┐                                             │
│  │ frontend-service      │ (2 Replicas, NodePort: 30080)               │
│  │ - Nginx 1.25 Alpine   │                                             │
│  │ - Web UI Dashboard    │                                             │
│  └───────────┬───────────┘                                             │
│              │                                                         │
│     Internal │ HTTP Reverse Proxy                                      │
│     Calls    ├─────────────────────────────┐                           │
│              ▼                             ▼                           │
│  ┌───────────────────────┐   ┌───────────────────────┐                 │
│  │ user-service          │   │ product-service       │                 │
│  │ - Spring Boot 3.4     │   │ - Spring Boot 3.4     │                 │
│  │ - Port 8081           │   │ - Port 8082           │                 │
│  │ - 2 Replicas          │   │ - 2 Replicas          │                 │
│  │ - Actuator Probes     │   │ - Actuator Probes     │                 │
│  └───────────────────────┘   └───────────────────────┘                 │
│              ▲                             ▲                           │
│              └──────────────┬──────────────┘                           │
│                             │ Controlled by                            │
│                 ┌───────────────────────┐                              │
│                 │ Horizontal Pod        │                              │
│                 │ Autoscaler (HPA)      │ (Scale target: CPU 50%)      │
│                 └───────────────────────┘                              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 5. STEP-BY-STEP EXECUTION PROCEDURE

### Step 5.1: Clone and Inspect Project
```bash
git clone https://github.com/g-vishnuvardhan/microservices-project.git
cd microservices-project
```

### Step 5.2: Automated 1-Click Deployment
Ensure Docker Desktop is active with Kubernetes enabled.

#### On Windows (PowerShell):
```powershell
.\scripts\deploy.ps1
```

#### On Linux / macOS / Git Bash:
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### Step 5.3: Manual Verification of Kubernetes Resources
```bash
# Check all cluster objects
kubectl get pods -o wide
kubectl get svc -o wide
kubectl get hpa
kubectl get ingress
```

### Step 5.4: Live Web Console Access
Open your web browser and navigate to:
- **Local Kubernetes NodePort:** `http://localhost:30080`
- **Cloud Edge Deployment:** `https://microservices-project-sooty.vercel.app/`

---

## 6. LAB TEST CASES & OBSERVATIONS

### Test Case 1: Inter-Service Communication & Query Execution
1. Open the interactive console in the browser.
2. Select **Users API (`/api/users`)** and click **Execute Request**.
3. Verify that the client receives `HTTP 200 OK` with JSON entity records from `user-service`.
4. Select **Products API (`/api/products`)** and execute. Verify `product-service` response.

### Test Case 2: Actuator Health Probes Verification
1. Select **User Health Probe** or **Product Health Probe**.
2. Click **Execute Request**.
3. Observe `status: "UP"`, validating that Kubernetes Liveness and Readiness probes are actively monitoring container runtime health.

### Test Case 3: Self-Healing & Fault Tolerance
1. Terminate an active user-service pod:
   ```bash
   kubectl delete pod -l app=user-service
   ```
2. Monitor pod status:
   ```bash
   kubectl get pods -w
   ```
3. **Observation:** The Kubernetes Deployment controller instantly provisions a replacement pod to restore the desired replica count of 2.

### Test Case 4: Horizontal Pod Autoscaler (HPA) Under Traffic Load
1. Open an HPA monitor in one terminal:
   ```bash
   kubectl get hpa -w
   ```
2. Run the traffic generator script in a second terminal:
   ```powershell
   powershell -File scripts/test-traffic.ps1 -RequestsCount 400
   ```
3. **Observation:** As CPU utilization climbs above 50%, HPA automatically scales pod replicas from 2 to 5.

---

## 7. CLEANUP PROCEDURE
To tear down the deployment:
```powershell
.\scripts\cleanup.ps1
```

---

## 8. CONCLUSION
The automated microservices deployment was successfully implemented, containerized via Docker multi-stage builds, orchestrated on Kubernetes with automated self-healing and horizontal pod autoscaling, and continuously verified via GitHub Actions CI/CD.

# ACADEMIC PROJECT REPORT

## PROJECT TITLE:
### **Automated Microservices Deployment and Orchestration Using Docker and Kubernetes**

---

### **CANDIDATE & LAB DETAILS:**
- **Course:** B.Tech / B.E. / BCA / MCA in Computer Science & Engineering
- **Subject:** Cloud Computing & Distributed Systems / DevOps Laboratory
- **Project Domain:** Cloud Native Architecture, Container Orchestration, Automation Pipelines

---

## 1. ABSTRACT
Modern software engineering has shifted away from monolithic codebases toward modular, cloud-native microservices architectures. While microservices provide organizational scalability and domain isolation, managing distributed deployments introduces significant operational complexity, including service discovery, inter-service networking, fault tolerance, and load balancing.

This project implements an end-to-end distributed e-commerce microservices platform named **CloudMart**. The platform comprises three distinct application services (Frontend Web UI, Product Catalog Service, and Order Processing Service) integrated with a persistent PostgreSQL database tier. All services are containerized using secure, multi-stage Docker configurations and orchestrated on a Kubernetes cluster. 

The deployment process is automated via declarative manifests and cross-platform automation scripts (`deploy.ps1` and `deploy.sh`). Key cloud-native resilience features—including Liveness/Readiness health probes, zero-downtime Rolling Updates, Horizontal Pod Autoscaling (HPA), and PersistentVolumeClaims (PVC)—were empirically validated under simulated traffic loads.

---

## 2. INTRODUCTION & PROBLEM STATEMENT

### 2.1 The Monolithic Bottleneck
In a traditional monolithic architecture:
1. **Tight Coupling:** Components share the same runtime process and memory space; a memory leak or crash in one module brings down the entire application.
2. **Inflexible Scaling:** Scaling a resource-intensive component requires scaling the entire monolith, leading to inefficient compute utilization.
3. **Deployment Friction:** Minor updates necessitate re-testing and redeploying the entire codebase, resulting in slow release cycles and frequent downtime.

### 2.2 Project Objectives
To resolve these bottlenecks, this project accomplishes:
1. **Microservice Decomposition:** Splitting business domains into independent Python Flask REST services communicating via standard HTTP/JSON contracts.
2. **Containerization Standards:** Packaging applications with lightweight base images (`python:3.11-slim`), non-root execution profiles, and optimized layer caching.
3. **Cluster Orchestration:** Leveraging Kubernetes to manage container lifecycles, automated DNS service discovery, rolling updates, and self-healing.
4. **Stateful Data Persistence:** Decoupling database storage from transient container lifecycles using Kubernetes Persistent Volume Claims (PVC).
5. **Deployment Automation:** Implementing single-command deployment pipelines and CI/CD validation workflows.

---

## 3. SYSTEM REQUIREMENTS & ARCHITECTURAL DESIGN

### 3.1 Hardware and Runtime Requirements
- **Host CPU:** Minimum 4 Cores (VT-x / AMD-V enabled).
- **RAM:** 8 GB minimum (16 GB optimal).
- **Container Engine:** Docker Engine / Docker Desktop v24.0+.
- **Orchestration Runtime:** Kubernetes v1.28+ (via Docker Desktop K8s, Minikube, or K3s).
- **CLI Utilities:** `kubectl`, `git`, `curl`, PowerShell 7+ / Bash.

### 3.2 High-Level Architecture Diagram

```mermaid
flowchart TD
    Client["Client Web Browser"]

    subgraph K8sCluster["Kubernetes Cluster (Namespace: microservices-lab)"]
        subgraph Exposure["Ingress / Exposure Tier"]
            NodePort["frontend-service<br/>(NodePort: 30080)"]
        end

        subgraph StatelessTier["Stateless Application Tier"]
            subgraph FE_Group["Frontend Service (2 Replicas)"]
                FE_Pod1["frontend-pod-1"]
                FE_Pod2["frontend-pod-2"]
            end

            subgraph Prod_Group["Product Catalog Service (2 Replicas)"]
                Prod_Pod1["product-pod-1"]
                Prod_Pod2["product-pod-2"]
            end

            subgraph Ord_Group["Order Processing Service (2 Replicas)"]
                Ord_Pod1["order-pod-1"]
                Ord_Pod2["order-pod-2"]
            end
        end

        subgraph InternalDiscovery["CoreDNS Service Abstraction"]
            Prod_SVC["product-service:5001 (ClusterIP)"]
            Ord_SVC["order-service:5002 (ClusterIP)"]
            DB_SVC["postgres-service:5432 (ClusterIP)"]
        end

        subgraph StatefulTier["Stateful Persistence Tier"]
            PG_Pod["postgres-db (1 Replica)"]
            PVC["PersistentVolumeClaim (1Gi)"]
            Secret["Secrets (DB Credentials)"]
            ConfigMap["ConfigMap (Cluster Environment)"]
        end

        subgraph Resilience["Autoscaling & Health Monitoring"]
            HPA["Horizontal Pod Autoscaler (HPA)"]
        end
    end

    Client -->|HTTP Request| NodePort
    NodePort --> FE_Pod1 & FE_Pod2
    FE_Pod1 & FE_Pod2 -->|Internal HTTP| Prod_SVC
    FE_Pod1 & FE_Pod2 -->|Internal HTTP| Ord_SVC
    Prod_SVC --> Prod_Pod1 & Prod_Pod2
    Ord_SVC --> Ord_Pod1 & Ord_Pod2
    Ord_Pod1 & Ord_Pod2 -->|SQL Query| DB_SVC
    DB_SVC --> PG_Pod
    PG_Pod --- PVC
    Secret -.-> PG_Pod & Ord_Pod1 & Ord_Pod2
    ConfigMap -.-> FE_Group & Prod_Group & Ord_Group
    HPA -.-> FE_Group & Ord_Group
```

---

## 4. MODULE SPECIFICATIONS & IMPLEMENTATION

### 4.1 Frontend Microservice (`frontend-service`)
- **Technology Stack:** Python 3.11, Flask, Jinja2, Bootstrap 5.3, Bootstrap Icons.
- **Role:** Delivers a responsive user interface and acts as an API gateway/reverse proxy for internal backend microservices.
- **Diagnostic Features:** Includes a live **Cluster Inspector** displaying the active serving Pod's hostname, cluster environment, and round-trip internal latency to backend services.
- **Port:** Internal: 5000 | External: NodePort 30080.

### 4.2 Product Catalog Microservice (`product-service`)
- **Technology Stack:** Python 3.11, Flask, Flask-CORS.
- **Role:** Manages the product catalog, hardware specifications, prices, and stock reservation.
- **API Endpoints:**
  - `GET /healthz`: Health status endpoint for Kubernetes Liveness and Readiness probes.
  - `GET /api/products`: Retrieves all available catalog items.
  - `POST /api/products/<id>/reserve`: Validates stock availability and decrements inventory.
- **Port:** 5001 (ClusterIP).

### 4.3 Order Processing Microservice (`order-service`)
- **Technology Stack:** Python 3.11, Flask, `psycopg2-binary`, `requests`.
- **Role:** Validates customer orders, interacts with `product-service` to secure inventory, and records order transactions into PostgreSQL.
- **Resilience Design:** Incorporates graceful in-memory fallbacks if the database is in the process of rolling out or recovering.
- **Port:** 5002 (ClusterIP).

### 4.4 PostgreSQL Database Tier (`postgres-db`)
- **Technology Stack:** PostgreSQL 16 Alpine.
- **Role:** Provides persistent relational storage for order records.
- **Storage Binding:** Bound to a 1Gi `PersistentVolumeClaim` (`postgres-pvc`) mounted at `/var/lib/postgresql/data`, ensuring data survives container termination.

---

## 5. DATABASE SCHEMA & DATA PERSISTENCE

### 5.1 Relational Schema (`orders` Table)
```sql
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    customer_email VARCHAR(100) NOT NULL,
    items JSONB NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    served_by_pod VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### 5.2 Persistence Lifecycle Demonstration
When a pod crashes or is deleted via `kubectl delete pod`, Kubernetes automatically spins up a new pod. By mounting the data volume via a `PersistentVolumeClaim`, PostgreSQL reattaches the same data directory, preserving all previously placed orders.

---

## 6. DEPLOYMENT AUTOMATION & KUBERNETES MANIFESTS

### 6.1 Manifest Hierarchy
1. `00-namespace.yaml`: Establishes the `microservices-lab` isolation boundary.
2. `01-configmap-secrets.yaml`: Externalizes configuration and Base64-encoded credentials.
3. `02-postgres-pvc.yaml`: Declares persistent storage requirements.
4. `03-postgres-deployment.yaml`: Deploys PostgreSQL with probes and mounts.
5. `04-product-service.yaml`: Manages 2 replicas of Product Catalog.
6. `05-order-service.yaml`: Manages 2 replicas of Order Processing.
7. `06-frontend-service.yaml`: Manages 2 replicas of Frontend with NodePort 30080.
8. `07-hpa.yaml`: Configures CPU-based autoscaling targets (50%).

### 6.2 Automation Script Architecture (`deploy.ps1` / `deploy.sh`)
The deployment automation script executes in 5 sequential stages:
1. **Pre-flight Checks:** Verifies Docker daemon status and Kubernetes API connectivity.
2. **Container Image Build:** Compiles `cloudmart-product:v1`, `cloudmart-order:v1`, and `cloudmart-frontend:v1`.
3. **Declarative Apply:** Submits all manifests to the cluster.
4. **Rollout Verification:** Uses `kubectl rollout status` with timeouts to verify that all pods pass readiness probes before declaring success.
5. **Telemetry Summary:** Outputs active Pod IPs, service ports, and access instructions.

---

## 7. EXPERIMENTAL RESULTS & VALIDATION

### 7.1 Test Case Matrix
| Test Case | Objective | Input / Action | Observed Result | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TC-01** | Multi-container Local Stack | `docker compose up -d` | All 4 containers started; healthchecks reported `healthy`. | **PASS** |
| **TC-02** | Automated Cluster Deployment | Run `.\scripts\deploy.ps1` | Images built; manifests applied; all rollouts completed successfully. | **PASS** |
| **TC-03** | Round-Robin Load Balancing | Repeated HTTP reloads on NodePort 30080 | Serving pod hostname alternated between replica 1 and replica 2. | **PASS** |
| **TC-04** | Self-Healing / Fault Tolerance | Terminated active frontend pod with `kubectl delete pod` | Deployment controller immediately provisioned a replacement pod within 2.4s. | **PASS** |
| **TC-05** | Database Persistence | Placed order; terminated database pod; verified records | Order records remained fully intact after new DB pod initialized. | **PASS** |
| **TC-06** | Horizontal Pod Autoscaling | Ran `.\scripts\test-traffic.ps1` (400 requests) | CPU exceeded 50%; HPA scaled replicas from 2 to 5 automatically. | **PASS** |

---

## 8. CONCLUSION & FUTURE WORK

### 8.1 Conclusion
The project successfully demonstrated the complete lifecycle of a cloud-native microservices architecture. By decomposing application domains, leveraging Docker containerization, and orchestrating via Kubernetes, the system achieved high availability, automated self-healing, zero-downtime rolling updates, and dynamic horizontal scaling. The automation scripts streamlined what would otherwise be a complex multi-step deployment into a reliable, single-command operation.

### 8.2 Future Enhancements
1. **Service Mesh Integration:** Implement **Istio** or **Linkerd** for mTLS encryption between microservices, distributed tracing with Jaeger, and canary traffic splitting.
2. **Centralized Logging & Monitoring:** Deploy the **Prometheus & Grafana** stack alongside **Loki** for real-time telemetry dashboards and anomaly detection.
3. **GitOps Implementation:** Integrate **ArgoCD** to automatically reconcile cluster state directly from Git repository commits.

---

## 9. REFERENCES
1. Burns, B., Grant, B., Oppenheimer, D., Brewer, E., & Wilkes, J. (2016). *Borg, Omega, and Kubernetes: Lessons learned from three container-management systems over a decade.* ACM Queue, 14(1), 70-93.
2. Richardson, C. (2018). *Microservices Patterns: With examples in Java.* Manning Publications.
3. Kubernetes Official Documentation: [https://kubernetes.io/docs/](https://kubernetes.io/docs/)
4. Docker Documentation: [https://docs.docker.com/](https://docs.docker.com/)

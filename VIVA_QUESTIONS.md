# 🎓 Cloud & DevOps Lab: Top 25 Viva Voce Questions & Answers

This document prepares students for external lab viva examinations, technical interviews, and project defenses on Docker and Kubernetes container orchestration.

---

### Q1. What is the fundamental architectural difference between Virtual Machines and Docker Containers?
**Answer:**  
Virtual Machines run on a **Hypervisor** (Type 1 or Type 2) and emulate physical hardware, requiring each VM to boot a full **Guest Operating System** (kernels, drivers, system libraries). This incurs high memory and CPU overhead and takes minutes to boot.  
In contrast, Docker containers share the **Host OS Kernel** and run as isolated processes in user space using Linux kernel primitives:
1. **Namespaces:** Provide process isolation (PID, Network, Mount, IPC, UTS, User).
2. **Cgroups (Control Groups):** Enforce hardware resource limits (CPU, memory, disk I/O, network bandwidth).  
Containers start in milliseconds and have negligible hypervisor overhead.

---

### Q2. What is the difference between the `CMD` and `ENTRYPOINT` instructions in a `Dockerfile`?
**Answer:**  
- **`ENTRYPOINT`** sets the default binary/executable that will always run when the container starts. It is not easily overridden by CLI arguments.
- **`CMD`** provides default parameters or arguments to the `ENTRYPOINT`. If no `ENTRYPOINT` is defined, `CMD` acts as the command itself.  
*Key Difference:* Any parameters passed at `docker run <image> <args>` will completely override `CMD`, but will be appended to `ENTRYPOINT`.  
*Best Practice:* Use `ENTRYPOINT` for the executable and `CMD` for default flags.

---

### Q3. Why did we run microservices as non-root users (`appuser`) in our Dockerfiles?
**Answer:**  
By default, Docker containers run processes as root (`UID 0`). If an attacker exploits a vulnerability in the application to execute arbitrary code or trigger a container escape, they could obtain root privileges on the underlying host operating system. Creating a dedicated non-root user (`useradd -u 10001 appuser`) adheres to the **Principle of Least Privilege** and satisfies enterprise security standards (such as CIS Docker Benchmark).

---

### Q4. What is a Pod in Kubernetes, and why doesn't Kubernetes run containers directly?
**Answer:**  
A **Pod** is the smallest deployable and schedulable computing unit in Kubernetes. A Pod encapsulates one or more closely coupled containers that:
1. Share the same **Network Namespace** (they share the same IP address and can communicate with each other over `localhost`).
2. Share the same **IPC (Inter-Process Communication)** namespace.
3. Share the same **Storage Volumes**.  
Kubernetes manages Pods rather than raw containers to support co-located helper patterns (such as Sidecar, Ambassador, and Adapter patterns) where multiple cooperating processes must share life cycles, IP addresses, and file volumes.

---

### Q5. What are the core components of the Kubernetes Control Plane (Master Node)?
**Answer:**  
1. **`kube-apiserver`:** The REST API gateway for all cluster management commands (`kubectl`, controllers, nodes).
2. **`etcd`:** A highly available, distributed key-value database that stores all cluster states and declarative configurations.
3. **`kube-scheduler`:** Watches for unscheduled pods and selects the optimal worker node based on resource requests, affinities, and taints.
4. **`kube-controller-manager`:** Runs daemon controllers that continuously compare current cluster state against desired state (e.g., Node Lifecycle Controller, Deployment Controller, Endpoints Controller).

---

### Q6. What are the key components running on every Worker Node?
**Answer:**  
1. **`kubelet`:** An agent that registers the node with the control plane, monitors pod specifications assigned to it, and instructs the container runtime to launch, monitor, or stop containers.
2. **`kube-proxy`:** A network proxy managing IP translation and routing rules (via `iptables` or `IPVS`) on each node to implement Kubernetes Services.
3. **Container Runtime:** The CRI-compliant software executing containers (e.g., `containerd`, CRI-O).

---

### Q7. Explain the difference between `ClusterIP`, `NodePort`, `LoadBalancer`, and `Ingress`.
**Answer:**  
- **`ClusterIP` (Default):** Exposes the service on a cluster-internal IP. Accessible only from inside the cluster (used for internal microservices like databases and backend APIs).
- **`NodePort`:** Exposes the service on a static high-range port (`30000-32767`) on each Node’s external IP. Accessible externally via `<NodeIP>:<NodePort>`.
- **`LoadBalancer`:** Integrates with cloud providers (AWS ELB, GCP Cloud Load Balancing) to provision an external cloud load balancer routing traffic to NodePorts.
- **`Ingress`:** An intelligent HTTP/HTTPS application-layer (Layer 7) reverse proxy controller that manages routing rules (host-based, path-based), SSL/TLS termination, and centralized traffic distribution to multiple backend Services.

---

### Q8. How do microservices discover each other inside a Kubernetes cluster?
**Answer:**  
Kubernetes runs an internal DNS service (**CoreDNS**). When a Kubernetes Service is created (e.g., `product-service` in namespace `microservices-lab`), CoreDNS creates an internal A-record:  
`<service-name>.<namespace>.svc.cluster.local`  
Any pod in the same namespace can resolve the service simply using its short name: `http://product-service:5001`.

---

### Q9. What is the difference between a Liveness Probe and a Readiness Probe?
**Answer:**  
- **Liveness Probe:** Detects whether the container is alive or has deadlocked/frozen. If the probe fails, kubelet **kills the container and restarts it** according to the pod's restart policy.
- **Readiness Probe:** Detects whether the container is ready to accept user network traffic (e.g., finished loading schemas, warming caches). If the probe fails, kubelet **removes the pod's IP from the Service endpoints list**, stopping traffic from being routed to it until it recovers, but does *not* terminate the container.

---

### Q10. What is the difference between a Deployment and a StatefulSet?
**Answer:**  
- **`Deployment`:** Designed for **stateless** workloads (e.g., Frontend, Product, Order APIs). Pods are interchangeable, have random generated names (`frontend-789-abc`), and share no unique identities or persistent ordered startup sequences.
- **`StatefulSet`:** Designed for **stateful** workloads (e.g., databases, distributed Kafka, ZooKeeper). Pods have stable, predictable ordinal names (`postgres-0`, `postgres-1`), ordered sequential rollout/termination, and dedicated per-pod persistent volume claims that remain bound across rescheduling.

---

### Q11. What is the difference between `PersistentVolume` (PV) and `PersistentVolumeClaim` (PVC)?
**Answer:**  
- **PersistentVolume (PV):** A piece of storage provisioned by an administrator or dynamically through a `StorageClass` (e.g., cloud disk, NFS share, host path). It is a cluster-level resource with a lifecycle independent of any individual pod.
- **PersistentVolumeClaim (PVC):** A user's request for storage with specific capacity and access modes (`ReadWriteOnce`, `ReadOnlyMany`, `ReadWriteMany`). It acts like a voucher that binds to a matching PV.

---

### Q12. Explain how Kubernetes performs Rolling Updates without zero downtime.
**Answer:**  
In a Deployment specification, the `.spec.strategy.rollingUpdate` defines:
- **`maxSurge`:** The maximum number of pods that can be created *above* the desired replica count during the update (e.g., `1`).
- **`maxUnavailable`:** The maximum number of pods that can be unavailable during the update (e.g., `0`).  
Kubernetes creates a new ReplicaSet with the new image, starts 1 new pod, waits for its Readiness Probe to pass, and only then terminates 1 old pod from the previous ReplicaSet. This guarantees continuous service availability.

---

### Q13. How does the Horizontal Pod Autoscaler (HPA) determine when to scale?
**Answer:**  
The HPA controller queries the Kubernetes **Metrics Server** every 15 seconds to calculate current vs target resource utilization using the formula:
$$\text{Desired Replicas} = \lceil \text{Current Replicas} \times \left( \frac{\text{Current Metric Value}}{\text{Target Metric Value}} \right) \rceil$$
For example, if target CPU is 50% and current CPU usage reaches 100% across 2 replicas:  
$\lceil 2 \times (100 / 50) \rceil = 4 \text{ replicas}$.

---

### Q14. What causes a `CrashLoopBackOff` status in Kubernetes, and how do you debug it?
**Answer:**  
`CrashLoopBackOff` indicates that a container started, exited with a non-zero code or crashed, was restarted by kubelet, and repeatedly crashed again, causing kubelet to introduce an exponential backoff delay before retrying.  
**Debugging steps:**
1. View container logs: `kubectl logs <pod-name> -n <namespace> --previous`
2. Inspect events: `kubectl describe pod <pod-name> -n <namespace>`
3. Check for missing environment variables, DB connection timeouts, or unhandled exceptions.

---

### Q15. What causes an `ImagePullBackOff` or `ErrImageNeverPull` status?
**Answer:**  
- **`ImagePullBackOff`:** The container runtime cannot pull the image from the registry due to an incorrect image name/tag, private repository without `imagePullSecrets`, or network failure.
- **`ErrImageNeverPull`:** The pod has `imagePullPolicy: Never` but the specified image does not exist in the local Docker daemon cache on that worker node.

---

### Q16. What is the difference between Kubernetes ConfigMaps and Secrets?
**Answer:**  
- **ConfigMap:** Stores non-confidential configuration key-value pairs (e.g., URLs, port numbers, log levels) in plain text.
- **Secret:** Designed for sensitive data (passwords, tokens, TLS certificates). Values are Base64-encoded by default in YAML and stored in `etcd` (which can be encrypted at rest). Pods mount them as environment variables or volume files.

---

### Q17. How does Kubernetes achieve "Self-Healing"?
**Answer:**  
The Kubernetes Controller Manager runs a continuous reconciliation loop:  
$\text{Reconcile}() : \text{Actual State} \to \text{Desired State}$  
If a worker node crashes or a pod is manually killed, the Deployment controller detects that the number of active pods is less than `.spec.replicas`. It immediately contacts the scheduler to assign and run new replacement pods on healthy nodes.

---

### Q18. What are `resources.requests` vs `resources.limits` in a Pod specification?
**Answer:**  
- **`requests`:** The minimum amount of CPU/Memory guaranteed to the container. The `kube-scheduler` uses this value to determine which node has enough unallocated capacity to schedule the pod.
- **`limits`:** The hard ceiling on resources the container can consume. If a container exceeds its memory limit, the Linux kernel terminates it with **`OOMKilled` (Exit code 137)**. If it exceeds its CPU limit, CPU throttling is applied.

---

### Q19. What is Docker Compose, and when should you use it over Kubernetes?
**Answer:**  
Docker Compose is a tool for defining and running multi-container Docker applications on a **single host engine** using a YAML file.  
- **Use Compose:** For local development, testing, and simple staging environments where multi-node clustering, dynamic autoscaling, and complex rollout orchestration are unnecessary.
- **Use Kubernetes:** For production multi-node clusters requiring high availability, distributed scheduling, self-healing, rolling upgrades, and horizontal scaling.

---

### Q20. What is Kustomize, and why is `kustomization.yaml` used?
**Answer:**  
Kustomize is a template-free configuration management tool built directly into `kubectl` (`kubectl apply -k <dir>`). It allows developers to customize application configurations, namespaces, labels, and image tags across multiple environments (Development, Staging, Production) without modifying the original base YAML files.

---

### Q21. Explain what happens during microservice-to-microservice communication in our project when an order is placed.
**Answer:**  
1. The user clicks "Place Order" on the browser UI (`frontend-service`).
2. The browser sends an AJAX POST to `/api/proxy/orders` on the frontend pod.
3. The frontend pod uses internal CoreDNS to resolve `http://order-service:5002` and forwards the order payload.
4. The `order-service` calls `http://product-service:5001/api/products/<id>/reserve` to validate and reserve item stock.
5. The `order-service` initiates a PostgreSQL connection to `postgres-service:5432`, inserts the order record into the `orders` table, and returns an HTTP 201 Created JSON response back up the call chain.

---

### Q22. What is a "Sidecar Container" pattern in Kubernetes?
**Answer:**  
A Sidecar container is a secondary helper container running in the same Pod alongside the main application container. It enhances or extends the main container's functionality without modifying the application code (e.g., logging agents like Fluentd, proxy sidecars like Envoy in Istio, or security token refreshers).

---

### Q23. What is the difference between Docker bridge network and Kubernetes pod networking?
**Answer:**  
In Docker on a single host, containers on a `bridge` network obtain private IPs (`172.17.x.x`) and require port mapping (`-p 80:80`) to communicate across hosts.  
In Kubernetes, the networking model dictates that **every Pod gets a unique, routable cluster IP address** and all Pods can communicate with all other Pods across different worker nodes without Network Address Translation (NAT), managed by a CNI plugin (e.g., Calico, Flannel, Cilium).

---

### Q24. How do you inspect real-time logs from all pods belonging to a deployment?
**Answer:**  
Using label selectors:  
```bash
kubectl logs -f -l app=order-service -n microservices-lab
```
Or for a specific pod:  
```bash
kubectl logs -f <pod-name> -n microservices-lab
```

---

### Q25. What is CI/CD and how does GitHub Actions automate Kubernetes deployment?
**Answer:**  
- **Continuous Integration (CI):** Automates code linting, static analysis, unit testing, and Docker image building upon every git push.
- **Continuous Deployment (CD):** Automatically delivers tested images to a container registry and applies declarative Kubernetes manifests (`kubectl apply`) to staging or production clusters, ensuring consistent, repeatable, human-error-free deployments.

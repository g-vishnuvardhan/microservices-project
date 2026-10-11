# 25 viva questions and answers

## 1. What problem does CloudMart solve?

It provides a working application for studying service communication, containerization, persistence and orchestration. Its storefront gives the infrastructure experiment a visible input and output.

## 2. What are the services?

Frontend serves the UI and forwards browser API calls. Product service supplies catalog data. Order service validates the cart and stores bills. PostgreSQL provides durable order storage.

## 3. Why use microservices instead of one application?

Different responsibilities can be deployed and scaled separately. The cost is more network communication, configuration and failure handling. A small real application may still be simpler as a monolith; this project separates services for learning.

## 4. What is the difference between a Docker image and a container?

An image packages filesystem layers and startup configuration. A container is a running or stopped instance created from an image. Multiple containers can use the same image with separate process state.

## 5. How does a multi-stage Dockerfile help here?

The builder downloads Python dependency wheels. The final image installs those wheels and copies application code without retaining the wheel directory. The stages separate build work from the runtime environment.

## 6. Why does the application run as a non-root user?

UID 10001 reduces the privileges available to a compromised application process. Kubernetes also drops capabilities and prevents privilege escalation. These controls reduce risk but do not replace application security.

## 7. What do namespaces and cgroups do?

Linux namespaces isolate views of resources such as process IDs and networking. Cgroups account for and constrain resource use. Containers share the host kernel, so they are not equivalent to separate full virtual machines.

## 8. What does Docker Compose do?

It defines and starts a group of containers, networks and volumes. This project uses health-dependent startup ordering. Compose does not implement Kubernetes Deployment reconciliation or HPA.

## 9. What is a Kubernetes pod?

A pod is the unit Kubernetes schedules. Containers within it share networking and can share volumes. CloudMart's application pods each contain one application container.

## 10. Why use a Deployment?

A Deployment manages ReplicaSets and desired application replicas, supports rolling updates and replaces missing pods. A manually created pod does not provide the same higher-level lifecycle management.

## 11. Deployment versus StatefulSet?

Deployments suit replaceable application replicas. StatefulSets provide stable identities and storage relationships useful for stateful workloads. Our single PostgreSQL Deployment with Recreate is a deliberately simple lab choice, not a full database failover design.

## 12. What is a Kubernetes Service?

It gives matching pods a stable access point while individual pod addresses change. Selectors connect the Service to labelled pods. A matching label and a ready endpoint are necessary for routing.

## 13. ClusterIP, NodePort and LoadBalancer?

ClusterIP exposes an internal service endpoint. NodePort adds a port on nodes. LoadBalancer asks supported infrastructure for external load-balancing resources. This lab keeps backends internal and exposes the frontend through NodePort.

## 14. How do services discover each other?

Container/cluster networking supplies name resolution. The frontend uses `product-service:5001` and `order-service:5002`. The browser never needs to resolve those internal names.

## 15. Liveness versus readiness versus startup probes?

Readiness controls whether a pod receives Service traffic. Liveness can trigger a container restart. Startup probes allow initialization to finish before the other probes operate. Order readiness checks database availability; process liveness avoids restarting the service merely because a dependency is temporarily down.

## 16. How does self-healing work?

The Deployment's controllers reconcile the desired replica count after a pod disappears. This is a replacement of process instances, not automatic recovery of every application-level error or lost data.

## 17. Does refreshing guarantee the next pod handles a request?

No. Connection reuse, session routing and the networking implementation can repeat a destination. Compare actual host responses over multiple requests and use kubectl as the authority for pod identities.

## 18. ConfigMap versus Secret?

ConfigMaps hold non-sensitive configuration. Secrets are intended for sensitive values and allow separate handling and access controls. Base64 representation is not encryption; protect cluster access and configure suitable storage encryption.

## 19. PV versus PVC, and why does order data survive a restart?

A PV represents storage available to the cluster. A PVC requests compatible storage. PostgreSQL mounts the claim, so replacing its pod does not inherently erase the stored files. Deleting the claim may lead to storage deletion, depending on reclaim policy.

## 20. Does persistent storage mean high availability?

No. Persistence protects data across supported lifecycle events. High availability also requires service continuity and failover. The single database replica may be temporarily unavailable during a restart.

## 21. How does HPA work here?

It changes application replica counts using measured CPU utilization relative to requested CPU. The supplied policies allow 2–5 replicas at a 50% target. Metrics Server and sustained load are prerequisites, and scaling is not immediate or guaranteed.

## 22. Requests versus limits?

Requests help the scheduler reserve capacity and provide HPA's CPU baseline. Limits constrain allowed resource use. CPU can be throttled; exceeding memory capacity can terminate a container. Choose values using actual measurements.

## 23. Why calculate prices on the server?

Users can edit browser data. The order service therefore fetches authoritative catalog prices and uses Decimal for totals. It ignores client-supplied prices and rejects unknown IDs or invalid quantities.

## 24. How do you avoid duplicate orders?

The client sends a request key and retains it if a response fails. A unique database key returns the original order on a retry. A cart fingerprint prevents a different cart from reusing that key. This protects checkout retries, but it is not a general distributed transaction system.

## 25. What have you verified, and what would production need?

The local app passed 14 automated tests and a live checkout smoke test using SQLite. Docker/Kubernetes runtime verification was blocked by unavailable local infrastructure during development. Production would need authentication, transactional stock reservation, HTTPS, backups, monitoring and a controlled delivery environment. Report real college cluster results after performing the lab.

## Further reading

See the official references in LAB_MANUAL.md. For the exact demonstration sequence and commands, use DEMO_GUIDE.md.

# Architecture Changes: trustyai-service

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Original row lacked auth mechanism; source inspection reveals kube-rbac-proxy delegation and dual-port architecture | src/main.py:259, src/main.py:267-268 |
| add | authentication | HTTP API (port 8080) :: All | * | <empty> | <empty> | HTTP port bound to 127.0.0.1 loopback only, fronted by kube-rbac-proxy for Kubernetes RBAC authentication | src/main.py:259, src/main.py:267-268 |
| add | authentication | HTTPS API (port 4443) :: All | * | <empty> | <empty> | Optional HTTPS listener on 0.0.0.0 with TLS certificates for direct access | src/main.py:262, src/main.py:276-280 |
| add | integration_points | KServe/ModelMesh inference services :: REST (inbound) | * | <empty> | <empty> | Consumer endpoint receives KServe v2 inference payloads for reconciliation and storage | src/endpoints/consumer/consumer_endpoint.py:65-81 |
| add | integration_points | MariaDB :: SQL client (outbound) | * | <empty> | <empty> | Optional persistent storage backend with TLS support, configured via SERVICE_STORAGE_FORMAT | src/service/data/storage/__init__.py:59-108 |
| add | integration_points | kube-rbac-proxy :: HTTP proxy (inbound) | * | <empty> | <empty> | Platform auth proxy authenticates requests before forwarding to loopback-bound service | src/main.py:259, src/main.py:267-268 |
| add | integration_points | Prometheus :: HTTP scrape (inbound) | * | <empty> | <empty> | Metrics endpoint at /q/metrics serves Prometheus-format fairness and drift metrics | src/main.py:197-204 |
| add | internal_dependencies | kube-rbac-proxy | * | <empty> | <empty> | HTTP port bound to loopback with explicit comment referencing kube-rbac-proxy forwarding | src/main.py:259, src/main.py:267-268 |
| add | internal_dependencies | KServe/ModelMesh | * | <empty> | <empty> | Consumer endpoint implements KServe v2 protocol for receiving inference payloads | src/endpoints/consumer/consumer_endpoint.py:65-81 |

# Architecture Changes: trustyai-service

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Row key changed: HTTP API split into loopback and direct HTTPS interfaces with distinct auth models | src/main.py:257-262 |
| add | authentication | HTTP API (loopback) :: All | * | <empty> | <empty> | HTTP binds to 127.0.0.1:8080 with kube-rbac-proxy as authentication sidecar; code comment explicitly states "kube-rbac-proxy forwards here" | src/main.py:259 |
| add | authentication | HTTPS API (direct) :: All | * | <empty> | <empty> | Optional HTTPS on 0.0.0.0:4443 with TLS termination when certificates are mounted; no app-level auth middleware | src/main.py:276-280 |
| add | integration_points | MariaDB :: Database client | * | <empty> | <empty> | MariaDB is an optional persistent storage backend configured via SERVICE_STORAGE_FORMAT environment variable | src/service/data/storage/__init__.py:60-109 |
| add | integration_points | ModelMesh/KServe :: HTTP inbound | * | <empty> | <empty> | Service receives KServe v2 inference payloads at /consumer/kserve/v2 for model monitoring | src/endpoints/consumer/consumer_endpoint.py:66-100 |
| add | integration_points | kube-rbac-proxy :: Sidecar proxy | * | <empty> | <empty> | HTTP bound to loopback only with code comment referencing kube-rbac-proxy forwarding | src/main.py:259 |
| add | internal_dependencies | kube-rbac-proxy | * | <empty> | <empty> | Authentication sidecar; HTTP listener bound to 127.0.0.1 with explicit kube-rbac-proxy reference | src/main.py:259 |
| add | internal_dependencies | ModelMesh/KServe | * | <empty> | <empty> | Inference data source providing KServe v2 payloads to consumer endpoint | src/endpoints/consumer/consumer_endpoint.py:66 |
| add | internal_dependencies | MariaDB | * | <empty> | <empty> | Optional database backend for persistent inference observation storage | src/service/data/storage/__init__.py:60-109 |

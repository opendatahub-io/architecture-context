# Architecture Changes: codeflare-sdk

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Analyzer row is a false positive from test infrastructure file; codeflare-sdk is a client SDK, not a web server | src/codeflare_sdk/common/kubernetes_cluster/auth.py:30 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | SDK authenticates to Kubernetes API server using kube-authkit with auto-detection, kubeconfig, in-cluster, and Bearer token strategies | src/codeflare_sdk/common/kubernetes_cluster/auth.py:30-31, src/codeflare_sdk/common/kubernetes_cluster/auth.py:257-263 |
| add | authentication | Ray Dashboard :: All | * | <empty> | <empty> | RayJobClient connects to Ray Dashboard with configurable HTTP headers, cookies, and TLS verification | src/codeflare_sdk/ray/client/ray_jobs.py:43-67 |
| add | internal_dependencies | Kueue | * | <empty> | <empty> | SDK manages Kueue LocalQueue and ClusterQueue resources for queue-aware batch scheduling | src/codeflare_sdk/common/kueue/__init__.py:1-6 |
| add | internal_dependencies | kube-authkit | * | <empty> | <empty> | Mandatory authentication dependency for Kubernetes API auto-detection and credential management | src/codeflare_sdk/common/kubernetes_cluster/auth.py:30, pyproject.toml:45 |
| add | integration_points | Kueue :: Kubernetes CustomObjects API | * | <empty> | <empty> | SDK queries and manages Kueue queue resources through Kubernetes CustomObjects API | src/codeflare_sdk/common/kueue/__init__.py:1-6 |
| update | integration_points | Kubernetes API :: Python client library | Encryption | Unknown | TLS (configurable) | SDK enforces TLS by default with configurable CA cert paths; skip_tls option available for legacy auth | src/codeflare_sdk/common/kubernetes_cluster/auth.py:144-151, src/codeflare_sdk/common/kubernetes_cluster/auth.py:305-311 |
| update | integration_points | Ray :: Python client library | Encryption | Unknown | TLS (configurable) | RayJobClient verify parameter defaults to True; TLS is configurable | src/codeflare_sdk/ray/client/ray_jobs.py:47-48, src/codeflare_sdk/ray/client/ray_jobs.py:58-67 |

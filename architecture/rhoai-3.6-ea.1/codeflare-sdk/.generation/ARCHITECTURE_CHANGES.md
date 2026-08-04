# Architecture Changes: codeflare-sdk

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | False positive from test helper file; SDK is a client library that does not serve HTTP endpoints | src/codeflare_sdk/common/kubernetes_cluster/test_kube_api_helpers.py:62 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | SDK authenticates to Kubernetes API server via kube-authkit with Bearer token, kubeconfig, or in-cluster strategies and TLS certificate verification | src/codeflare_sdk/common/kubernetes_cluster/auth.py:30-31, src/codeflare_sdk/common/kubernetes_cluster/auth.py:257-264 |
| add | integration_points | Kueue :: Kubernetes Custom Resource API | * | <empty> | <empty> | SDK queries Kueue LocalQueues and WorkloadPriorityClasses via kueue.x-k8s.io/v1beta1 CustomObjects API for queue management and scheduling | src/codeflare_sdk/common/kueue/kueue.py:41-46, src/codeflare_sdk/common/kueue/kueue.py:186-190 |
| add | internal_dependencies | Kueue | * | <empty> | <empty> | SDK queries Kueue custom resources for local queue discovery, default queue resolution, and workload priority class validation | src/codeflare_sdk/common/kueue/kueue.py:41-46, src/codeflare_sdk/common/kueue/kueue.py:186-190 |
| add | internal_dependencies | kube-authkit | * | <empty> | <empty> | Mandatory dependency providing Kubernetes authentication abstraction with auto-detection, token, and kubeconfig strategies | src/codeflare_sdk/common/kubernetes_cluster/auth.py:30, pyproject.toml:45 |
| add | internal_dependencies | openshift-client | * | <empty> | <empty> | OpenShift-specific Kubernetes client operations dependency | pyproject.toml:37 |
| add | internal_dependencies | cryptography | * | <empty> | <empty> | TLS certificate generation for Ray cluster mTLS using RSA-3072 keys and SHA-256 signing | src/codeflare_sdk/common/utils/generate_cert.py:21-24, pyproject.toml:41 |

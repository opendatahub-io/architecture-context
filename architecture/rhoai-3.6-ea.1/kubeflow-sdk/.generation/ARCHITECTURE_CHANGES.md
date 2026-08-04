# Architecture Changes: kubeflow-sdk

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| delete | authentication | HTTP API :: All | * | <empty> | <empty> | Analyzer detected HTTP endpoint from test file mock server; SDK is a client library with no application server or auth middleware | kubeflow/trainer/backends/kubernetes/backend.py:50-57 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | SDK authenticates to Kubernetes API via kubernetes Python client load_kube_config or load_incluster_config; this is the actual authentication surface | kubeflow/trainer/backends/kubernetes/backend.py:50-57, kubeflow/common/types.py:20-27 |
| add | internal_dependencies | kubeflow-trainer-api | * | <empty> | <empty> | Core direct dependency declared in pyproject.toml providing Trainer custom resource model definitions | pyproject.toml:31 |
| add | internal_dependencies | kubeflow-katib-api | * | <empty> | <empty> | Core direct dependency declared in pyproject.toml providing Katib custom resource model definitions | pyproject.toml:32 |

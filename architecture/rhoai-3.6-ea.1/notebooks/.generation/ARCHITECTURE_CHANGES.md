# Architecture Changes: notebooks

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | authentication | JupyterLab UI :: All | * | <empty> | <empty> | Platform-delegated authentication via oauth-proxy sidecar injected by odh-notebook-controller; notebook container has no built-in auth middleware | jupyter/utils/jupyter_server_config.py:1, jupyter/minimal/ubi9-python-3.12/start-notebook.sh:47 |
| add | integration_points | Kubernetes API :: REST client library | * | <empty> | <empty> | Pre-installed kubernetes Python client library enables user-invoked cluster API access from notebooks | codeserver/ubi9-python-3.12/requirements.cpu.txt:270 |
| add | integration_points | KubeFlow Pipelines :: REST client library | * | <empty> | <empty> | Pre-installed kfp SDK enables pipeline submission from notebooks | codeserver/ubi9-python-3.12/requirements.cpu.txt:322 |
| add | integration_points | S3-compatible storage :: REST client library | * | <empty> | <empty> | Pre-installed boto3 enables object storage access from notebooks | codeserver/ubi9-python-3.12/requirements.cpu.txt:108 |
| add | integration_points | MLflow Tracking :: REST client library | * | <empty> | <empty> | Pre-installed mlflow enables experiment tracking from notebooks | codeserver/ubi9-python-3.12/requirements.cpu.txt:350 |
| add | integration_points | CodeFlare :: REST client library | * | <empty> | <empty> | Pre-installed codeflare-sdk enables distributed computing job submission from notebooks | codeserver/ubi9-python-3.12/requirements.cpu.txt:118 |
| add | internal_dependencies | odh-notebook-controller | * | <empty> | <empty> | Controller reconciles Notebook CRs into pods using these images and injects oauth-proxy sidecar | manifests/rhoai/base/kustomization.yaml:46 |
| add | internal_dependencies | RHOAI Dashboard | * | <empty> | <empty> | Dashboard discovers available notebook images via labeled ImageStreams | manifests/rhoai/base/kustomization.yaml:46 |

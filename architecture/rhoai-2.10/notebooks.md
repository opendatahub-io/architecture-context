# Component: Notebook Workbench Images

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-637-gf19592cf5
- **Branch**: rhoai-2.10
- **Distribution**: RHOAI (with upstream ODH counterpart at opendatahub-io/notebooks)
- **Languages**: Python 3.8, Python 3.9, R 4.3, Shell, Dockerfile
- **Deployment Type**: Container Image Repository

## Purpose
**Short**: Pre-built container images for Jupyter notebooks, RStudio Server, and VS Code Server workbenches in RHOAI/ODH data science platform.

**Detailed**: This repository provides a collection of OCI container images that serve as workbench environments for data scientists working in Red Hat OpenShift AI. The images are built in a layered architecture starting from base UBI/RHEL images, progressing through minimal Jupyter installations, to specialized data science images with frameworks like TensorFlow, PyTorch, and TrustAI. These images include pre-installed Python libraries, ML frameworks, and development tools optimized for specific use cases (general data science, GPU acceleration, specialized hardware like Habana Gaudi, Intel GPU). The repository also includes "runtime" variants designed for Elyra pipeline execution, which are lightweight images containing only the necessary dependencies to run notebooks in automated pipelines. Images follow a twice-yearly major release cycle (e.g., 2024a, 2024b) with weekly security patch updates, ensuring both stability and security compliance.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images (UBI8/UBI9/RHEL9/C9S) | Container Base Layer | Foundation images with Python runtime, oc CLI, and core system packages |
| Jupyter Minimal | JupyterLab Environment | Minimal JupyterLab 3.x installation with notebook server and Python kernel |
| Jupyter Data Science | Enhanced Workbench | Extended notebook with data science libraries (pandas, scikit-learn, matplotlib) |
| Jupyter Specialized (PyTorch/TensorFlow/TrustAI) | Framework-Specific Workbench | Domain-specific images with ML frameworks and optimized dependencies |
| CUDA Images | GPU-Accelerated Workbench | NVIDIA CUDA-enabled base and notebook images for GPU compute |
| Habana Images | Gaudi-Accelerated Workbench | Intel Habana Gaudi AI accelerator support (versions 1.9-1.13) |
| Intel GPU Images | Intel Arc/Flex GPU Workbench | Intel GPU acceleration for PyTorch, TensorFlow, and general ML |
| Code Server | VS Code IDE | VS Code Server for browser-based IDE experience |
| RStudio Server | R IDE | RStudio Server 4.3 for R programming and statistical computing |
| Runtime Images | Pipeline Execution | Lightweight images for Elyra pipeline execution without full IDE |
| ImageStream Manifests | OpenShift Deployment | Kustomize-based deployment manifests for image registration in OpenShift |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It produces container images that are referenced by OpenShift ImageStreams and consumed by the ODH Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/ | GET/POST | 8888/TCP | HTTP | None (internal) | Token-based (disabled in ODH) | JupyterLab web interface |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None (internal) | Token-based (disabled in ODH) | JupyterLab REST API for notebook operations |
| /notebook/{namespace}/{username}/lab | GET | 8888/TCP | HTTP | None (internal) | Token-based (disabled in ODH) | JupyterLab UI entry point |
| /notebook/{namespace}/{username}/terminals/websocket/* | WebSocket | 8888/TCP | WS | None (internal) | Token-based (disabled in ODH) | Terminal websocket connections |
| / (Code Server) | GET | 8080/TCP | HTTP | None (internal) | None | VS Code Server web interface |
| / (RStudio) | GET | 8787/TCP | HTTP | None (internal) | None | RStudio Server web interface |

**Note**: Notebook containers run as internal ClusterIP services. Encryption and authentication are enforced at the ingress layer by OAuth Proxy sidecars and Istio/OpenShift Route, not within the container.

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9 Python 3.9 Base Image | registry.access.redhat.com/ubi9/python-39@sha256:bbac8c29fb0f834f616b3ec07aa78d942a6e4239a5537a52517acaff59350917 | Yes | Base OS and Python runtime for UBI9 images |
| UBI8 Python 3.8 Base Image | registry.access.redhat.com/ubi8/python-38 | Yes | Base OS and Python runtime for UBI8 images |
| JupyterLab | 3.2-3.6 | Yes (Jupyter images) | Web-based notebook IDE |
| Notebook | 6.4-6.5 | Yes (Jupyter images) | Classic Jupyter Notebook interface |
| TensorFlow | 2.x | No (specialized images) | Deep learning framework |
| PyTorch | 2.x | No (specialized images) | Deep learning framework |
| CUDA Toolkit | 11.x-12.x | No (GPU images) | NVIDIA GPU acceleration libraries |
| Intel Extension for TensorFlow | Latest | No (Intel images) | Intel GPU acceleration for TensorFlow |
| Intel Extension for PyTorch | Latest | No (Intel images) | Intel GPU acceleration for PyTorch |
| Habana SynapseAI SDK | 1.9.0-1.13.0 | No (Habana images) | Intel Habana Gaudi accelerator SDK |
| Code Server | 4.x | Yes (Code Server images) | VS Code Server |
| RStudio Server | 4.3 | Yes (RStudio images) | RStudio Server for R |
| OpenShift CLI (oc) | stable | Yes | Kubernetes/OpenShift cluster interaction from notebooks |
| Elyra | 3.x | No (runtime images) | AI pipeline orchestration for KFP/Airflow |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Consumed by | Controller launches workbenches using these images via StatefulSets |
| ODH Dashboard | Consumed by | Dashboard presents ImageStreams to users for workbench selection |
| JupyterHub (optional) | Consumed by | Alternative notebook spawner that can use these images |
| Kubeflow Pipelines | Consumed by | Runtime images used as pipeline step containers |
| Model Mesh / KServe | Data flow | Notebooks train/prepare models deployed to serving layer |
| S3 Storage (Minio/AWS) | Data access | Notebooks read/write datasets and models to object storage |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {workbench-name}-notebook | ClusterIP | 8888/TCP | notebook-port (8888) | HTTP | None | None (OAuth Proxy handles auth) | Internal only |
| {codeserver-name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | None (OAuth Proxy handles auth) | Internal only |
| {rstudio-name} | ClusterIP | 8787/TCP | 8787 | HTTP | None | None (OAuth Proxy handles auth) | Internal only |

**Note**: Services are created per-user workbench instance with names prefixed by workbench identifier. Actual service creation is handled by ODH Notebook Controller, not by these images directly.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {workbench-name} | OpenShift Route | {workbench-name}-{namespace}.apps.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Reencrypt | External (authenticated) |

**Note**: Routes are created by ODH Notebook Controller with OAuth Proxy sidecar for authentication. Notebook containers themselves communicate over plain HTTP internally.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | oc CLI commands from notebooks |
| Quay.io / Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull base images during builds |
| PyPI / Conda Repos | 443/TCP | HTTPS | TLS 1.2+ | None | Install additional Python packages at runtime |
| S3 Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 / IAM | Read/write datasets and model artifacts |
| Git Repositories (GitHub/GitLab) | 443/TCP | HTTPS | TLS 1.2+ | SSH Key / Token | Clone repositories into workspace |
| External ML APIs | 443/TCP | HTTPS | TLS 1.2+ | API Key | Access external ML services from notebooks |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. RBAC for workbench pods is managed by ODH Notebook Controller, which assigns ServiceAccounts to pods based on user permissions.

### RBAC - Role Bindings

This component does not define RoleBindings. Per-user workbenches receive ServiceAccounts with minimal permissions (typically default ServiceAccount) at pod creation time.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription credentials for RStudio builds | Administrator | No |
| notebook-{username}-oauth-config | Opaque | OAuth proxy configuration for authentication | ODH Notebook Controller | No |
| {user-git-credentials} | kubernetes.io/ssh-auth | Git SSH keys for repository access | User via Dashboard | No |
| {user-aws-credentials} | Opaque | AWS credentials for S3 access | User via Dashboard | No |

**Note**: These secrets are consumed by, but not created by, the notebook images. Secret management is external to this component.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | GET, POST, WebSocket | OAuth2 Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | User must be authenticated and authorized for namespace |
| Internal JupyterLab API | ALL | None (token disabled) | N/A | Trust within pod network |

**Security Notes**:
- JupyterLab token authentication is explicitly disabled (`--ServerApp.token='' --ServerApp.password=''`) as authentication is handled by OAuth Proxy sidecar
- Notebooks run as non-root user (UID 1001) with restricted capabilities
- Images use minimal base images (UBI) scanned for vulnerabilities
- Weekly security patch updates applied to all supported image releases
- Pod Security Standards: Restricted profile compatible (non-root, no privilege escalation)

## Data Flows

### Flow 1: User Accesses Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | Session Cookie |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 3 | OAuth Proxy Sidecar | JupyterLab Container | 8888/TCP | HTTP | None | None (trusted pod network) |
| 4 | JupyterLab Container | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Notebook Reads/Writes Data to S3

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | JupyterLab (boto3/s3fs) | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 (from secret) |

### Flow 3: Elyra Pipeline Execution (Runtime Image)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Elyra in Jupyter | KFP API Server | 443/TCP | HTTPS | TLS 1.2+ | Bearer Token |
| 2 | KFP | Runtime Image Pod | N/A | N/A | N/A | N/A (creates pod) |
| 3 | Runtime Image Pod | S3 (input data) | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 |
| 4 | Runtime Image Pod | S3 (output artifacts) | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 |

### Flow 4: Image Build and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Konflux/CI | Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Registry Token |
| 2 | GitHub Actions | Quay.io (push) | 443/TCP | HTTPS | TLS 1.2+ | Robot Account |
| 3 | OpenShift ImageStream | Quay.io (import) | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Image Reference | N/A | N/A | N/A | Controller creates StatefulSets using these images |
| ODH Dashboard | ImageStream Query | N/A | Kubernetes API | N/A | Dashboard reads ImageStreams to present workbench options |
| Kubeflow Pipelines | Container Execution | N/A | N/A | N/A | Runtime images execute as pipeline step containers |
| OpenShift BuildConfig | Build Trigger | N/A | N/A | N/A | RStudio images built in-cluster from Git source |
| Quay.io Registry | Image Pull/Push | 443/TCP | HTTPS | TLS 1.2+ | Image distribution and storage |
| GitHub Repository | Source Code | 443/TCP | HTTPS | TLS 1.2+ | Build source for BuildConfigs |

## Build Chain Architecture

### UBI9 Python 3.9 Chain

```
base-ubi9-python-3.9
├── jupyter-minimal-ubi9-python-3.9
│   ├── jupyter-datascience-ubi9-python-3.9
│   │   ├── jupyter-pytorch-ubi9-python-3.9 (CUDA variant)
│   │   ├── jupyter-tensorflow-ubi9-python-3.9 (CUDA variant)
│   │   └── jupyter-trustyai-ubi9-python-3.9
├── codeserver-ubi9-python-3.9
├── runtime-minimal-ubi9-python-3.9
├── runtime-datascience-ubi9-python-3.9
├── runtime-pytorch-ubi9-python-3.9
└── runtime-tensorflow-ubi9-python-3.9 (CUDA base)
```

### CUDA GPU Chain

```
cuda-ubi9-python-3.9 (base + NVIDIA CUDA)
├── cuda-jupyter-minimal-ubi9-python-3.9
│   └── cuda-jupyter-datascience-ubi9-python-3.9
│       ├── cuda-jupyter-tensorflow-ubi9-python-3.9
│       └── cuda-jupyter-pytorch-ubi9-python-3.9
└── runtime-cuda-tensorflow-ubi9-python-3.9
```

### Intel GPU Chain

```
intel-base-gpu-ubi9-python-3.9
├── intel-runtime-tensorflow-ubi9-python-3.9
│   └── jupyter-intel-tensorflow-ubi9-python-3.9
├── intel-runtime-pytorch-ubi9-python-3.9
│   └── jupyter-intel-pytorch-ubi9-python-3.9
└── intel-runtime-ml-ubi9-python-3.9
    └── jupyter-intel-ml-ubi9-python-3.9
```

### Habana Gaudi Chain

```
jupyter-datascience-ubi8-python-3.8
├── habana-jupyter-1.9.0-ubi8-python-3.8
├── habana-jupyter-1.10.0-ubi8-python-3.8
├── habana-jupyter-1.11.0-ubi8-python-3.8
└── habana-jupyter-1.13.0-ubi8-python-3.8
```

## Release and Update Cadence

| Release Type | Frequency | Scope | Example Version |
|--------------|-----------|-------|-----------------|
| Major Release | Twice yearly (Spring/Fall) | MAJOR.MINOR version updates to all components | 2024a, 2024b |
| Patch Release | Weekly | PATCH version updates for security fixes only | 2024a-20240315 |
| Support Window | 12 months minimum | Two major releases supported concurrently | 2024a and 2024b both supported |
| Weekly Tag | Continuous | Latest patched version of release | 2024a-weekly |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| f19592cf5 | 2024-03 | - Merge RHOAIENG-13414: Deactivate Habana notebook from manifests |
| 247ecd235 | 2024-03 | - Deactivate Habana notebook from manifests and repository docs |
| bfc8e3a5c | 2024-02 | - [RHOAIENG-11695] Fix critical CVEs in jupyter-server-proxy package |
| 2984fbe27 | 2024-02 | - Backport kustomize version pinning to rhoai-2.10 |
| bb9c26af9 | 2024-02 | - [GHA] Pin kustomize version in tests to specific version |
| ad95d2901 | 2024-01 | - [RHOAIENG-9258] Backport fix for PyTorch notebook |
| a274ef07f | 2024-01 | - Backport PyTorch notebook fixes |
| 2d4e3f757 | 2024-01 | - Run static code checks on push and manual trigger |
| 858ea6789 | 2024-01 | - Update static code quality checks |
| 51a1bd188 | 2023-12 | - [RHOAIENG-8255] Fix spawn-fcgi RPM download location |
| 58dbb6501 | 2023-12 | - Merge upstream main into rhoai-2.10 branch |
| ac9c50418 | 2023-11 | - Add Hadolint linting for Dockerfiles |
| 2d4642c01 | 2023-11 | - Rsync from upstream main branch |
| 81b637d12 | 2023-11 | - Merge upstream main repository changes |
| afab4cfc6 | 2023-10 | - Check commit IDs in ImageStream definitions |
| 876b7244d | 2023-10 | - Add kustomize validation in CI |
| 1a1db8438 | 2023-10 | - ODH sync updater automation |
| a5ec851f2 | 2023-10 | - Update CodeFlare dependencies |
| 141cf60e1 | 2023-10 | - Update ODH notebooks maintainer list |
| 60d955aae | 2023-09 | - Merge remote tracking from upstream main |

## Image Registry Locations

| Image Family | Registry | Repository | Example Tag |
|--------------|----------|------------|-------------|
| RHOAI Notebooks | quay.io/modh | odh-minimal-notebook-container | sha256:0bac29a185f2d14ac43267529178ccba2cd327c23563a9c5d81db855f8e6c5ed |
| RHOAI Data Science | quay.io/modh | odh-generic-data-science-notebook | sha256:3c742712ca5a398199e202009bc57b6c1456de8d5b30eec07493132b93c296ae |
| RHOAI CUDA | quay.io/modh | cuda-notebooks | sha256:3beed917f90b12239d57cf49c864c6249236c8ffcafcc7eb06b0b55272ef5b55 |
| RHOAI PyTorch | quay.io/modh | odh-pytorch-notebook | sha256:354f98690a02c5b2519da72be22555562c6652bc9db8ece2f3c03476fd6369ff |
| RHOAI TrustAI | quay.io/modh | odh-trustyai-notebook | sha256:6756ea9be23349b2ad748864217d0867e7ff8213d91a93ec422c8276c5b63366 |
| RHOAI Habana | quay.io/modh | odh-habana-notebooks | sha256:64ca5d31d1d0d305bc99317eb9d453ce5fa8571f0311e171252df12b40c41b75 |
| RHOAI Code Server | quay.io/modh | codeserver | sha256:3f1b86feed5ee437663ff1088471ccca1ba164b45b2bb4443a8d37a587e95e91 |
| Upstream ODH | quay.io/opendatahub | workbench-images | jupyter-minimal-ubi9-python-3.9-2024a-20240317 |

## Deployment Architecture

### ImageStream Pattern (Kustomize)

The repository provides two deployment patterns:

1. **Per-Image Test Deployment**: Each notebook variant has `kustomize/base/` with Service + StatefulSet for standalone testing
2. **Production Deployment**: `manifests/base/` contains ImageStream definitions for production OpenShift clusters

**Production Flow**:
```
manifests/base/kustomization.yaml
├── jupyter-minimal-notebook-imagestream.yaml (defines ImageStream with 4 version tags)
├── jupyter-datascience-notebook-imagestream.yaml
├── jupyter-pytorch-notebook-imagestream.yaml
├── jupyter-tensorflow-notebook-imagestream.yaml
├── jupyter-trustyai-notebook-imagestream.yaml
├── jupyter-habana-notebook-imagestream.yaml
├── code-server-notebook-imagestream.yaml
├── rstudio-buildconfig.yaml (BuildConfig + ImageStream for RStudio)
└── params.env (ConfigMap with image SHAs)
```

**Test/Development Flow**:
```
jupyter/minimal/ubi9-python-3.9/kustomize/base/
├── kustomization.yaml
├── service.yaml (ClusterIP on port 8888)
└── statefulset.yaml (1 replica, user 'jovyan')
```

### Container Runtime Configuration

| Parameter | Value | Purpose |
|-----------|-------|---------|
| User | 1001 (non-root) | Security: run as non-privileged user |
| Working Directory | /opt/app-root/src | User workspace for notebooks and data |
| Entrypoint | start-notebook.sh | Launch JupyterLab with configuration |
| Port | 8888/TCP | JupyterLab web server |
| Base URL | /notebook/{namespace}/{username} | Multi-tenant path isolation |
| Root Dir | ${HOME} | Notebook file browser root |
| Allow Origin | * | CORS configuration (safe behind OAuth proxy) |
| Quit Button | False | Prevent users from shutting down managed workbench |

## Quality and Security Scanning

### Automated Checks

| Check Type | Tool | Frequency | Purpose |
|------------|------|-----------|---------|
| Container Vulnerability Scan | Quay Security Scanner | On push | Detect CVEs in image layers |
| Python Dependency Audit | Pipenv / pip-audit | Weekly | Identify vulnerable Python packages |
| Dockerfile Linting | Hadolint | On PR | Enforce Dockerfile best practices |
| Runtime Image Validation | Custom Script (skopeo) | On PR | Verify runtime images meet Elyra requirements |
| Params.env Validation | Custom Script | On PR | Ensure image SHAs exist in registry |
| JSON Schema Validation | jq | On PR | Validate ImageStream JSON structure |

### Required Runtime Image Capabilities

Runtime images (used in Elyra pipelines) must include:
- `curl` - HTTP client for artifact download
- `python3` - Python runtime
- Ability to execute notebooks via `papermill`
- Ability to install packages from `requirements-elyra.txt`

## Testing Strategy

| Test Type | Scope | Execution |
|-----------|-------|-----------|
| Papermill Notebook Execution | Functional test notebooks in each image variant | OpenShift CI (post-merge) |
| API Health Check | HTTP GET to `/notebook/{namespace}/jovyan/api` | Make targets (test-%) |
| Runtime Image Validation | Check for required commands (curl, python3) | Make target (validate-runtime-image) |
| Code Server Validation | Check for code-server, oc, curl, python | Make target (validate-codeserver-image) |
| RStudio Validation | Check for RStudio Server, R package installation | Make target (validate-rstudio-image) |

## Known Limitations

1. **Authentication**: JupyterLab token/password auth is disabled; relies entirely on OAuth Proxy sidecar
2. **Encryption**: Notebooks communicate over HTTP internally; HTTPS termination at ingress only
3. **Multi-user**: Each user gets isolated workbench pod; no shared JupyterHub-style multi-user notebook
4. **Resource Constraints**: Default requests/limits (500m CPU, 2Gi memory) may be insufficient for large workloads
5. **Storage**: No persistent volume attached by default; notebooks use ephemeral storage unless PVC configured
6. **Habana Support**: Habana images deactivated in RHOAI 2.10 manifests (recent change)
7. **Package Installation**: Users can `pip install` packages at runtime, but changes are lost on pod restart unless using persistent volume

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Notebook won't start | Pod stuck in Pending/CrashLoopBackOff | Check image pull errors, resource quotas, node capacity |
| Cannot install packages | `pip install` fails with permission errors | Ensure `/opt/app-root/lib/python3.9/site-packages` has group write permissions (should be fixed in images) |
| OAuth redirect loop | User cannot access notebook UI | Verify OAuth proxy configuration, check Route/Ingress configuration |
| Notebook server exits | Pod logs show "Quit button pressed" | This shouldn't happen (quit button disabled); check if configuration override present |
| Missing oc command | `oc` not found in PATH | Verify image build completed successfully; `oc` should be in `/opt/app-root/bin` |
| S3 access fails | boto3 raises credential errors | Check AWS credentials secret mounted correctly, verify IAM permissions |

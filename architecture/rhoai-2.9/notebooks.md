# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-555-gf34daccaf
- **Branch**: rhoai-2.9
- **Distribution**: ODH and RHOAI
- **Languages**: Python, Shell, Dockerfile
- **Deployment Type**: Container Images / Workbenches

## Purpose
**Short**: Provides pre-configured notebook and IDE workbench container images for data science and ML workflows in OpenShift.

**Detailed**: The notebooks repository is a collection of container images that provide browser-based integrated development environments (IDEs) for data scientists and ML engineers. These workbench images include JupyterLab notebooks, VS Code Server, and RStudio Server, each tailored for different use cases ranging from minimal Python environments to GPU-accelerated deep learning with TensorFlow and PyTorch. The images are designed to run in OpenShift environments and integrate with the ODH/RHOAI platform ecosystem, including support for Elyra pipelines, model development, and specialized hardware accelerators (NVIDIA CUDA, Intel GPU, Habana Gaudi). Images are published to quay.io/modh/ registry and deployed via OpenShift ImageStreams, with versioned releases (N, N-1, N-2) maintained for compatibility.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image | Foundation UBI8/9, C9S, RHEL9, Anaconda Python images with core dependencies |
| Jupyter Minimal | Container Image | Lightweight JupyterLab environment with Python 3.8/3.9 |
| Jupyter Data Science | Container Image | JupyterLab with ML libraries, database clients, and data science tools |
| Jupyter TensorFlow | Container Image | JupyterLab with TensorFlow framework for deep learning |
| Jupyter PyTorch | Container Image | JupyterLab with PyTorch framework for computer vision and NLP |
| Jupyter TrustyAI | Container Image | JupyterLab with model explainability and monitoring tools |
| CUDA Images | Container Image | GPU-accelerated images with NVIDIA CUDA Toolkit |
| Habana AI Images | Container Image | Images optimized for Habana Gaudi accelerators |
| Intel GPU Images | Container Image | Images optimized for Intel GPU acceleration |
| Runtime Images | Container Image | Headless images for Elyra pipeline execution (no JupyterLab UI) |
| Code Server | Container Image | VS Code Server browser-based IDE |
| RStudio Server | Container Image | RStudio IDE for R programming |
| ImageStreams | OpenShift CR | Image version management with N/N-1/N-2 releases |
| ConfigMaps | Kubernetes CR | Image digests and commit tracking |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It consumes ImageStream CRs (image.openshift.io/v1) provided by OpenShift.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{user}/ | GET, POST | 8888/TCP | HTTP | None | OAuth Proxy | JupyterLab web interface |
| /notebook/{namespace}/{user}/api | GET | 8888/TCP | HTTP | None | OAuth Proxy | Jupyter API endpoints (readiness probe) |
| /notebook/{namespace}/{user}/terminals/websocket/{term_name} | WebSocket | 8888/TCP | HTTP | None | OAuth Proxy | Terminal websocket connections |
| / | GET | 8787/TCP | HTTP | None | OAuth Proxy | RStudio Server web interface (RStudio images only) |
| / | GET | 8443/TCP | HTTP | None | OAuth Proxy | Code Server web interface (Code Server images only) |

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI8/UBI9 Base Image | registry.access.redhat.com/ubi8/python-38, ubi9/python-39 | Yes | Base operating system and Python runtime |
| JupyterLab | 3.2-3.6 | Yes (Jupyter images) | Interactive notebook interface |
| Notebook | 6.4-6.5 | Yes (Jupyter images) | Jupyter Notebook server |
| NumPy | Latest | Yes (Data Science images) | Numerical computing library |
| Pandas | Latest | Yes (Data Science images) | Data analysis library |
| Scikit-learn | Latest | Yes (Data Science images) | Machine learning library |
| TensorFlow | 2.x | Yes (TensorFlow images) | Deep learning framework |
| PyTorch | 1.x/2.x | Yes (PyTorch images) | Deep learning framework |
| CUDA Toolkit | 11.x/12.x | Yes (CUDA images) | GPU acceleration |
| OpenCV | Latest | Yes (Data Science images) | Computer vision library |
| Elyra | 3.x | Yes (Runtime images) | Pipeline orchestration |
| code-server | Latest | Yes (Code Server images) | VS Code Server |
| RStudio Server | Latest | Yes (RStudio images) | R IDE |
| OpenShift CLI (oc) | Latest stable | Yes | Cluster interaction from notebooks |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Launches workbenches | Spawns notebook StatefulSets from ImageStream references |
| ODH Dashboard | UI selection | Displays available workbench images to users |
| OAuth Proxy | Authentication sidecar | Provides authentication for notebook endpoints |
| Kubeflow Pipelines (KFP) | Pipeline execution | Executes data science pipelines using runtime images |
| Model Registry | Model storage | Stores trained models from notebooks |
| S3 Storage | Data persistence | Persistent storage for notebook files and datasets |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {notebook-name}-notebook | ClusterIP | 8888/TCP | notebook-port (8888) | HTTP | None | OAuth Proxy (external) | Internal |
| rstudio-server | ClusterIP | 8787/TCP | 8787 | HTTP | None | OAuth Proxy (external) | Internal |
| code-server | ClusterIP | 8443/TCP | 8443 | HTTP | None | OAuth Proxy (external) | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name}-route | OpenShift Route | *.apps.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io/modh/* | 443/TCP | HTTPS | TLS 1.2+ | Registry token | Pull workbench images |
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |
| github.com | 443/TCP | HTTPS | TLS 1.2+ | Git credentials | Clone repositories |
| S3 Endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 | Access data storage |
| Kubeflow Pipelines API | 8888/TCP | HTTP | mTLS | Service token | Submit/track pipeline runs |
| Model Registry API | 8080/TCP | HTTP | mTLS | Service token | Register models |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. Notebook pods run with user-provided ServiceAccounts configured by the Notebook Controller.

### RBAC - Role Bindings

Notebook instances inherit RBAC from the Notebook Controller component. Individual notebook pods are bound to user-specific ServiceAccounts with permissions scoped to their namespace.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {notebook-name}-oauth-config | Opaque | OAuth proxy configuration | Notebook Controller | No |
| {notebook-name}-tls | kubernetes.io/tls | TLS certificate for Route | cert-manager / OpenShift | Yes |
| git-credentials | kubernetes.io/ssh-auth | Git repository authentication | User | No |
| aws-credentials | Opaque | S3 storage credentials | User | No |
| image-pull-secret | kubernetes.io/dockerconfigjson | Pull images from private registries | Cluster admin | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/* | GET, POST, WebSocket | OAuth2 Bearer Token | OAuth Proxy Sidecar | OpenShift RBAC |
| /api | GET | OAuth2 Bearer Token | OAuth Proxy Sidecar | Namespace viewer role |

## Data Flows

### Flow 1: Notebook Launch and Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 (OpenShift) |
| 2 | OAuth Proxy | JupyterLab Container | 8888/TCP | HTTP | None | None (localhost) |
| 3 | JupyterLab | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Model Training and Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Container | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / SigV4 |
| 2 | Notebook Container | Model Registry API | 8080/TCP | HTTP | mTLS | ServiceAccount Token |

### Flow 3: Pipeline Execution (Elyra Runtime)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | JupyterLab | KFP API | 8888/TCP | HTTP | mTLS | ServiceAccount Token |
| 2 | KFP | Runtime Image Pod | N/A | N/A | N/A | ServiceAccount Token |
| 3 | Runtime Image | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / SigV4 |

### Flow 4: Image Pull and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | ImageStream | quay.io/modh/* | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secret |
| 2 | Notebook Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Kubelet | Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secret |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | Web UI | 443/TCP | HTTPS | TLS 1.2+ | Workbench image selection and launch |
| Notebook Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | StatefulSet creation and lifecycle management |
| OAuth Proxy | HTTP Reverse Proxy | 8888/TCP | HTTP | None (sidecar) | Authentication enforcement |
| Kubeflow Pipelines | REST API | 8888/TCP | HTTP | mTLS | Pipeline submission and execution |
| Model Registry | REST API | 8080/TCP | HTTP | mTLS | Model versioning and storage |
| S3 / Object Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Persistent data storage |
| Git Repositories | Git/HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Source code version control |
| PyPI / Conda | HTTPS | 443/TCP | HTTPS | TLS 1.2+ | Runtime package installation |
| Container Registry | Docker Registry API | 443/TCP | HTTPS | TLS 1.2+ | Image distribution |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| v1.1.1-555-gf34daccaf | 2024-04-24 | - Merged RC fixes for 2.9 release<br>- Updated codeflare-sdk version in imagestream annotations<br>- Updated images for release N and N-1 with 2024a commit db8bd76 |
| v1.1.1-550-ga88691d1c | 2024-04-24 | - Updated images for release N and N-1 with 2024a commit<br>- Digest updater automated update |
| v1.1.1-549-gbaeea143e | 2024-04-19 | - Updated notebooks via odh-sync-updater automated action |
| v1.1.1-548-g48ddb3fc1 | 2024-04-18 | - Patched Elyra KFP template to fix kfp-kubernetes issue |
| v1.1.1-546-gfde17e1eb | 2024-04-16 | - Fixed TensorFlow KFP integration<br>- Adjusted KFP version to 2.5 in TensorFlow annotations |
| v1.1.1-545-gcd937c863 | 2024-04-16 | - Adjusted KFP version to 2.5 in TensorFlow annotation |
| v1.1.1-544-g2a3964abe | 2024-04-16 | - Updated branch reference for RStudio notebooks to point to release branch |
| v1.1.1-543-g7bff14a59 | 2024-04-15 | - Updated annotations for KFP compatibility |
| v1.1.1-539-gadd660c6f | 2024-04-12 | - Merged release-2024a branch<br>- Updated image commits for release N via digest-updater |
| v1.1.1-534-g67dccfdb5 | 2024-04-12 | - Updated manifests for code-freeze 2.9 |

## Notes

### Image Versioning Strategy
- **N (Current)**: Latest production release (e.g., 2024.1)
- **N-1 (Previous)**: Previous production release (e.g., 2023.2)
- **N-2 (Deprecated)**: Older release marked as outdated (e.g., 2023.1)
- **N-3 (Legacy)**: Legacy release for backward compatibility (e.g., 1.2)

Images are referenced by SHA256 digest in params.env to ensure immutability. ImageStream tags maintain multiple versions simultaneously for rollback and compatibility.

### Build Chain
Images follow a hierarchical build chain:
1. **Base** → **Minimal** → **Data Science** → **Specialized** (TensorFlow/PyTorch/TrustyAI)
2. **Base** → **CUDA** → **GPU-accelerated Minimal** → **GPU Data Science** → **GPU Specialized**
3. **Base** → **Runtime** (headless for pipeline execution)

### Deployment Model
Workbench images are **not deployed directly** by this repository. Instead:
- Images are built and published to quay.io/modh/
- ImageStreams and ConfigMaps define available images in the cluster
- ODH Notebook Controller launches StatefulSets using these ImageStream references
- Users select workbench images via the ODH Dashboard UI

### Hardware Acceleration Support
- **NVIDIA CUDA**: CUDA 11.x/12.x for GPU acceleration
- **Intel GPU**: Intel GPU drivers and optimized libraries
- **Habana Gaudi**: Habana SDK for DL training acceleration

### Manifest Location
- **Deployment Manifests**: `manifests/base/` and `manifests/overlays/`
- **JupyterHub Integration**: Deployed via manifests:/jupyterhub/notebooks kustomization
- **Kustomize**: Uses ConfigMapGenerator for image version management

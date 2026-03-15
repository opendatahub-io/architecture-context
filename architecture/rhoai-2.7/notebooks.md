# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-366-gc221dab8a
- **Branch**: rhoai-2.7
- **Distribution**: RHOAI, ODH
- **Languages**: Python, Shell, Dockerfile
- **Deployment Type**: Container Images (Workbench/Notebook Servers)

## Purpose
**Short**: Provides containerized workbench environments (Jupyter, code-server, RStudio) for data scientists and ML engineers.

**Detailed**: The notebooks repository builds and maintains a collection of containerized workbench images that serve as interactive development environments for data science and machine learning workflows in RHOAI/ODH. These images include JupyterLab notebooks with various pre-installed libraries (minimal, data science, PyTorch, TensorFlow, TrustyAI), code-server (VS Code in browser), and RStudio Server for R programming. The images are built in a layered architecture starting from UBI/RHEL base images and progressively adding capabilities. They support both CPU-only and accelerated workloads (NVIDIA CUDA, Intel Habana). Runtime images optimized for Elyra pipeline execution are also provided. Images are deployed as StatefulSets in OpenShift/Kubernetes and expose web-based IDEs through services and ingress.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images (ubi8/ubi9/c9s/rhel9) | Container Base | Foundation images with Python 3.8 or 3.9, pip, and OpenShift CLI |
| Jupyter Minimal | Container Image | Basic JupyterLab environment with minimal dependencies |
| Jupyter Data Science | Container Image | JupyterLab with common ML/AI libraries (numpy, pandas, scikit-learn, matplotlib) |
| Jupyter PyTorch | Container Image | Data Science + PyTorch framework for deep learning |
| Jupyter TensorFlow | Container Image | Data Science + TensorFlow framework for deep learning |
| Jupyter TrustyAI | Container Image | Data Science + TrustyAI explainability libraries |
| CUDA Base Images | Container Image | Base images with NVIDIA CUDA toolkit for GPU acceleration |
| CUDA Jupyter Variants | Container Image | GPU-accelerated versions of Jupyter notebooks |
| Habana Jupyter Images | Container Image | Intel Habana Gaudi accelerator support (versions 1.9.0, 1.10.0, 1.11.0) |
| Runtime Images | Container Image | Lightweight images for Elyra pipeline execution (no Jupyter UI) |
| code-server | Container Image | VS Code server in browser with Python environment |
| RStudio Server | Container Image | RStudio IDE for R programming with Python support |
| ImageStream Manifests | OpenShift Resource | Image registry pointers and version management |
| BuildConfig Manifests | OpenShift Resource | Image build pipelines for RStudio (requires RHEL subscription) |
| Kustomize Deployments | Kubernetes Manifests | Deployment templates for notebook StatefulSets and Services |

## APIs Exposed

### Custom Resource Definitions (CRDs)

None - this component provides container images only.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/ | GET, POST | 8888/TCP | HTTP | None (internal) | Token-based (disabled in dev) | JupyterLab UI and API access |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None (internal) | Token-based (disabled in dev) | Jupyter server API (used by readiness probe) |
| /api | GET | 8888/TCP | HTTP | None (internal) | None (code-server) | code-server API health check |
| /rstudio/ | GET, POST | 8787/TCP | HTTP | None (internal) | Basic Auth | RStudio Server web interface |

**Note**: All services run as ClusterIP and are accessed through the ODH/RHOAI notebook controller proxy. TLS termination happens at the ingress/route level, not within the notebook containers.

### gRPC Services

None - HTTP-only interfaces.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI8 Python 3.8 | registry.access.redhat.com/ubi8/python-38 | Yes | Base image for Python 3.8 notebooks |
| UBI9 Python 3.9 | registry.access.redhat.com/ubi9/python-39 | Yes | Base image for Python 3.9 notebooks |
| CentOS Stream 9 | quay.io/centos/centos:stream9 | Yes | Base for code-server and RStudio |
| NVIDIA CUDA Toolkit | 11.8+ | No (GPU only) | GPU acceleration support |
| Intel Habana SDK | 1.9.0, 1.10.0, 1.11.0 | No (Habana only) | Intel Gaudi accelerator support |
| JupyterLab | 3.2-3.6 | Yes (Jupyter) | Notebook interface |
| code-server | 4.16.1 | Yes (code-server) | VS Code server |
| RStudio Server | 2023.06.1-524 | Yes (RStudio) | R IDE |
| NGINX | 1.22 | Yes (code-server, RStudio) | Reverse proxy for API health checks |
| OpenShift Client (oc) | stable | Yes | Cluster interaction from notebooks |
| Elyra | 3.15.0 | No (Data Science) | Visual pipeline editor |
| boto3 | 1.28+ | No (Data Science) | AWS SDK for Python |
| PyTorch | latest | No (PyTorch) | Deep learning framework |
| TensorFlow | latest | No (TensorFlow) | Deep learning framework |
| scikit-learn | 1.2-1.3 | No (Data Science) | ML library |
| pandas | 1.5+ | No (Data Science) | Data manipulation library |
| numpy | 1.24+ | No (Data Science) | Numerical computing library |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH/RHOAI Notebook Controller | Orchestration | Spawns and manages notebook instances as StatefulSets |
| ODH Dashboard | UI | Provides notebook selection and launch interface |
| OpenShift ImageStreams | Image Registry | Stores and versions notebook images |
| OpenShift Routes/Ingress | HTTP Proxy | Routes external traffic to notebook services via controller |
| Service Mesh (Istio) | mTLS & AuthZ | Enforces service-to-service encryption and authorization (when enabled) |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {notebook-name}-notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None (internal) | Token (disabled in dev) | Internal |
| code-server-svc | ClusterIP | 8888/TCP | 8888 | HTTP | None (internal) | Basic Auth (VS Code) | Internal |
| rstudio-svc | ClusterIP | 8787/TCP | 8787 | HTTP | None (internal) | Basic Auth (RStudio) | Internal |

**Note**: Services are dynamically created per notebook instance. The service name format is `jupyter-{variant}-{python-version}-notebook`.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-route-{username} | OpenShift Route | {cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

**Note**: Ingress/Routes are created by the notebook controller, not by the notebook images themselves. Traffic flows through the controller proxy which adds authentication and authorization.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull container images |
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |
| mirror.openshift.com | 443/TCP | HTTPS | TLS 1.2+ | None | Download OpenShift CLI tools |
| github.com | 443/TCP | HTTPS | TLS 1.2+ | SSH/Token | Git operations from notebooks |
| cran.rstudio.com | 443/TCP | HTTPS | TLS 1.2+ | None | Install R packages (RStudio) |
| download2.rstudio.org | 443/TCP | HTTPS | TLS 1.2+ | None | RStudio Server installation |
| S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/S3 Keys | Data access via boto3 |
| Kafka Brokers | 9092/TCP, 9093/TCP | Kafka/SSL | TLS 1.2+ (SSL) | SASL | Kafka client connections |
| PostgreSQL | 5432/TCP | PostgreSQL | TLS (optional) | Password | Database connections |
| MySQL | 3306/TCP | MySQL | TLS (optional) | Password | Database connections |
| MongoDB | 27017/TCP | MongoDB | TLS (optional) | Password | Database connections |

## Security

### RBAC - Cluster Roles

None defined in this repository. RBAC is managed by the ODH/RHOAI notebook controller which launches these images.

### RBAC - Role Bindings

None defined in this repository. Notebook pods run under service accounts created by the notebook controller.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription for building RStudio images | Administrator | No |
| {notebook-name}-notebook-tls | kubernetes.io/tls | TLS certificate for notebook routes | OpenShift Router | No |
| user-git-credentials | kubernetes.io/ssh-auth | User Git SSH keys for version control | User/Admin | No |
| aws-secret | Opaque | AWS credentials for S3 access | User/Admin | No |
| database-credentials | Opaque | Database connection credentials | User/Admin | No |

**Note**: Most secrets are mounted by the notebook controller based on user configuration, not hardcoded in these images.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | GET, POST | Bearer Token (JWT) from OAuth | Notebook Controller Proxy | User must own namespace or have RBAC view permissions |
| Internal Jupyter API | GET, POST | Token (disabled in example configs) | Jupyter Server | Disabled for controller-managed notebooks |
| code-server | GET, POST | Password (optional) | NGINX + code-server | Optional password protection |
| RStudio Server | GET, POST | PAM Authentication | RStudio Server | Username/password authentication |

**Note**: Primary authentication is handled by the ODH/RHOAI notebook controller proxy, which validates OpenShift OAuth tokens before proxying to notebook pods.

## Data Flows

### Flow 1: User Accesses Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | OpenShift Router | Notebook Controller Service | 8080/TCP | HTTP | mTLS (if service mesh enabled) | Service Account Token |
| 3 | Notebook Controller | Notebook Pod Service | 8888/TCP | HTTP | mTLS (if service mesh enabled) | None (internal) |
| 4 | Notebook Pod | Jupyter Server Process | 8888/TCP | HTTP | None (localhost) | None |

### Flow 2: Notebook Installs Python Package

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod | PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | PyPI CDN | Notebook Pod | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 3: Notebook Accesses S3 Data

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod (boto3) | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM (SigV4) |
| 2 | S3 Service | Notebook Pod | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 4: Image Build (BuildConfig)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | BuildConfig | GitHub | 443/TCP | HTTPS | TLS 1.2+ | None (public repo) |
| 2 | BuildConfig | Base Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 3 | BuildConfig | OpenShift ImageStream | Internal | Registry API | TLS 1.2+ | Service Account Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Pod Orchestration | N/A | Kubernetes API | TLS 1.2+ | Creates StatefulSets from image definitions |
| OpenShift ImageStream | Image Pull | 5000/TCP | Container Registry | TLS 1.2+ | Serves built images to cluster |
| Elyra Pipeline Execution | Runtime Execution | N/A | KFP/Tekton API | TLS 1.2+ | Runtime images execute pipeline steps |
| JupyterHub (legacy) | Notebook Spawning | 8888/TCP | HTTP | mTLS | Alternative notebook launcher (deprecated) |
| GPU Node Feature Discovery | Device Detection | N/A | Kubelet | None | Schedules CUDA notebooks on GPU nodes |

## Container Image Build Process

### Build Chain (Python 3.9 / UBI9 Example)

| Step | Image | Base Image | Added Components |
|------|-------|------------|------------------|
| 1 | base-ubi9-python-3.9 | registry.access.redhat.com/ubi9/python-39 | wheel, setuptools, oc CLI, mesa-libGL |
| 2 | jupyter-minimal-ubi9-python-3.9 | base-ubi9-python-3.9 | JupyterLab 3.6, Notebook 6.5, jupyter-server |
| 3 | jupyter-datascience-ubi9-python-3.9 | jupyter-minimal-ubi9-python-3.9 | pandas, numpy, scikit-learn, matplotlib, boto3, Elyra, DB connectors |
| 4 | jupyter-pytorch-ubi9-python-3.9 | cuda-jupyter-datascience-ubi9-python-3.9 | PyTorch, torchvision, torchaudio |
| 5 | jupyter-tensorflow-ubi9-python-3.9 | cuda-jupyter-datascience-ubi9-python-3.9 | TensorFlow, Keras |
| 6 | jupyter-trustyai-ubi9-python-3.9 | jupyter-datascience-ubi9-python-3.9 | TrustyAI explainability libraries |

### CUDA Build Chain

| Step | Image | Base Image | Added Components |
|------|-------|------------|------------------|
| 1 | cuda-ubi9-python-3.9 | base-ubi9-python-3.9 | NVIDIA CUDA Toolkit 11.8+, cuDNN, NCCL |
| 2 | cuda-jupyter-minimal-ubi9-python-3.9 | cuda-ubi9-python-3.9 | JupyterLab (same as minimal) |
| 3 | cuda-jupyter-datascience-ubi9-python-3.9 | cuda-jupyter-minimal-ubi9-python-3.9 | Data science libraries (GPU-enabled versions) |

### Alternate Workbenches

| Image | Base Image | Primary Software | Port |
|-------|------------|------------------|------|
| code-server-c9s-python-3.9 | base-c9s-python-3.9 | code-server 4.16.1, NGINX 1.22, VS Code extensions | 8888/TCP |
| rstudio-c9s-python-3.9 | base-c9s-python-3.9 | RStudio Server 2023.06.1-524, R 4.3.1, NGINX 1.22 | 8787/TCP |

## Deployment Model

### StatefulSet Configuration

```yaml
Replicas: 1 (single-user notebook)
Resources:
  Limits:
    CPU: 500m (configurable by admin)
    Memory: 2Gi (configurable by admin)
  Requests:
    CPU: 500m
    Memory: 2Gi
Probes:
  Liveness: TCP socket on port 8888
  Readiness: HTTP GET /notebook/{namespace}/{username}/api
Persistent Storage: Optional (PVC for /opt/app-root/src)
Service Account: Created by notebook controller per user
Security Context:
  RunAsUser: 1001
  RunAsGroup: 0
  FSGroup: 0 (OpenShift compatibility)
```

### Image Management

- **Registry**: quay.io/opendatahub/workbench-images (ODH), quay.io/modh/* (RHOAI)
- **Tagging Strategy**: {image-name}-{RELEASE}_{DATE} (e.g., jupyter-minimal-ubi9-python-3.9-2023b_20240131)
- **Version Tracking**:
  - N (current/recommended)
  - N-1 (supported)
  - N-2 (outdated, marked for deprecation)
- **ImageStream Tags**: Map to specific image digests (SHA256) for reproducibility
- **Update Mechanism**: Digest updater GitHub action updates manifests with new image SHAs

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| c221dab8a | 2023 | - Merge release-2023b branch |
| e747bcecc | 2023 | - Cherry-pick fixes to release-2023b |
| f9dc3b7bf | 2023 | - Cherry-pick additional fixes |
| ea9c4a4ef | 2023 | - Fix library path version on rsession.conf file |
| 48b7199bc | 2023 | - Hot fix: bump cuda resources |
| 98b20dde8 | 2023 | - HotFix: Remove annotation notebook-images=true from RStudio imagestreams |
| 8cf4bdfed | 2023 | - Fix user R library path version |
| c20c52cb6 | 2023 | - Update image commits for release N via digest-updater GitHub action |
| b8984d398 | 2023 | - Update images for release N via digest-updater GitHub action |
| 21a8d6f22 | 2023 | - Remove R-package install from workbench |
| f833605a7 | 2023 | - Merge rsync updates to 2023b |
| 7389221b6 | 2023 | - CI: Fix for YAML files with multiple definitions |
| 8bf128eaf | 2023 | - Fix naming for RStudio Server on RHEL flavor |

## Testing & Validation

### Notebook Testing

- **Framework**: Papermill (automated notebook execution)
- **Test Notebooks**: Located in each image variant directory (jupyter/*/test/test_notebook.ipynb)
- **Validation**: Executes test notebook and checks for FAILED status in stderr
- **CI Pipeline**: Automated testing on pull requests

### Runtime Image Validation

**Required Commands**:
- curl (HTTP requests)
- python3 (Elyra pipeline execution)

**Validation Process**:
1. Check command availability
2. Install requirements-elyra.txt
3. Execute sample notebook with papermill
4. Verify successful execution

### code-server Validation

**Required Commands**:
- curl
- python
- oc (OpenShift CLI)
- code-server

### RStudio Validation

**Required Commands**:
- curl
- python
- oc
- /usr/lib/rstudio-server/bin/rserver

## Known Limitations

1. **Single-User Model**: Each notebook runs as a separate StatefulSet (not multi-tenant within a pod)
2. **No Built-in Persistence**: Users must configure PVCs separately for notebook storage
3. **Token Auth Disabled**: Jupyter token authentication is disabled when using notebook controller (relies on controller auth)
4. **RStudio Build Complexity**: Requires RHEL subscription secret for building (uses BuildConfig instead of standard CI)
5. **CUDA Version Lock**: CUDA toolkit version is baked into images, not runtime-configurable
6. **Python Version Isolation**: No support for multiple Python versions in a single image
7. **Package Conflicts**: Users installing additional packages may encounter dependency conflicts with pre-installed libraries

## Future Enhancements

Based on repository structure and commit history:

1. **Python 3.11/3.12 Support**: Newer Python versions on UBI9/RHEL9
2. **Habana SDK Updates**: Support for newer Habana Gaudi driver versions
3. **GPU Sharing**: Multi-tenant GPU utilization for cost optimization
4. **Custom Package Channels**: Support for private PyPI mirrors
5. **Build-time Customization**: User-defined package lists in notebook spawner
6. **Improved Conda Support**: Better Anaconda environment management
7. **ARM64 Support**: Multi-architecture images for ARM-based clusters

# Component: Workbench Notebooks

## Metadata
- **Repository**: https://github.com/opendatahub-io/notebooks.git
- **Version**: 1.42.0-46-g98f5c95c
- **Distribution**: ODH and RHOAI (both)
- **Languages**: Python, Bash, Dockerfiles
- **Deployment Type**: Container Images

## Purpose
**Short**: Provides pre-configured workbench container images for data science and machine learning workflows in OpenDataHub and RHOAI.

**Detailed**: The notebooks component is a collection of container images that provide data science workbenches with various IDEs (Jupyter, VS Code Server, RStudio) and runtime environments optimized for different use cases. These images include base images with Python environments, specialized images with ML frameworks (PyTorch, TensorFlow), and accelerator-specific builds for CUDA and ROCm GPUs. The images are designed to be launched by the ODH/RHOAI Notebook Controller and provide integrated environments with pre-installed tools, libraries, and dependencies. The repository supports both workbench images (interactive development) and runtime images (pipeline execution) across multiple Python versions, OS distributions (UBI9, C9S, RHEL9), and hardware architectures (x86_64, aarch64, ppc64le, s390x).

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image | Foundation images with Python runtime and common dependencies (CPU, CUDA, ROCm variants) |
| Workbench Images | Container Image | Interactive development environments (Jupyter, CodeServer, RStudio) with ML frameworks |
| Runtime Images | Container Image | Lightweight pipeline execution images with Python and framework dependencies |
| Kustomize Manifests | Deployment Artifact | StatefulSet and Service definitions for deploying workbenches in Kubernetes |
| Tekton Pipelines | CI/CD | Multi-arch build pipelines for automated image building via Konflux |

## APIs Exposed

### Custom Resource Definitions (CRDs)
No CRDs are defined in this component. Workbenches are launched by the ODH Notebook Controller which creates StatefulSets.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET, POST | 8888/TCP | HTTP | None (internal) | Notebook token | Jupyter Lab web interface |
| /lab | GET | 8888/TCP | HTTP | None (internal) | Notebook token | Jupyter Lab UI |
| /api | GET, POST | 8888/TCP | HTTP | None (internal) | Notebook token | Jupyter Server API |

### gRPC Services
No gRPC services are exposed. Workbenches communicate via HTTP.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| JupyterLab | 4.x | Yes | Core notebook interface for Jupyter workbenches |
| VS Code Server | Latest | Yes | IDE interface for CodeServer workbenches |
| RStudio Server | Latest | Yes | IDE for R development workbenches |
| PyTorch | 2.x | No | Deep learning framework (pytorch images only) |
| TensorFlow | 2.x | No | Machine learning framework (tensorflow images only) |
| CUDA Toolkit | 12.6-13.0 | No | NVIDIA GPU support (CUDA images only) |
| ROCm | 6.2-6.4 | No | AMD GPU support (ROCm images only) |
| NumPy, Pandas, scikit-learn | Latest | Yes | Data science libraries (datascience images) |
| TrustyAI | Latest | No | Explainable AI tools (trustyai images only) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | CRD-managed | Launches and manages notebook workbench StatefulSets |
| ODH Dashboard | UI Integration | Provides UI for creating and managing notebook instances |
| Data Science Pipelines | Runtime Integration | Uses runtime images for pipeline step execution |
| Model Registry | API | Registers and versions models from workbench development |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | Notebook Token | Internal |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-ingress | OpenShift Route | *.apps.cluster | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull container images and artifacts |
| pypi.org / pip index | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials | Access datasets and model artifacts |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH/Token | Clone code repositories |

## Security

### RBAC - Cluster Roles
No custom ClusterRoles are defined. Workbenches run with the permissions granted by the Notebook Controller's ServiceAccount.

### RBAC - Role Bindings
Workbench pods run with minimal permissions. RBAC is managed by the Notebook Controller component.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| notebook-tls-secret | kubernetes.io/tls | TLS certificates for HTTPS ingress | cert-manager / OpenShift | Yes |
| notebook-oauth-secret | Opaque | OAuth proxy authentication token | ODH Dashboard | No |
| aws-credentials | Opaque | S3 bucket access credentials for datasets | User-provided | No |
| git-credentials | kubernetes.io/ssh-auth | SSH keys for private git repository access | User-provided | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /lab, /api | GET, POST | Jupyter Token | Jupyter Server | Token-based access control |
| Ingress HTTPS | GET, POST | OAuth Proxy | OpenShift Route | User authentication via OAuth |

## Data Flows

### Flow 1: Workbench Development Session

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Ingress | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 2 | OAuth Proxy | Notebook Pod | 8888/TCP | HTTP | None | Notebook Token |
| 3 | Notebook Pod | PyPI Index | 443/TCP | HTTPS | TLS 1.2+ | None |
| 4 | Notebook Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM |
| 5 | Notebook Pod | Git Repository | 443/TCP | HTTPS | TLS 1.2+ | SSH Key / Token |

### Flow 2: Pipeline Runtime Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | DSP Orchestrator | Runtime Pod | N/A | Exec | None | Kubernetes API |
| 2 | Runtime Pod | S3 Artifacts | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM |
| 3 | Runtime Pod | Model Registry API | 8080/TCP | HTTP | None | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | HTTP API | 8080/TCP | HTTP | None | Workbench lifecycle management |
| Data Science Pipelines | Container Runtime | N/A | N/A | N/A | Execute pipeline steps using runtime images |
| Model Registry | HTTP API | 8080/TCP | HTTP | None | Register trained models from workbench |
| S3 Storage | HTTP API | 443/TCP | HTTPS | TLS 1.2+ | Access training data and model artifacts |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 1.42.0-46 | 2025-01 | - Add manifests/tools/generate_envs.py for automating container image reference updates<br>- Rename Tekton pipeline tasks to use consistent "odh-main" naming<br>- Add ROCm minimal image support for large platforms<br>- Move manifests to separate odh/ and rhoai/ directories<br>- Update to new 3.4-ea2 artifacts (RHAB Images & RH-Index)<br>- Add GPU library loading tests for ROCm unversioned symlinks<br>- Update RStudio Python packages for AIPCC rh-index wheels |

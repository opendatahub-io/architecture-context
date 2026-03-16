# Component: Notebook Workbench Images

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-434-g896a5954a
- **Branch**: rhoai-2.8
- **Distribution**: RHOAI
- **Languages**: Python, Shell, Dockerfile
- **Deployment Type**: Container Images (deployed via OpenShift ImageStreams)

## Purpose
**Short**: Container image build definitions for Jupyter notebook and IDE workbench images used in Red Hat OpenShift AI.

**Detailed**: This repository provides a comprehensive collection of container image build definitions for data science workbench environments. It creates layered container images ranging from minimal Python environments to fully-featured data science notebooks with GPU acceleration support. The images are designed to run as user workspaces in OpenShift AI, providing data scientists with pre-configured environments for interactive development, model training, and pipeline execution. The repository supports multiple base operating systems (UBI8, UBI9, RHEL9, CentOS Stream 9), multiple Python versions (3.8, 3.9), and specialized hardware accelerators (NVIDIA CUDA, Intel Habana Gaudi). Images are built in a hierarchical dependency chain, allowing efficient layer reuse and consistent environments across different workbench types.

The repository also includes runtime images optimized for Elyra pipeline execution, IDE alternatives (VS Code Server, RStudio Server), and extensive testing infrastructure to validate notebook functionality. All images are published to Quay.io container registries and deployed via OpenShift ImageStream resources with version tracking through commit SHAs.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image | Minimal Python environments with OpenShift client (oc) and pip package management |
| Jupyter Minimal | Container Image | JupyterLab 3.6 with core notebook functionality, Git integration, and server proxy |
| Jupyter Data Science | Container Image | Full data science stack with pandas, scikit-learn, matplotlib, Elyra pipeline extensions, and database connectors |
| Jupyter PyTorch | Container Image | PyTorch-optimized notebook for deep learning model development |
| Jupyter TensorFlow | Container Image | TensorFlow-optimized notebook for deep learning model development |
| Jupyter TrustyAI | Container Image | Specialized notebook with TrustyAI explainability and bias detection tools |
| CUDA Notebooks | Container Image | GPU-accelerated variants with NVIDIA CUDA runtime and libraries |
| Habana Notebooks | Container Image | Intel Gaudi accelerator support for AI workloads (versions 1.9.0, 1.10.0, 1.11.0) |
| Runtime Images | Container Image | Lightweight Elyra-compatible pipeline execution containers without JupyterLab UI |
| Code Server | Container Image | VS Code browser-based IDE with Python and Jupyter extensions, nginx proxy |
| RStudio Server | Container Image | R programming IDE with web interface, nginx proxy |
| ImageStream Manifests | Kubernetes Resource | OpenShift ImageStream definitions for notebook image deployment |
| ConfigMap Parameters | Kubernetes Resource | Version pinning via image SHA digests and commit tracking |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It provides container images consumed by the ODH Notebook Controller which creates notebook pods based on user selections.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/* | GET, POST, WebSocket | 8888/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | JupyterLab UI and notebook API endpoints |
| /api/kernels | GET, POST, DELETE, WebSocket | 8888/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | Jupyter kernel management and execution |
| /api/contents | GET, POST, PUT, DELETE | 8888/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | Notebook file content management |
| /proxy/* | GET, POST | 8888/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | Jupyter Server Proxy for forwarding to applications |
| /git/* | GET, POST | 8888/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | JupyterLab Git extension API |
| / (Code Server) | GET, POST, WebSocket | 8080/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | VS Code Server web UI and extension APIs |
| / (RStudio) | GET, POST | 8787/TCP | HTTP | None (Istio terminates TLS) | OAuth Proxy | RStudio Server web UI |

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI8 Python 3.8 | registry.access.redhat.com/ubi8/python-38 | Yes | Base OS image for Python 3.8 workbenches |
| UBI9 Python 3.9 | registry.access.redhat.com/ubi9/python-39 | Yes | Base OS image for Python 3.9 workbenches |
| RHEL9 Python 3.9 | registry.redhat.io/rhel9/python-39 | Yes | Enterprise base OS for RHOAI production builds |
| CentOS Stream 9 | quay.io/centos/centos:stream9 | Yes | Base for Code Server and RStudio images |
| Anaconda Python 3.8 | continuumio/anaconda3 | No | Alternative Python distribution (deprecated) |
| NVIDIA CUDA Base | nvidia/cuda | Yes (GPU) | CUDA runtime and libraries for GPU acceleration |
| Intel Habana Base | vault.habana.ai/gaudi-docker | Yes (Habana) | Intel Gaudi accelerator runtime |
| JupyterLab | ~=3.6.5 | Yes | Core notebook web interface |
| Jupyter Server | ~=2.7.3 | Yes | Backend server for Jupyter notebooks |
| Elyra Extensions | ~=3.15.0 | Yes (Data Science) | Visual pipeline editor and code snippet extensions |
| Code Server | 4.x | Yes (Code Server) | VS Code browser implementation |
| RStudio Server | Latest OSS | Yes (RStudio) | R IDE server component |
| OpenShift CLI (oc) | stable | Yes | Kubernetes/OpenShift command-line tool |
| Nginx | Latest | Yes (Code Server, RStudio) | Reverse proxy for IDE access |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | CRD Reconciliation | Launches notebook pods from ImageStream selections |
| ODH Dashboard | UI Integration | Provides notebook image selection interface |
| OAuth Proxy | Sidecar Container | Authenticates notebook access via OpenShift OAuth |
| Elyra Runtime Pipelines | Container Execution | Executes runtime images in Kubeflow/Tekton pipelines |
| Data Science Pipelines | Pipeline DAG | Integrates with Kubeflow Pipelines via kfp-tekton SDK |
| Model Registry | Python SDK | Connects to model storage via boto3 S3 client |

## Network Architecture

### Services

Notebook workbenches do not define Services directly. They run as Pods with network access controlled by the ODH Notebook Controller.

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {username}-notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | OAuth Proxy Sidecar | Internal (via Route) |
| {username}-code-server | ClusterIP | 8080/TCP | 8080 | HTTP | None | OAuth Proxy Sidecar | Internal (via Route) |
| {username}-rstudio | ClusterIP | 8787/TCP | 8787 | HTTP | None | OAuth Proxy Sidecar | Internal (via Route) |

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {username}-notebook | OpenShift Route | {username}-notebook-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | edge | External |
| {username}-code-server | OpenShift Route | {username}-code-server-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | edge | External |
| {username}-rstudio | OpenShift Route | {username}-rstudio-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | edge | External |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None | Install user Python packages via pip |
| Conda Repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Install Anaconda packages |
| Git Repositories (github.com, gitlab.com) | 443/TCP | HTTPS | TLS 1.2+ | User SSH Key/Token | Clone and push code repositories |
| S3-compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Key | Access data and model artifacts via boto3 |
| Database Endpoints | 5432/TCP, 3306/TCP, 27017/TCP, 1433/TCP | PostgreSQL, MySQL, MongoDB, MS SQL | TLS 1.2+ | DB Credentials | Connect to databases from notebooks |
| OpenShift API | 6443/TCP | HTTPS | TLS 1.3 | ServiceAccount Token | Execute oc commands, manage resources |
| Kubeflow Pipelines API | 8888/TCP | HTTP | None (internal) | Bearer Token | Submit and monitor pipeline runs |
| Container Registries (quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull runtime images for pipeline execution |

## Security

### RBAC - Cluster Roles

Notebook workbenches run with permissions granted by the ODH Notebook Controller. They do not define cluster-wide RBAC themselves.

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | "" | pods, services, serviceaccounts, configmaps, secrets, persistentvolumeclaims | get, list, create, delete, patch |
| notebook-controller-role | apps | statefulsets | get, list, create, delete, patch |
| notebook-controller-role | route.openshift.io | routes | get, list, create, delete, patch |
| notebook-controller-role | networking.k8s.io | networkpolicies | get, list, create, delete, patch |

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| {username}-notebook-sa | {user-namespace} | edit | {username}-notebook-sa |

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {username}-notebook-oauth-config | Opaque | OAuth proxy configuration for notebook access | ODH Dashboard | No |
| {username}-git-credentials | kubernetes.io/ssh-auth | Git repository authentication | User via Dashboard | No |
| {username}-db-credentials | Opaque | Database connection credentials | User | No |
| {username}-s3-credentials | Opaque | S3/object storage access keys | User | No |
| aws-connection-{name} | Opaque | AWS credentials for data connections | Data Science Pipelines | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | All | OAuth Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | Namespace RBAC (user must have access to namespace) |
| /api/* | All | OAuth Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | Namespace RBAC (user must have access to namespace) |
| / (Code Server) | All | OAuth Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | Namespace RBAC (user must have access to namespace) |
| / (RStudio) | All | OAuth Proxy (OpenShift OAuth) | OAuth Proxy Sidecar | Namespace RBAC (user must have access to namespace) |

## Data Flows

### Flow 1: User Notebook Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (public endpoint) |
| 2 | OpenShift Router | Route ({username}-notebook) | 443/TCP | HTTPS | TLS 1.2+ | Route policy |
| 3 | Route | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift OAuth redirect |
| 4 | OAuth Proxy Sidecar | Jupyter Server Container | 8888/TCP | HTTP | plaintext | Localhost trusted |
| 5 | Jupyter Server | User Browser (WebSocket) | 8888/TCP | HTTP/WebSocket | plaintext (OAuth proxy tunnels) | OAuth Token validated |

### Flow 2: Notebook to S3 Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter Notebook (boto3) | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature V4 (Access Key ID + Secret) |
| 2 | S3 Service | Jupyter Notebook | 443/TCP | HTTPS | TLS 1.2+ | N/A (response) |

### Flow 3: Git Repository Clone

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter Notebook (git CLI) | GitHub/GitLab | 443/TCP | HTTPS or SSH (22/TCP) | TLS 1.2+ or SSH | User Personal Access Token or SSH Key |
| 2 | Git Server | Jupyter Notebook | 443/TCP or 22/TCP | HTTPS or SSH | TLS 1.2+ or SSH | N/A (response) |

### Flow 4: Pipeline Execution (Elyra Runtime)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Elyra Extension (Jupyter) | Kubeflow Pipelines API | 8888/TCP | HTTP | plaintext (internal) | Bearer Token (ServiceAccount) |
| 2 | Kubeflow Pipelines | Argo/Tekton Workflow Engine | 8080/TCP | HTTP | plaintext (internal) | ServiceAccount Token |
| 3 | Argo/Tekton | Runtime Image Pod | N/A | Container Exec | plaintext (internal) | ServiceAccount Token |
| 4 | Runtime Image Pod | S3 Storage (artifacts) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM or Access Key |

### Flow 5: Database Connection

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter Notebook (psycopg/pymongo/pyodbc) | Database Endpoint | 5432/TCP, 27017/TCP, 3306/TCP, 1433/TCP | PostgreSQL/MongoDB/MySQL/MS SQL | TLS 1.2+ (if configured) | Username + Password or Certificate |
| 2 | Database Server | Jupyter Notebook | 5432/TCP, 27017/TCP, 3306/TCP, 1433/TCP | DB Protocol | TLS 1.2+ | N/A (response) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | HTTP REST API | 8080/TCP | HTTP | plaintext (internal) | Notebook image selection and spawning |
| OAuth Proxy | HTTP Proxy | 8443/TCP | HTTPS | TLS 1.2+ | User authentication and authorization |
| Kubeflow Pipelines | HTTP REST API | 8888/TCP | HTTP | plaintext (internal) | Pipeline submission and monitoring via kfp-tekton SDK |
| Data Science Pipelines | HTTP REST API | 8888/TCP | HTTP | plaintext (internal) | Pipeline execution and artifact storage |
| Model Registry | HTTP REST API | 8080/TCP | HTTP | plaintext (internal) | Model versioning and metadata storage |
| S3 Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Data and model artifact storage via boto3 |
| OpenShift API | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Resource management via oc CLI |
| Container Registry (Quay.io) | Docker Registry API v2 | 443/TCP | HTTPS | TLS 1.2+ | Pull notebook and runtime images |
| Git Repositories | Git Protocol | 443/TCP or 22/TCP | HTTPS or SSH | TLS 1.2+ or SSH | Source code version control |

## Build and Deployment Architecture

### Build Chain

| Stage | Input | Output | Build Tool | Purpose |
|-------|-------|--------|------------|---------|
| Base Image Build | UBI/RHEL Dockerfile + Pipfile.lock | base-{distro}-python-{version} | Podman/Buildah | Minimal Python environment with oc CLI |
| Jupyter Minimal Build | Base Image + Jupyter Pipfile.lock | jupyter-minimal-{distro}-python-{version} | Podman/Buildah | JupyterLab core installation |
| Jupyter Data Science Build | Jupyter Minimal + Data Science Pipfile.lock | jupyter-datascience-{distro}-python-{version} | Podman/Buildah | Add ML libraries and Elyra extensions |
| Jupyter ML Framework Build | Data Science Image + Framework packages | jupyter-pytorch/tensorflow-{distro}-python-{version} | Podman/Buildah | Deep learning framework optimization |
| CUDA Build | Base Image + NVIDIA CUDA | cuda-{distro}-python-{version} | Podman/Buildah | GPU acceleration layer |
| Runtime Build | Base Image + Runtime Pipfile.lock | runtime-{variant}-{distro}-python-{version} | Podman/Buildah | Lightweight Elyra execution container |

### Image Publishing

| Registry | Image Path | Tag Format | Purpose |
|----------|-----------|------------|---------|
| quay.io/modh/* | odh-{notebook-type}-notebook-container, cuda-notebooks, codeserver | SHA256 digest | RHOAI production images |
| quay.io/opendatahub/workbench-images | {notebook-type}-{distro}-python-{version} | {release}_{date} or commit SHA | ODH community images |

### Deployment Manifests

| Manifest Type | Location | Purpose |
|---------------|----------|---------|
| ImageStream | manifests/base/*-imagestream.yaml | Define notebook image versions with N, N-1, N-2 rollback |
| BuildConfig | manifests/base/*-buildconfig.yaml | OpenShift S2I builds for RStudio (requires RHEL entitlements) |
| ConfigMap (params) | Generated from params.env | Pin exact image SHA256 digests for version stability |
| ConfigMap (commit) | Generated from commit.env | Track git commit SHA for each image build |
| Kustomization | manifests/base/kustomization.yaml | Aggregate manifests and inject ConfigMap variables |

## Testing Infrastructure

| Test Type | Tool | Coverage |
|-----------|------|----------|
| Notebook Functionality | Papermill | Execute test notebooks in each image variant |
| Runtime Validation | Shell Scripts | Verify curl, python3, and Elyra requirements |
| Code Server Validation | Shell Scripts | Check code-server, oc, curl, python availability |
| RStudio Validation | R Scripts | Test package installation and RStudio server launch |
| Container Builds | Hadolint | Dockerfile linting for best practices |
| Manifest Validation | Kustomize + kubectl | Verify Kubernetes resource syntax |
| Image Availability | Shell Scripts | Check params.env references valid registry digests |

## Recent Changes

| Version | Date | Changes |
|---------|------|---------|
| 896a5954a | 2024-10-17 | - Merge pull request #400 (RHOAIENG-13278)<br>- Deactivate Habana notebook from manifests and repository docs |
| 8501f5c31 | 2024-10-14 | - Deactivate Habana notebook from manifests and repository docs |
| 0958a0f61 | 2024-10-14 | - Merge pull request #410 (fix28KubectlDownstream)<br>- Pin kustomize version in test infrastructure |
| 75ad655c6 | 2024-08-21 | - Pin kustomize version to specific release for CI stability |
| 2c2e35ade | 2024-07-23 | - Merge pull request #263 (downstreamCiImages)<br>- Add downstream CI image validation |
| 726ce2af3 | 2024-07-16 | - Fix commit ID reference for code-server image in manifests |
| 1d76b1cb1 | 2024-06-11 | - Fix/unify naming of variables used for code-server image |
| e5bbc9dec | 2024-05-09 | - Extend CI check for commit IDs of referenced images |
| 2ffabe4f8 | 2024-05-09 | - Extend CI image check to also include runtime images |
| 09d5b1f3e | 2024-06-11 | - Update GitHub Actions to use Node20 for compatibility |
| 4ff4a6fe3 | 2023-11-02 | - Add GitHub action to validate params.env file integrity |
| 42f103da2 | 2024-07-17 | - HotFix: Replace with correct branch ref instead of main |
| 7661f8cd5 | 2024-07-16 | - Update 2023b notebook version of TrustyAI to fix CVE-2023-47248 vulnerability |
| 999a6c711 | 2024-07-04 | - Merge pull request #299 (RHOAIENG-9257) |
| dcdcdba45 | 2024-07-01 | - Backport fix for PyTorch notebook build issues |
| e9e6e9e27 | 2024-06-12 | - Merge pull request #264 (static code checks on push) |
| 595947142 | 2024-05-29 | - Run static code checks on push and when manually triggered |
| b90e6210a | 2024-06-11 | - Merge pull request #262 (downstream CI Kustomize validation) |
| a45181391 | 2024-06-11 | - Add hadolint rule exclusions to make CI pass |
| b4abd071c | 2024-05-29 | - Add kubectl kustomize run to validate manifests definition in CI |

## Container Image Variants

### Python 3.9 (UBI9-based) - Current Production

| Image Name | Base | Key Packages | Target Use Case |
|------------|------|--------------|-----------------|
| base-ubi9-python-3.9 | UBI9 Python 3.9 | wheel, setuptools, oc CLI | Foundation for all UBI9 notebooks |
| jupyter-minimal-ubi9-python-3.9 | base-ubi9-python-3.9 | JupyterLab 3.6, jupyter-server-proxy, jupyterlab-git, nbgitpuller | Lightweight notebook for code development |
| jupyter-datascience-ubi9-python-3.9 | jupyter-minimal-ubi9-python-3.9 | pandas, scikit-learn, matplotlib, boto3, Elyra extensions, DB connectors | General data science and ML workflows |
| jupyter-pytorch-ubi9-python-3.9 | jupyter-datascience-ubi9-python-3.9 | PyTorch, torchvision | Deep learning with PyTorch framework |
| jupyter-tensorflow-ubi9-python-3.9 | cuda-jupyter-datascience-ubi9-python-3.9 | TensorFlow | Deep learning with TensorFlow framework |
| jupyter-trustyai-ubi9-python-3.9 | jupyter-datascience-ubi9-python-3.9 | TrustyAI SDK | Model explainability and bias detection |
| cuda-ubi9-python-3.9 | base-ubi9-python-3.9 + NVIDIA CUDA | CUDA runtime, cuDNN | GPU-accelerated base image |
| cuda-jupyter-minimal-ubi9-python-3.9 | cuda-ubi9-python-3.9 | JupyterLab 3.6 | GPU-enabled minimal notebook |
| cuda-jupyter-datascience-ubi9-python-3.9 | cuda-jupyter-minimal-ubi9-python-3.9 | Data science stack + CUDA | GPU-accelerated data science |
| runtime-minimal-ubi9-python-3.9 | base-ubi9-python-3.9 | Elyra dependencies | Lightweight Elyra pipeline execution |
| runtime-datascience-ubi9-python-3.9 | base-ubi9-python-3.9 | Data science stack for pipelines | Data science pipeline execution |
| runtime-pytorch-ubi9-python-3.9 | base-ubi9-python-3.9 | PyTorch for pipelines | PyTorch pipeline execution |
| runtime-tensorflow-ubi9-python-3.9 | cuda-ubi9-python-3.9 | TensorFlow for pipelines | TensorFlow GPU pipeline execution |

### Python 3.8 (UBI8-based) - Legacy Support

| Image Name | Base | Key Packages | Target Use Case |
|------------|------|--------------|-----------------|
| base-ubi8-python-3.8 | UBI8 Python 3.8 | wheel, setuptools, oc CLI | Foundation for all UBI8 notebooks |
| jupyter-minimal-ubi8-python-3.8 | base-ubi8-python-3.8 | JupyterLab 3.2, jupyter-server-proxy | Legacy minimal notebook |
| jupyter-datascience-ubi8-python-3.8 | jupyter-minimal-ubi8-python-3.8 | Older data science stack | Legacy data science workflows |
| jupyter-trustyai-ubi8-python-3.8 | jupyter-datascience-ubi8-python-3.8 | TrustyAI SDK | Legacy explainability workflows |
| cuda-ubi8-python-3.8 | base-ubi8-python-3.8 + NVIDIA CUDA | CUDA runtime | Legacy GPU base |
| habana-jupyter-1.9.0-ubi8-python-3.8 | jupyter-datascience-ubi8-python-3.8 + Habana 1.9.0 | Intel Habana Gaudi SDK | Intel Gaudi accelerator (v1.9.0) - deprecated |
| habana-jupyter-1.10.0-ubi8-python-3.8 | jupyter-datascience-ubi8-python-3.8 + Habana 1.10.0 | Intel Habana Gaudi SDK | Intel Gaudi accelerator (v1.10.0) - deprecated |
| habana-jupyter-1.11.0-ubi8-python-3.8 | jupyter-datascience-ubi8-python-3.8 + Habana 1.11.0 | Intel Habana Gaudi SDK | Intel Gaudi accelerator (v1.11.0) - deprecated |
| runtime-minimal-ubi8-python-3.8 | base-ubi8-python-3.8 | Elyra dependencies | Legacy pipeline execution |
| runtime-datascience-ubi8-python-3.8 | base-ubi8-python-3.8 | Data science stack | Legacy data science pipelines |
| runtime-pytorch-ubi8-python-3.8 | base-ubi8-python-3.8 | PyTorch | Legacy PyTorch pipelines |
| runtime-tensorflow-ubi8-python-3.8 | cuda-ubi8-python-3.8 | TensorFlow | Legacy TensorFlow pipelines |

### Alternative IDEs (CentOS Stream 9)

| Image Name | Base | Key Packages | Target Use Case |
|------------|------|--------------|-----------------|
| base-c9s-python-3.9 | CentOS Stream 9 | Python 3.9, oc CLI | Foundation for IDE images |
| code-server-c9s-python-3.9 | base-c9s-python-3.9 | code-server 4.x, nginx, Python extensions | VS Code in browser |
| rstudio-c9s-python-3.9 | base-c9s-python-3.9 | RStudio Server OSS, nginx, R | R programming IDE |
| cuda-rstudio-c9s-python-3.9 | cuda-c9s-python-3.9 | RStudio Server + CUDA | GPU-accelerated R development |

### RHEL9 (Enterprise Only)

| Image Name | Base | Key Packages | Target Use Case |
|------------|------|--------------|-----------------|
| base-rhel9-python-3.9 | RHEL9 Python 3.9 | wheel, setuptools, oc CLI | RHOAI enterprise base (requires RHEL subscription) |
| cuda-rhel9-python-3.9 | RHEL9 + NVIDIA CUDA | CUDA runtime | Enterprise GPU base |
| rstudio-rhel9-python-3.9 | RHEL9 | RStudio Server | Enterprise R IDE |

## Known Issues and Limitations

1. **Habana Notebooks Deprecated**: As of October 2024, Habana notebook images have been deactivated from manifests due to RHOAIENG-13278.
2. **Anaconda Images Deprecated**: Anaconda-based images are no longer actively maintained.
3. **Python 3.8 Legacy**: UBI8/Python 3.8 images are in maintenance mode; new features target UBI9/Python 3.9.
4. **GPU Memory Limits**: CUDA notebooks require explicit GPU resource requests/limits in notebook CR.
5. **Elyra Version Lock**: kfp-tekton pinned to <1.6.0 for Tekton pipeline compatibility.
6. **Database Drivers**: Some DB drivers (pyodbc for MS SQL) require OS-level ODBC libraries.
7. **Image Size**: Full data science images exceed 5GB due to ML framework dependencies.
8. **Build Time**: Layered image builds can take 30+ minutes for full rebuild.
9. **Registry Authentication**: Pulling from registry.redhat.io requires valid pull secrets.
10. **OpenShift-Specific**: Images assume OpenShift environment (oc CLI, OAuth proxy, Routes).

## Future Roadmap

1. **Python 3.11 Support**: Migrate to newer Python runtime for performance and security.
2. **JupyterLab 4.x**: Upgrade to JupyterLab 4.x with improved extension architecture.
3. **Konflux Build Integration**: Transition from manual builds to Konflux CI/CD pipeline.
4. **ARM64 Support**: Multi-architecture images for ARM-based clusters.
5. **Reduced Image Size**: Optimize layer caching and dependency pruning.
6. **Rootless Containers**: Full support for rootless Podman/cri-o execution.
7. **Enhanced GPU Support**: Multi-GPU and fractional GPU allocation.
8. **Alternative Kernels**: Support for additional languages (Julia, R kernel in Jupyter).

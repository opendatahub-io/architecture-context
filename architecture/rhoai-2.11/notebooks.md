# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-700-gb0968de8f
- **Branch**: rhoai-2.11
- **Distribution**: ODH and RHOAI
- **Languages**: Python, R, Shell, Dockerfile
- **Deployment Type**: Container Images (Workbench Environments)

## Purpose
**Short**: Provides container images for data science workbench environments including Jupyter notebooks, RStudio, and VS Code Server with pre-configured ML frameworks and libraries.

**Detailed**:
This repository contains the source code and build configurations for workbench container images used in OpenDataHub (ODH) and Red Hat OpenShift AI (RHOAI). These images provide browser-based integrated development environments (IDEs) for data scientists and ML engineers to develop, train, and test machine learning models. The repository supports multiple workbench types (Jupyter, RStudio, Code Server), various ML frameworks (TensorFlow, PyTorch, TrustyAI), and hardware acceleration options (NVIDIA CUDA, Intel Gaudi/Habana AI, AMD ROCm, Intel XPU). Images are built in layers starting from base images and adding specific dependencies, tools, and frameworks.

The workbench images are launched and managed by the ODH Notebook Controller component, which creates the necessary Kubernetes resources (StatefulSets, Services, Routes) and handles user authentication via OAuth proxy. These images expose web-based interfaces accessible through OpenShift Routes and provide isolated, reproducible environments for data science workloads.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Images | Foundation images with Python runtime, package managers (micropipenv), and OpenShift CLI (oc) |
| Jupyter Workbenches | Container Images | JupyterLab-based development environments with various ML framework configurations |
| CUDA Images | Container Images | GPU-accelerated images with NVIDIA CUDA Toolkit for compute-intensive workloads |
| Habana Images | Container Images | Images optimized for Intel Gaudi/Habana AI accelerators for deep learning training |
| Intel Images | Container Images | Images optimized for Intel XPU (GPU) with oneAPI libraries |
| AMD Images | Container Images | Images with AMD ROCm support for GPU-accelerated ML workloads |
| RStudio Workbenches | Container Images | RStudio Server IDE environments for R programming and statistical computing |
| Code Server Workbenches | Container Images | VS Code Server environments providing browser-based VS Code IDE |
| Runtime Images | Container Images | Lightweight images without JupyterLab UI for pipeline/workflow execution |
| ImageStream Manifests | OpenShift Resources | ImageStream definitions referencing built images with metadata for ODH Dashboard |
| BuildConfig Manifests | OpenShift Resources | BuildConfig definitions for building images within OpenShift (RStudio variants) |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define any CRDs. It provides container images that are consumed by the ODH Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/ | GET, POST | 8888/TCP | HTTP | None (TLS at Route) | OAuth Proxy | JupyterLab web interface |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None (TLS at Route) | OAuth Proxy | JupyterLab REST API for kernels, sessions |
| /notebook/{namespace}/{username}/lab | GET | 8888/TCP | HTTP | None (TLS at Route) | OAuth Proxy | JupyterLab application UI |
| /codeserver/healthz | GET | 8888/TCP | HTTP | None | None | Code Server health check endpoint |
| / | GET | 8888/TCP | HTTP | None (TLS at Route) | OAuth Proxy | RStudio Server web interface |

**Note**: Workbench containers expose HTTP on port 8888. Authentication and TLS termination are handled by OpenShift OAuth proxy and Routes created by the Notebook Controller.

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| registry.access.redhat.com/ubi9/python-39 | sha256:bbac8c29... | Yes | Base container image for UBI9 Python 3.9 workbenches |
| registry.access.redhat.com/ubi8/python-38 | Latest | Yes | Base container image for UBI8 Python 3.8 workbenches |
| JupyterLab | 3.6.x | Yes | Web-based interactive development environment |
| Notebook | 6.5.x | Yes | Jupyter Notebook server |
| TensorFlow | 2.x | No | Deep learning framework (TensorFlow workbenches only) |
| PyTorch | 2.x | No | Deep learning framework (PyTorch workbenches only) |
| NVIDIA CUDA Toolkit | 11.8, 12.x | No | GPU acceleration libraries (CUDA workbenches only) |
| Intel Habana SynapseAI | 1.9-1.13 | No | Habana Gaudi accelerator drivers (Habana workbenches only) |
| Intel oneAPI | Latest | No | Intel GPU optimization libraries (Intel workbenches only) |
| AMD ROCm | Latest | No | AMD GPU libraries (AMD workbenches only) |
| RStudio Server | 4.3 | No | R IDE server (RStudio workbenches only) |
| code-server | Latest | No | VS Code server (Code Server workbenches only) |
| OpenShift Client (oc) | Latest stable | Yes | OpenShift command-line tools |
| Elyra | Latest | No | JupyterLab extension for ML pipelines |
| Pandas | 1.5.x | Yes | Data manipulation library |
| NumPy | 1.24.x | Yes | Numerical computing library |
| Scikit-learn | 1.2.x | Yes | Machine learning library |
| Matplotlib | 3.6.x | Yes | Data visualization library |
| TrustyAI | Latest | No | Model explainability toolkit (TrustyAI workbenches only) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Consumes Images | Launches workbench pods from ImageStreams, manages lifecycle |
| ODH Dashboard | Reads ImageStream Metadata | Displays available workbench images to users with descriptions and versions |
| OAuth Proxy | Sidecar Container | Provides authentication/authorization for workbench access |
| OpenShift ImageStreams | Provides Images | References container images stored in Quay.io registry |
| OpenShift Routes | Network Access | Exposes workbench web interfaces to external users |
| PersistentVolumeClaims | Storage | Mounts user home directories for persistent notebook storage |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | Via OAuth Proxy | Internal |

**Note**: The Service is created by the Notebook Controller for each workbench instance, not by this repository's manifests.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} | OpenShift Route | {cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge Termination | External |

**Note**: Routes are created dynamically by the Notebook Controller with OAuth proxy for authentication.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Registry Auth | Pull container images |
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |
| conda repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Install Conda packages (Anaconda images) |
| github.com | 443/TCP | HTTPS | TLS 1.2+ | User SSH/Token | Git operations from notebooks |
| S3/Object Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Credentials | Data access from notebooks |
| mirror.openshift.com | 443/TCP | HTTPS | TLS 1.2+ | None | Download OpenShift CLI during image build |
| Red Hat registries | 443/TCP | HTTPS | TLS 1.2+ | Subscription Secrets | Pull base images during build |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. RBAC for workbench pods is managed by the ODH Notebook Controller.

### RBAC - Role Bindings

This component does not define RoleBindings. The Notebook Controller creates necessary service accounts and bindings.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription credentials for entitled builds | Administrator | No |
| {notebook-name}-oauth-config | Opaque | OAuth proxy configuration | Notebook Controller | No |
| {user-git-credentials} | kubernetes.io/ssh-auth | User Git credentials for repository access | User/Dashboard | No |
| {data-connection} | Opaque | S3/object storage credentials | User/Dashboard | No |

**Note**: Secrets in curly braces are created dynamically per workbench instance.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | GET, POST, PUT, DELETE | OAuth2 Bearer Token | OAuth Proxy Sidecar | User must own notebook or have admin role |
| /codeserver/* | GET, POST | OAuth2 Bearer Token | OAuth Proxy Sidecar | User must own notebook |
| /rstudio/* | GET, POST | OAuth2 Bearer Token | OAuth Proxy Sidecar | User must own notebook |

**Note**: In test/development deployments, authentication is disabled (--ServerApp.token='' --ServerApp.password=''). In production, OAuth proxy enforces OpenShift RBAC.

## Data Flows

### Flow 1: User Accesses Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy (Sidecar) | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift Session Cookie |
| 3 | OAuth Proxy | Notebook Container | 8888/TCP | HTTP | None (same pod) | None (authenticated by proxy) |
| 4 | Notebook Container | JupyterLab Process | localhost | HTTP | None | None |

### Flow 2: Notebook Pulls Data from S3

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Code | Python boto3 Library | N/A | N/A | N/A | N/A |
| 2 | Notebook Container | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM Credentials (from Secret) |
| 3 | S3 Service | Notebook Container | 443/TCP | HTTPS | TLS 1.2+ | N/A |

### Flow 3: Image Build and Push

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | BuildConfig/Konflux | Base Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 2 | Build Process | PyPI/Package Repos | 443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | Build Process | Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Push Credentials |
| 4 | ImageStream | Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

### Flow 4: Notebook Controller Launches Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | ODH Dashboard API | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 Bearer Token |
| 2 | ODH Dashboard | Kubernetes API | 443/TCP | HTTPS | mTLS | Service Account Token |
| 3 | Notebook Controller | Kubernetes API | 443/TCP | HTTPS | mTLS | Service Account Token |
| 4 | Kubelet | Container Registry (Quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Image Pull Secret |
| 5 | Kubelet | Starts Notebook Pod | N/A | N/A | N/A | N/A |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Kubernetes Resources | 6443/TCP | HTTPS | mTLS | Controller reads ImageStream metadata, creates StatefulSets/Services/Routes |
| ODH Dashboard | REST API / ImageStream Metadata | N/A | N/A | N/A | Dashboard queries ImageStream annotations to display workbench options |
| Quay.io Registry | Container Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Kubelet pulls workbench images |
| OAuth Proxy | HTTP Reverse Proxy | 8888/TCP | HTTP | None (same pod) | Sidecar container provides authentication before requests reach notebook |
| PersistentVolumeClaim | Volume Mount | N/A | N/A | N/A | Workbench pods mount PVCs for persistent user data storage |
| Elyra Runtime Images | Container Execution | Varies | Varies | Varies | Jupyter pipelines launch jobs using runtime images |
| OpenShift BuildConfig | Image Build | N/A | N/A | N/A | Builds RStudio images from source within OpenShift |

## Deployment Architecture

### Image Build Hierarchy

**Jupyter Workbenches (UBI9 Python 3.9)**:
```
base-ubi9-python-3.9
├── jupyter-minimal-ubi9-python-3.9
│   ├── jupyter-datascience-ubi9-python-3.9
│   │   ├── jupyter-tensorflow-ubi9-python-3.9
│   │   └── jupyter-pytorch-ubi9-python-3.9
│   └── jupyter-trustyai-ubi9-python-3.9
└── cuda-ubi9-python-3.9
    └── cuda-jupyter-minimal-ubi9-python-3.9
        └── cuda-jupyter-datascience-ubi9-python-3.9
```

**Hardware Accelerated Images**:
- **CUDA**: base-ubi9-python-3.9 → cuda-ubi9-python-3.9 → cuda-jupyter-*
- **Habana**: base-ubi8-python-3.8 → habana-{version}-ubi8-python-3.8 → jupyter-habana-*
- **Intel**: intel-base-gpu-ubi9-python-3.9 → jupyter-intel-ml/pytorch/tensorflow-ubi9-python-3.9
- **AMD**: amd-rhel9-python-3.9 → jupyter-amd-pytorch/tensorflow-ubi9-python-3.9

**Other Workbenches**:
- **Code Server**: codeserver-ubi9-python-3.9 (standalone)
- **RStudio**: rstudio-rhel9/c9s-python-3.9 (standalone, built via BuildConfig)

### Runtime Images

Lightweight images without JupyterLab UI for pipeline/workflow execution:
- runtime-minimal-ubi9-python-3.9
- runtime-datascience-ubi9-python-3.9
- runtime-pytorch-ubi9-python-3.9
- runtime-tensorflow-ubi9-python-3.9

### Image Registry and Distribution

- **Built Images**: Published to `quay.io/opendatahub/workbench-images` and `quay.io/modh/`
- **Image Tags**: Format `{workbench-type}-{os}-python-{version}-{release}-{date}-{commit}`
- **ImageStreams**: Reference multiple image tags (N, N-1, N-2, N-3) for version compatibility
- **RHOAI Images**: Built via Red Hat Konflux CI/CD pipeline
- **ODH Images**: Built via GitHub Actions and pushed to Quay.io

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2024-03 | b0968de8f | - feat(Rstudio): update branch rhoai-2.11 for the rstudio builds (#306) |
| 2024-03 | e5963a6b0 | - [Digest Updater Action] Update Notebook Images (#295) |
| 2024-03 | 41199e990 | - Update file via digest-updater-9712922548 GitHub action |
| 2024-03 | 797e66d72 | - Merge branch 'main' of opendatahub-io/notebooks into rsync-main |
| 2024-02 | 02f9de312 | - chores: Include the update to the build-notebook CI<br>- chores: Fix the makefile for amd calls and upgrade odh-elyra |
| 2024-02 | d35ed71fd | - Upgrade codeflare-sdk with the latest 0.16.4 |
| 2024-02 | 9f0a83769 | - Setup build images for Pytorch & Tensorflow with base ROCm image (#557) |
| 2024-02 | ea7f4675c | - ci: increase available disk space for GHA container image builds (#577) |
| 2024-02 | 5ca446dc5 | - Replace fcgi with supervisord on rstudio rhel flavor |
| 2024-01 | 7bfbf321c | - Limit PR checks to build only the modified images (#558) |

## Component Interactions

### Workbench Lifecycle

1. **Image Publication**: CI/CD builds images and pushes to Quay.io registry
2. **ImageStream Creation**: Administrator applies ImageStream manifests to OpenShift cluster
3. **Dashboard Discovery**: ODH Dashboard reads ImageStream annotations to populate workbench catalog
4. **User Selection**: User selects workbench type, size, and accelerators via Dashboard UI
5. **Notebook Controller Action**: Controller creates StatefulSet, Service, Route, and OAuth proxy
6. **Pod Startup**: Kubelet pulls image from Quay.io and starts notebook container
7. **Route Access**: User accesses workbench via HTTPS Route with OAuth authentication
8. **Data Access**: Workbench code accesses S3, databases, and other services using mounted secrets
9. **Shutdown**: User stops workbench, Controller deletes resources, PVC persists user data

### Supported Workbench Images (RHOAI 2.11)

| Workbench | Python | R | JupyterLab | Code Server | RStudio | GPU Support | Runtime Available |
|-----------|--------|---|------------|-------------|---------|-------------|-------------------|
| Minimal | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| Data Science | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✓ |
| TensorFlow | ✓ | ✗ | ✓ | ✗ | ✗ | CUDA | ✓ |
| PyTorch | ✓ | ✗ | ✓ | ✗ | ✗ | CUDA | ✓ |
| TrustyAI | ✓ | ✗ | ✓ | ✗ | ✗ | ✗ | ✗ |
| Habana | ✓ | ✗ | ✓ | ✗ | ✗ | Gaudi | ✗ |
| Intel ML | ✓ | ✗ | ✓ | ✗ | ✗ | XPU | ✗ |
| AMD PyTorch | ✓ | ✗ | ✓ | ✗ | ✗ | ROCm | ✗ |
| AMD TensorFlow | ✓ | ✗ | ✓ | ✗ | ✗ | ROCm | ✗ |
| Code Server | ✓ | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| RStudio | ✓ | ✓ | ✗ | ✗ | ✓ | Optional CUDA | ✗ |

## Build and Test Infrastructure

### Makefile Targets

- **Image Build**: `make {workbench-name}` - Builds specific workbench image
- **Deploy Test**: `make deploy9-{workbench-name}` - Deploys test instance to cluster
- **Test Suite**: `make test-{workbench-name}` - Runs validation tests
- **Runtime Validation**: `make validate-runtime-image image={image}` - Validates runtime image compatibility
- **Cleanup**: `make undeploy9-{workbench-name}` - Removes test deployment

### CI/CD Pipeline

- **GitHub Actions**: Automated builds for ODH images on push/PR
- **Red Hat Konflux**: Builds RHOAI images with enterprise security scanning
- **Security Scanning**: Hadolint (Dockerfile linting), vulnerability scanning
- **Image Signing**: RHOAI images are signed for supply chain security
- **Digest Updates**: Automated PRs update base image digests

### Testing Strategy

1. **Dockerfile Linting**: Hadolint validation of Dockerfile best practices
2. **YAML Validation**: yamllint checks on manifest files
3. **Runtime Commands**: Validates required binaries exist (curl, python, oc, etc.)
4. **Container Startup**: Ensures workbench starts and responds to health checks
5. **API Validation**: Tests JupyterLab API endpoints respond correctly
6. **Package Import**: Validates key Python libraries can be imported

## Notes

- **No CRDs Defined**: This repository provides container images, not Kubernetes operators or controllers
- **No RBAC Resources**: Security policies are enforced by Notebook Controller and OAuth proxy
- **Image Versioning**: Follows release-based tagging (2024.1, 2024.2) with N, N-1, N-2 support
- **Base Image Updates**: Automated digest updater keeps base images current for security patches
- **Hardware Acceleration**: GPU/accelerator support requires appropriate NodeSelector and tolerations set by Notebook Controller
- **Persistent Storage**: User data persists in PVCs mounted at `/opt/app-root/src`
- **Runtime Images**: Lightweight variants without JupyterLab for Kubeflow Pipelines and Elyra workflows
- **Custom Packages**: Users can install additional packages at runtime using pip/conda
- **Elyra Integration**: Supports visual pipeline authoring and execution in JupyterLab
- **Multi-Architecture**: Some images support both x86_64 and aarch64 architectures

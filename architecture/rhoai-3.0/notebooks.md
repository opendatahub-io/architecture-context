# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks.git
- **Version**: v3.0.0-1-g1c4670fc7
- **Branch**: rhoai-3.0
- **Distribution**: RHOAI
- **Languages**: Python 3.12, R 4.5.1, Bash, Makefile
- **Deployment Type**: Container Images (Workbenches)

## Purpose
**Short**: Provides containerized workbench images (Jupyter, RStudio, CodeServer) and pipeline runtime images for data science workflows in RHOAI.

**Detailed**: This repository builds and maintains containerized workbench environments that data scientists use to develop, train, and deploy machine learning models in Red Hat OpenShift AI. It provides three types of images: (1) JupyterLab-based workbenches with variants for minimal, data science, PyTorch, TensorFlow, and TrustyAI workflows, (2) RStudio Server workbenches for R-based data analysis, and (3) CodeServer workbenches for VS Code-like development environments. All images support CPU architectures (x86_64, aarch64, ppc64le, s390x) with GPU-accelerated variants available for NVIDIA CUDA and AMD ROCm. Additionally, the repository provides runtime-only images (without UI) for use in data science pipelines. Images are built using Konflux CI/CD pipelines and deployed as ImageStreams in OpenShift, integrated with the ODH Notebook Controller for workbench lifecycle management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Jupyter Minimal | Container Image | Minimal JupyterLab environment with Python 3.12 and basic data science tools |
| Jupyter DataScience | Container Image | JupyterLab with comprehensive data science libraries (pandas, numpy, scikit-learn, database clients) |
| Jupyter PyTorch | Container Image | JupyterLab with PyTorch for deep learning and computer vision workloads |
| Jupyter TensorFlow | Container Image | JupyterLab with TensorFlow for machine learning model training |
| Jupyter TrustyAI | Container Image | JupyterLab with TrustyAI libraries for model explainability and monitoring |
| Jupyter PyTorch LLMCompressor | Container Image | JupyterLab with PyTorch and LLMCompressor for large language model optimization |
| RStudio Server | Container Image | RStudio IDE for R-based statistical computing and graphics |
| CodeServer | Container Image | Browser-based VS Code IDE for collaborative development |
| Runtime Images | Container Image | Headless versions of workbenches for Kubeflow pipeline execution (no UI) |
| Base Images | Container Image | Foundation images with CPU, CUDA 12.8, or ROCm 6.3/6.4 support |
| NGINX Proxy | Service Component | Reverse proxy for RStudio and CodeServer web interfaces |
| Apache httpd | Service Component | Web server for RStudio authentication and session management |

## APIs Exposed

### Custom Resource Definitions (CRDs)

None - this component provides container images consumed by the ODH Notebook Controller, which manages the Notebook CRD.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /lab | GET, POST | 8888/TCP | HTTP | None | Token/OAuth | JupyterLab main interface |
| /api/kernels | GET, POST | 8888/TCP | HTTP | None | Token/OAuth | Jupyter kernel management API |
| /api/sessions | GET, POST | 8888/TCP | HTTP | None | Token/OAuth | Jupyter session management |
| / | GET, POST | 8080/TCP | HTTP | None | Basic Auth | RStudio Server web interface (behind nginx proxy) |
| / | GET | 8888/TCP | HTTP | None | Token/OAuth | RStudio nginx proxy (external port) |
| / | GET | 8787/TCP | HTTP | None | None | CodeServer web interface (behind nginx proxy) |
| / | GET | 8888/TCP | HTTP | None | Token/OAuth | CodeServer nginx proxy (external port) |
| /healthz | GET | 8888/TCP | HTTP | None | None | Health check endpoint for all workbenches |

### gRPC Services

None - workbenches expose HTTP-only interfaces.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Python | 3.12 | Yes | Primary runtime for Jupyter and data science libraries |
| R | 4.5.1 | Yes (RStudio) | Statistical computing runtime for RStudio workbenches |
| JupyterLab | 4.4 | Yes (Jupyter) | Web-based interactive development environment |
| PyTorch | 2.x | Yes (PyTorch images) | Deep learning framework |
| TensorFlow | 2.16+ | Yes (TensorFlow images) | Machine learning framework |
| NVIDIA CUDA Toolkit | 12.8 | Yes (CUDA images) | GPU acceleration for NVIDIA GPUs |
| AMD ROCm | 6.3, 6.4 | Yes (ROCm images) | GPU acceleration for AMD GPUs |
| RStudio Server | 2025.09.0-387 | Yes (RStudio) | R IDE server component |
| code-server | v4.104.0 | Yes (CodeServer) | VS Code server for browser-based development |
| Node.js | 22.18.0 | Yes (CodeServer) | JavaScript runtime for code-server |
| NGINX | Latest (UBI9) | Yes (RStudio/CodeServer) | Reverse proxy for web interfaces |
| Apache httpd | Latest (UBI9) | Yes (RStudio) | Web server for RStudio authentication |
| OpenShift CLI (oc) | stable | Yes | Kubernetes/OpenShift cluster interaction from workbenches |
| Elyra | Latest | Optional | Visual pipeline editor for Kubeflow Pipelines |
| Pandas | Latest | Yes (DataScience) | Data manipulation and analysis |
| NumPy | Latest | Yes (DataScience) | Numerical computing library |
| Scikit-learn | Latest | Yes (DataScience) | Machine learning library |
| TrustyAI | Latest | Yes (TrustyAI) | Model explainability and monitoring |
| LLMCompressor | Latest | Yes (LLMCompressor) | Large language model optimization toolkit |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | CRD | Manages notebook pod lifecycle and authentication |
| ODH Dashboard | UI Integration | Displays available workbench images via ImageStream metadata |
| Kubeflow Pipelines | Runtime Execution | Executes pipeline components using runtime images |
| Model Registry | Optional Integration | Stores and versions trained models from workbenches |
| Data Science Pipelines | Pipeline Integration | Orchestrates ML workflows using runtime images |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | None | OAuth Proxy | Internal |

**Note**: Services are dynamically created by the ODH Notebook Controller for each workbench instance. The service name follows the pattern `notebook-{workbench-name}`.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook-name} | OpenShift Route | *.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

**Note**: Routes are dynamically created by the ODH Notebook Controller with OAuth proxy sidecar for authentication.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI (files.pythonhosted.org) | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation |
| CRAN (cran.rstudio.com) | 443/TCP | HTTPS | TLS 1.2+ | None | R package installation |
| GitHub (github.com) | 443/TCP | HTTPS | TLS 1.2+ | Token | Git repository access |
| Quay.io (quay.io) | 443/TCP | HTTPS | TLS 1.2+ | Token | Container image pulls |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.3 | Bearer Token | Kubernetes API access via oc CLI |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Data and model storage |
| Object Storage | 443/TCP | HTTPS | TLS 1.2+ | Credentials | Training data access |

## Security

### RBAC - Cluster Roles

None - workbench containers run with the privileges of the notebook service account managed by ODH Notebook Controller.

### RBAC - Role Bindings

None - RBAC is managed by the ODH Notebook Controller at the notebook pod level.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {notebook-name}-oauth-config | Opaque | OAuth proxy configuration | ODH Notebook Controller | No |
| {notebook-name}-oauth-cookie-secret | Opaque | OAuth session cookies | ODH Notebook Controller | No |
| git-credentials | kubernetes.io/basic-auth | Git repository authentication | User | No |
| aws-credentials | Opaque | S3 storage access | User | No |
| database-credentials | Opaque | Database connection credentials | User | No |

**Note**: Secret names vary based on user configuration; these are common patterns.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /lab | GET, POST, WS | OAuth Proxy (OpenShift) | OAuth Proxy Sidecar | User must have access to notebook namespace |
| / (RStudio) | GET, POST | OAuth Proxy (OpenShift) | OAuth Proxy Sidecar | User must have access to notebook namespace |
| / (CodeServer) | GET, POST | OAuth Proxy (OpenShift) | OAuth Proxy Sidecar | User must have access to notebook namespace |
| Internal Services | All | Service Account Token | Kubernetes RBAC | Workbench service account permissions |

## Data Flows

### Flow 1: User Access to Jupyter Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | OpenShift Session |
| 3 | OAuth Proxy Sidecar | JupyterLab Container | 8888/TCP | HTTP | None | Authenticated |
| 4 | JupyterLab Container | Jupyter Kernel | Internal | IPC | None | Local Process |

### Flow 2: Workbench to S3 Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workbench Container | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM Credentials |
| 2 | S3 Endpoint | Object Storage Backend | Internal | Protocol-specific | Service Mesh mTLS | Service Identity |

### Flow 3: Pipeline Runtime Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KFP Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 2 | Kubernetes API | Runtime Container | Internal | Container Runtime | None | None |
| 3 | Runtime Container | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM Credentials |
| 4 | Runtime Container | Model Registry | 8080/TCP | HTTP | Service Mesh mTLS | Bearer Token |

### Flow 4: CodeServer to Git Repository

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CodeServer Container | GitHub | 443/TCP | HTTPS | TLS 1.2+ | Git Credentials |
| 2 | CodeServer Container | Internal Git Server | 22/TCP | SSH | SSH | SSH Key |

### Flow 5: RStudio Package Installation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | RStudio Container | CRAN Repository | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | RStudio Container | Bioconductor | 443/TCP | HTTPS | TLS 1.2+ | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.3 | Workbench pod lifecycle management |
| ODH Dashboard | ImageStream API | 6443/TCP | HTTPS | TLS 1.3 | Discover available workbench images |
| OAuth Proxy | HTTP Proxy | 8888/TCP | HTTP | None | Authentication delegation |
| Kubeflow Pipelines | Container Execution | N/A | N/A | N/A | Execute pipeline steps using runtime images |
| Model Registry | REST API | 8080/TCP | HTTP | Service Mesh mTLS | Register trained models |
| Prometheus | Metrics Scrape | N/A | N/A | N/A | Not currently implemented |
| Git (GitHub/GitLab) | Git Protocol | 443/TCP, 22/TCP | HTTPS, SSH | TLS 1.2+, SSH | Source code versioning |
| Container Registry (Quay) | Container Pull | 443/TCP | HTTPS | TLS 1.2+ | Pull base and utility images |

## Build and Deployment Architecture

### Build Process

| Stage | Tool | Input | Output | Location |
|-------|------|-------|--------|----------|
| 1. Source Checkout | Git | GitHub repository | Source code | Konflux build container |
| 2. Base Image Build | Podman/Docker | Dockerfile.konflux.{cpu,cuda,rocm} | Base images | Konflux pipeline |
| 3. Workbench Build | Podman/Docker | Dockerfile.konflux.{variant} | Workbench images | Konflux pipeline |
| 4. Image Scan | Clair/Snyk | Container image | Vulnerability report | Konflux pipeline |
| 5. Image Sign | Cosign | Container image | Signed image | Konflux pipeline |
| 6. Image Push | Skopeo | Signed image | Quay.io registry | Konflux pipeline |
| 7. Manifest Generation | Kustomize | params.env | ImageStream YAML | manifests/base/ |

### Deployment Artifacts

| Artifact Type | Location | Purpose |
|---------------|----------|---------|
| ImageStream | manifests/base/*.yaml | Defines available workbench images in OpenShift |
| ConfigMap | manifests/base/params.env | Image tags and metadata |
| Kustomization | manifests/base/kustomization.yaml | Kustomize overlay configuration |
| Dockerfile.konflux | */Dockerfile.konflux.* | Konflux-specific build definitions (RHOAI production builds) |
| Dockerfile | */Dockerfile.* | Local/ODH build definitions |

### Image Variants

| Variant | Python | OS | Accelerator | Architectures | Container Size |
|---------|--------|----|-----------|--------------| ---------------|
| minimal-cpu | 3.12 | UBI9 | None | x86_64, aarch64, ppc64le, s390x | ~1.5 GB |
| datascience-cpu | 3.12 | UBI9 | None | x86_64, aarch64, ppc64le, s390x | ~3.5 GB |
| pytorch-cuda | 3.12 | UBI9 | CUDA 12.8 | x86_64, aarch64 | ~8 GB |
| tensorflow-cuda | 3.12 | UBI9 | CUDA 12.8 | x86_64, aarch64 | ~8 GB |
| pytorch-rocm | 3.12 | UBI9 | ROCm 6.3 | x86_64 | ~10 GB |
| tensorflow-rocm | 3.12 | UBI9 | ROCm 6.3 | x86_64 | ~10 GB |
| trustyai-cpu | 3.12 | UBI9 | None | x86_64, aarch64, ppc64le | ~3 GB |
| codeserver-cpu | 3.12 | UBI9 | None | x86_64, aarch64, ppc64le, s390x | ~2.5 GB |
| rstudio-cpu | 3.12 (R 4.5.1) | C9S | None | x86_64, aarch64 | ~3 GB |
| rstudio-cuda | 3.12 (R 4.5.1) | C9S | CUDA 12.8 | x86_64, aarch64 | ~7 GB |

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2025-11-14 | 1c4670fc7 | - Sync pipelineruns with konflux-central |
| 2025-11-09 | adfa5b3fb | - Merge pull request #1681: Retrigger TensorFlow CUDA build for RHOAI 3.0<br>- Rebuild cuda-tensorflow image for RHOAI 3.0 |
| 2025-11-08 | e82841764 | - Retrigger for CodeFlareSDK update on jupyter-cuda-tensorflow (RHOAI 3.0) |
| 2025-11-07 | 0d0be7466 | - Update Codeflare-SDK to 0.32.1 and lock dependencies |
| 2025-10-27 | d2c2a6877 | - RHAIENG-1643: Fix Pyarrow build for s390x architecture |
| 2025-10-27 | 1183d2207 | - Sync pipelineruns with konflux-central (d1fb6ac) |
| 2025-10-24 | fbb85f997 | - NO-JIRA: Sync ODH changes to Dockerfile.konflux files in RHDS |
| 2025-10-24 | 72a674131 | - RHAIENG-1602: Create .so symbolic links for ROCm 6.3.4 TensorFlow compatibility |
| 2025-10-24 | a61506816 | - RHAIENG-495: Add gettext for envsubst in run-nginx.sh |
| 2025-10-23 | 9924a1f94 | - RHAIENG-287: Skip tf2onnx conversion test for TensorFlow 2.16+ incompatibility |

## Container Image Lifecycle

### Image Tagging Strategy

| Tag Pattern | Purpose | Example |
|-------------|---------|---------|
| 2025.2 | Current release (N) | jupyter-minimal-cpu-py312-ubi9:2025.2 |
| 2025.1 | Previous release (N-1) | jupyter-minimal-cpu-py312-ubi9:2025.1 |
| 2024.2 | Older release (N-2) | jupyter-minimal-cpu-py311-ubi9:2024.2 |
| {release}_{date} | Daily build | jupyter-minimal-cpu-py312-ubi9:2025b_20250315 |
| latest | Development | Not recommended for production |

### Support Policy

- **Supported Versions**: Current (N) and previous (N-1) releases
- **Minimum Support Duration**: 12 months per release
- **Update Frequency**: Major updates every 6 months
- **Security Patches**: Applied to supported releases within 14 days of disclosure
- **Deprecated Tags**: Marked with `opendatahub.io/image-tag-outdated: "true"` annotation

## Testing and Quality

### Test Types

| Test Type | Framework | Scope | Execution |
|-----------|-----------|-------|-----------|
| Unit Tests | pytest | Python scripts, utilities | CI pipeline |
| Container Tests | testcontainers | Image startup, health checks | CI pipeline, local |
| Browser Tests | Playwright | UI functionality | Manual, CI pipeline |
| Integration Tests | pytest + Kubernetes | Multi-component workflows | OpenShift cluster |
| Vulnerability Scans | Clair, Snyk | Container image CVEs | Konflux pipeline |

### Quality Gates

- All tests must pass before image promotion
- No HIGH or CRITICAL CVEs allowed in production images
- Multi-architecture builds required (x86_64, aarch64, ppc64le, s390x for CPU variants)
- Image size must not exceed baseline + 20% without justification

## Operational Considerations

### Resource Requirements

| Workbench Type | CPU Request | CPU Limit | Memory Request | Memory Limit | Storage |
|----------------|-------------|-----------|----------------|--------------|---------|
| Minimal | 0.5 cores | 2 cores | 1 GiB | 4 GiB | 20 GiB PVC |
| DataScience | 1 core | 4 cores | 2 GiB | 8 GiB | 20 GiB PVC |
| PyTorch/TensorFlow (CPU) | 2 cores | 8 cores | 4 GiB | 16 GiB | 40 GiB PVC |
| PyTorch/TensorFlow (GPU) | 4 cores | 16 cores | 8 GiB | 32 GiB | 100 GiB PVC + GPU |
| RStudio | 1 core | 4 cores | 2 GiB | 8 GiB | 20 GiB PVC |
| CodeServer | 0.5 cores | 2 cores | 1 GiB | 4 GiB | 20 GiB PVC |

**Note**: These are recommended defaults; users can customize via ODH Dashboard.

### Monitoring and Health

| Metric | Endpoint | Method | Success Criteria |
|--------|----------|--------|------------------|
| Liveness | /healthz | HTTP GET | 200 OK response |
| Readiness | /api/status | HTTP GET | 200 OK response, kernels ready |
| Startup | Container readiness probe | Container state | Running within 120s |

### Backup and Recovery

- **User Data**: Stored on PersistentVolumeClaims (PVCs); backup via Velero or storage snapshots
- **Configuration**: Workbench configuration stored in notebook CR; backup via GitOps
- **Recovery Time Objective (RTO)**: < 15 minutes (recreate pod from ImageStream)
- **Recovery Point Objective (RPO)**: Depends on PVC snapshot frequency (user-configurable)

## Known Limitations

1. **IPv6 Support**: Partial - CodeServer and RStudio detect and bind to IPv6 when available
2. **GPU Sharing**: Not supported - each GPU-enabled workbench requires dedicated GPU
3. **Multi-User Jupyter**: Not supported - each user gets isolated workbench pod
4. **Persistent Extensions**: User-installed JupyterLab extensions require PVC; not included in image
5. **Architecture Support**: ROCm images limited to x86_64; CUDA aarch64 support planned
6. **Image Size**: GPU images exceed 8 GB due to framework and CUDA/ROCm libraries
7. **Startup Time**: GPU workbenches may take 60-120 seconds due to driver initialization
8. **Python Version**: Single Python version per image (currently 3.12); no multi-version support

## Future Enhancements

- Support for Python 3.13 workbenches (planned for 2026.1 release)
- Integration with MLflow for experiment tracking
- Pre-built AI/ML model serving integration
- GPU time-slicing support for cost optimization
- Distroless base images for reduced attack surface
- Automated dependency updates via Renovate
- Enhanced telemetry and usage metrics collection

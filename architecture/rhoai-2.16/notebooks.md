# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks.git
- **Version**: v20xx.1-462-g3e30c4b17
- **Branch**: rhoai-2.16
- **Distribution**: RHOAI
- **Languages**: Python, Dockerfile, Shell, Makefile
- **Deployment Type**: Container Images (deployed as StatefulSets by Notebook Controller)

## Purpose
**Short**: Provides pre-built workbench container images (JupyterLab, RStudio, Code Server) for interactive data science development in RHOAI.

**Detailed**: This repository builds and maintains a collection of workbench images that serve as interactive development environments for data scientists within the Red Hat OpenShift AI platform. These images are not standalone services but are container definitions that get deployed by the ODH Notebook Controller when users create workbenches through the RHOAI dashboard.

The repository provides multiple image variants optimized for different use cases: minimal Python environments, data science stacks with common ML libraries, GPU-accelerated images with CUDA/ROCm support, framework-specific images (PyTorch, TensorFlow), specialized images (TrustAI, Intel optimizations), and alternative IDEs (RStudio for R, Code Server for VS Code). Each workbench runs JupyterLab or equivalent IDE and integrates with Data Science Pipelines through Elyra extensions. The images support multiple Python versions (3.9, 3.11) and base OS variants (UBI9, RHEL9, CentOS Stream 9).

Images are published as OpenShift ImageStreams with multiple version tags (N, N-1, N-2, etc.) for version compatibility and rollback support. The manifests use Kustomize to configure these ImageStreams with metadata annotations that the RHOAI dashboard uses to present workbench options to users.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image | Foundation layer with Python, pip, OpenShift client (oc), and common utilities |
| Jupyter Minimal | Container Image | Lightweight JupyterLab 4.2 environment with Python kernel |
| Jupyter Data Science | Container Image | JupyterLab with Elyra, data science libraries (pandas, scikit-learn), database clients |
| Jupyter PyTorch | Container Image | PyTorch-optimized environment with GPU support |
| Jupyter TensorFlow | Container Image | TensorFlow-optimized environment with GPU support |
| Jupyter TrustAI | Container Image | JupyterLab with TrustAI libraries for explainable AI |
| CUDA Images | Container Image | NVIDIA CUDA-enabled base images for GPU workloads |
| ROCm Images | Container Image | AMD ROCm-enabled images for AMD GPU support |
| Intel Images | Container Image | Intel-optimized images (oneAPI, XPU support) |
| Code Server | Container Image | VS Code in browser for Python development |
| RStudio Server | Container Image | RStudio IDE for R language development |
| Runtime Images | Container Image | Lightweight versions for Data Science Pipeline execution (no IDE) |
| ImageStream Manifests | Kubernetes Manifest | OpenShift ImageStreams defining available workbench images |
| BuildConfig Manifests | Kubernetes Manifest | In-cluster build configurations for RStudio images |

## APIs Exposed

### Custom Resource Definitions (CRDs)

No CRDs defined. Workbenches are launched via `Notebook` CRDs managed by the ODH Notebook Controller component.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | OAuth Proxy | JupyterLab web interface |
| /api | GET, POST | 8888/TCP | HTTP | None | OAuth Proxy | Jupyter Server REST API |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None | OAuth Proxy | Namespaced Jupyter API endpoint |
| /lab | GET | 8888/TCP | HTTP | None | OAuth Proxy | JupyterLab UI |
| /rstudio | GET | 8888/TCP | HTTP | None | OAuth Proxy | RStudio Server interface (RStudio images only) |

**Note**: Encryption and authentication are provided by OAuth proxy sidecar container injected by Notebook Controller, not by the workbench container itself.

### gRPC Services

None exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9 Python | 3.9, 3.11 | Yes | Base container image from Red Hat |
| JupyterLab | 4.2, 3.6 | Yes | Interactive notebook environment |
| Elyra | 3.x | No | Pipeline authoring and notebook orchestration |
| PyTorch | 2.x | No | Deep learning framework (PyTorch images) |
| TensorFlow | 2.x | No | Deep learning framework (TensorFlow images) |
| NVIDIA CUDA | 11.x, 12.x | No | GPU acceleration (CUDA images) |
| AMD ROCm | 5.x, 6.x | No | GPU acceleration (ROCm images) |
| Intel oneAPI | Latest | No | Intel XPU optimization (Intel images) |
| Code Server | 4.x | No | VS Code in browser (Code Server images) |
| RStudio Server | 2024.04.2 | No | R IDE (RStudio images) |
| OpenShift CLI | Latest stable | Yes | oc command for cluster interaction |
| MongoDB CLI | 6.0 | No | MongoDB client tools (Data Science images) |
| MSSQL Tools | 2022 | No | Microsoft SQL Server client (Data Science images) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Launches/Manages | Creates StatefulSet and Service for workbench instances |
| Data Science Pipelines | Elyra Integration | Submit pipeline runs from notebooks via Elyra extension |
| OAuth Proxy | Sidecar Container | Provides authentication and TLS termination |
| Model Registry | API Client | Register and retrieve ML models from notebooks |
| Model Serving (KServe) | API Client | Deploy models to inference endpoints |
| S3 Storage | Object Storage | Store notebooks, datasets, model artifacts |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal (accessed via OAuth proxy) |

**Note**: Each workbench instance gets its own Service named `notebook` in the user's namespace. The OAuth proxy sidecar provides TLS termination and authentication before traffic reaches port 8888.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| Workbench Route | OpenShift Route | {cluster-apps-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

**Note**: Routes are created by the Notebook Controller, not by this repository. Routes terminate TLS and forward to the OAuth proxy on port 8443.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI/pip repositories | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |
| Data Science Pipeline API | 8888/TCP | HTTP | mTLS | Service Account Token | Submit pipeline runs via Elyra |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 | Read/write datasets and models |
| Model Registry API | 8080/TCP | HTTP | mTLS | Service Account Token | Register and query ML models |
| KServe Inference Endpoints | 8080/TCP, 8443/TCP | HTTP/HTTPS | TLS 1.2+ (optional) | Service Account Token | Invoke model predictions |
| OpenShift API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | oc CLI operations |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH keys/tokens | Clone notebooks and code |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull base images during builds |
| External databases | 5432/TCP, 3306/TCP, 27017/TCP | TCP | TLS (varies) | User credentials | Connect to PostgreSQL, MySQL, MongoDB |

## Security

### RBAC - Cluster Roles

No ClusterRoles defined in this repository. RBAC is managed by the Notebook Controller which creates per-notebook ServiceAccounts and RoleBindings.

### RBAC - Role Bindings

No RoleBindings defined in this repository. The Notebook Controller creates RoleBindings to allow the workbench ServiceAccount to access namespace resources.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription for RStudio BuildConfig | Platform Admin | No |
| aws-connection-* | Opaque | S3 credentials for data access | User/Admin | No |
| git-credentials | kubernetes.io/ssh-auth | Git repository authentication | User | No |
| database-credentials | Opaque | Database connection credentials | User/Admin | No |

**Note**: Secrets are mounted by the Notebook Controller based on user configuration, not hardcoded in the image.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| / (all paths) | All | OAuth2 (OpenShift) | OAuth Proxy Sidecar | User must be notebook owner or have namespace access |
| /api | GET, POST | Bearer Token (OAuth) | OAuth Proxy Sidecar | Same user as notebook creator |

**Note**: Workbench containers run as non-root user (UID 1001). SELinux and seccomp policies enforced by OpenShift.

## Data Flows

### Flow 1: User Accesses Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 Cookie |
| 3 | OAuth Proxy | JupyterLab Container | 8888/TCP | HTTP | None (localhost) | Forwarded user headers |

### Flow 2: Submit Data Science Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Elyra (in notebook) | Data Science Pipeline API | 8888/TCP | HTTP | mTLS | Service Account Token |
| 2 | DSP API | Argo Workflows | 2746/TCP | HTTP | mTLS | Service Account Token |
| 3 | Argo Workflow | Runtime Image (from this repo) | N/A | N/A | N/A | Pipeline execution in pod |

### Flow 3: Install Python Package at Runtime

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | pip (in notebook) | PyPI Registry | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | PyPI | pip | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 4: Access S3 Data Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | boto3/s3fs (in notebook) | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 (from mounted secret) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | Metadata Consumer | N/A | N/A | N/A | Reads ImageStream annotations to display workbench options |
| Notebook Controller | Pod Launcher | N/A | N/A | N/A | Creates StatefulSet from selected image |
| Data Science Pipelines | REST API Client | 8888/TCP | HTTP | mTLS | Submit pipeline runs via Elyra |
| Model Registry | REST API Client | 8080/TCP | HTTP | mTLS | Register trained models |
| KServe | REST API Client | 8080/TCP, 8443/TCP | HTTP/HTTPS | TLS 1.2+ | Deploy models for inference |
| OpenShift OAuth | OAuth2 Client | 6443/TCP | HTTPS | TLS 1.2+ | Authenticate users via proxy |
| S3 Storage | S3 API Client | 443/TCP | HTTPS | TLS 1.2+ | Persist notebooks and data |

## Build and Release

### Image Build Pipeline

Images are built via Konflux CI/CD pipeline (transitioning from legacy builds):
1. **Base images**: Built from `base/{os}-python-{version}/Dockerfile`
2. **Layered images**: Built on top of base images (e.g., minimal → datascience)
3. **Specialized images**: GPU, ROCm, Intel variants built with hardware-specific dependencies
4. **Version tagging**: Multiple versions (N, N-1, N-2, N-3, N-4) maintained in ImageStreams
5. **Manifest updates**: `params.env` updated with image digests via automated GitHub Actions

### Image Variants Matrix

| Base OS | Python Version | Variants |
|---------|----------------|----------|
| UBI9 | 3.9, 3.11 | Base, Minimal, DataScience, PyTorch, TensorFlow, TrustAI, Code Server |
| RHEL9 | 3.9, 3.11 | Base, RStudio, CUDA (3.11 only for CUDA) |
| CentOS Stream 9 | 3.9, 3.11 | Base, CUDA, RStudio |
| UBI9 + CUDA | 3.9, 3.11 | Minimal GPU, PyTorch, TensorFlow |
| UBI9 + ROCm | 3.9, 3.11 | Minimal, PyTorch, TensorFlow |
| UBI9 + Intel | 3.9, 3.11 | ML, PyTorch, TensorFlow |

## Deployment Configuration

### Kustomize Structure

```
manifests/
├── base/
│   ├── kustomization.yaml
│   ├── jupyter-minimal-notebook-imagestream.yaml
│   ├── jupyter-datascience-notebook-imagestream.yaml
│   ├── jupyter-pytorch-notebook-imagestream.yaml
│   ├── jupyter-tensorflow-notebook-imagestream.yaml
│   ├── jupyter-trustyai-notebook-imagestream.yaml
│   ├── jupyter-minimal-gpu-notebook-imagestream.yaml
│   ├── jupyter-habana-notebook-imagestream.yaml
│   ├── code-server-notebook-imagestream.yaml
│   ├── rstudio-buildconfig.yaml
│   ├── cuda-rstudio-buildconfig.yaml
│   ├── jupyter-rocm-*-imagestream.yaml
│   ├── params.env (image references)
│   └── commit.env (build commit info)
└── overlays/
    └── additional/
        ├── kustomization.yaml
        └── jupyter-intel-*-imagestream.yaml
```

### ImageStream Configuration

ImageStreams define:
- **Labels**: `opendatahub.io/notebook-image: "true"` (enables dashboard discovery)
- **Annotations**: Image name, description, URL, software versions, Python dependencies
- **Tags**: Multiple version tags with specific image digests from `params.env`
- **Lookup Policy**: Local lookup enabled for faster image pulls

### StatefulSet Configuration (Test/Reference)

Test manifests in `jupyter/*/kustomize/base/` show deployment pattern:
- **Replicas**: 1
- **Resources**: 500m CPU, 2Gi memory (default, overridden by user selection)
- **Probes**: TCP liveness on 8888, HTTP readiness on `/notebook/{ns}/{user}/api`
- **Environment**: `NOTEBOOK_ARGS` configures JupyterLab server settings
- **Working Directory**: `/opt/app-root/src`

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 3e30c4b17 | 2026 | - RHOAIENG-17368: Update package versions script for 2.16.1 support |
| 9988c8b1a | 2026 | - RHOAIENG-15333: Create Python script for docs snippet generation from manifests |
| aed66a410 | 2026 | - Fix ROCm TensorFlow image annotation |
| 42d6b0ae9 | 2026 | - RHOAIENG-14520: Change supervisord files location for RHEL images |
| 40c810ca4 | 2026 | - RHOAIENG-15710: Fix codeflare-sdk version display for 2024.1 |
| 16ceccdd9 | 2026 | - Update image commits for release N-1 via digest-updater |
| af37148da | 2026 | - Update images for release N via digest-updater |
| 813a6d090 | 2026 | - Sync with upstream main branch |
| 4609fdef8 | 2026 | - Update annotations for codeflare-sdk and odh-elyra |
| e9c4ba4e9 | 2026 | - RHOAIENG-15242: Format JSON strings in manifests |
| ec0c518c1 | 2026 | - RHOAIENG-14585: Add RHEL9 CUDA Python 3.11 image |
| b43efbf1f | 2026 | - Bump RStudio BuildConfig branch reference to 2.16 |

**Key Trends**:
- Active maintenance of multiple image versions (N, N-1, N-2)
- Automated digest updates for published images
- Addition of RHEL9-based CUDA support for Python 3.11
- Improved manifest formatting and documentation
- ROCm and Intel accelerator support enhancements
- Codeflare SDK integration updates

## Notes

- **No standalone deployment**: Images are deployed by the Notebook Controller when users create workbenches
- **Version management**: Each ImageStream maintains 5 versions (N through N-4) for compatibility
- **GPU support**: CUDA, ROCm, and Intel XPU variants available for accelerated workloads
- **Elyra integration**: Data Science images include Elyra extension pre-configured for RHOAI Data Science Pipelines
- **Runtime images**: Lightweight variants (without JupyterLab) for pipeline step execution
- **BuildConfigs**: RStudio requires in-cluster builds due to licensing and subscription requirements
- **Customization**: Users can install additional Python packages at runtime (persistent via PVC)
- **Image updates**: Automated GitHub Actions update image digests in `params.env` when new builds are available
- **Distribution difference**: This is the RHOAI fork (red-hat-data-services) with RHEL-based images, distinct from upstream ODH (opendatahub-io) with CentOS/community images

# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks.git
- **Version**: v20xx.1-255-g4c7e4f988
- **Branch**: rhoai-2.12
- **Distribution**: RHOAI (also supports ODH)
- **Languages**: Python, Shell (Bash), Makefile
- **Deployment Type**: Container Image Builder & Registry

## Purpose
**Short**: Builds and maintains Jupyter notebook and IDE workbench container images for data science and machine learning workflows in RHOAI/ODH.

**Detailed**: This repository provides the build infrastructure for a comprehensive collection of notebook workbench container images tailored for data analysis, machine learning, research, and coding within the Red Hat OpenShift AI (RHOAI) and OpenDataHub (ODH) ecosystems. These images are designed to work with the ODH Notebook Controller as the launcher and provide users with pre-configured environments containing JupyterLab, RStudio, or VS Code Server along with popular data science libraries and frameworks. The images support various base operating systems (UBI8, UBI9, RHEL9, CentOS Stream 9) and Python versions (3.8, 3.9), with specialized variants for GPU acceleration (NVIDIA CUDA, AMD ROCm, Intel, Habana Gaudi) and machine learning frameworks (PyTorch, TensorFlow). The repository includes both interactive notebook images and runtime images for Elyra pipeline execution. Images are published to quay.io/opendatahub/workbench-images and quay.io/modh registries and deployed via OpenShift ImageStreams.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image Layer | Foundational Python environments (3.8/3.9) on UBI8/UBI9/RHEL9/CentOS9 with OpenShift CLI and base dependencies |
| Jupyter Minimal | Container Image | Minimal JupyterLab environment with Python 3.9, JupyterLab 3.6, Notebook 6.5 for lightweight workbenches |
| Jupyter Data Science | Container Image | Standard data science image with Pandas, NumPy, Scikit-learn, Matplotlib, Boto3, KFP, Elyra, CodeFlare SDK, database connectors |
| Jupyter PyTorch | Container Image | PyTorch 2.2 with CUDA 12.1 support, Tensorboard, and full data science stack for deep learning |
| Jupyter TensorFlow | Container Image | TensorFlow with CUDA support, Keras, and data science libraries for neural network training |
| Jupyter TrustyAI | Container Image | Specialized image for TrustyAI explainability and fairness analysis workloads |
| CUDA Base Images | Container Image Layer | NVIDIA CUDA GPU-accelerated base images for GPU workloads (CUDA 11.8, 12.1) |
| ROCm Images | Container Image | AMD ROCm GPU support for PyTorch and TensorFlow on AMD hardware |
| Habana Images | Container Image | Intel Habana Gaudi AI accelerator support (versions 1.10.0, 1.13.0) |
| Intel Images | Container Image | Intel GPU and ML optimization libraries for Intel hardware acceleration |
| RStudio Server | Container Image | RStudio Server 4.3 IDE for R statistical computing and Python integration |
| Code Server | Container Image | VS Code Server web IDE with Python, OpenShift CLI, and code-server for browser-based development |
| Runtime Images | Container Image | Lightweight images for Elyra pipeline execution without interactive JupyterLab interface |
| Build System | Makefile | Orchestrates multi-stage container builds with dependency resolution using podman/docker |
| Manifests (Kustomize) | Deployment Config | OpenShift ImageStream and BuildConfig definitions for image deployment and builds |
| CI/CD Scripts | Shell Scripts | Validation scripts for params.env consistency, JSON validation, runtime image checks, security scanning |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It consumes OpenShift ImageStream and BuildConfig resources.

### HTTP Endpoints

This component does not expose HTTP endpoints. The built notebook images expose the following when deployed:

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP/HTTPS | TLS 1.2+ (when configured) | Token-based | JupyterLab web interface |
| /api/* | GET, POST | 8888/TCP | HTTP/HTTPS | TLS 1.2+ (when configured) | Token-based | Jupyter Server REST API |
| /terminals/* | WebSocket | 8888/TCP | WSS | TLS 1.2+ (when configured) | Token-based | Terminal access via browser |
| /rstudio/ | GET, POST | 8787/TCP | HTTP/HTTPS | TLS 1.2+ (when configured) | Password | RStudio Server interface (RStudio images) |
| / | GET | 8080/TCP | HTTP/HTTPS | TLS 1.2+ (when configured) | Password | VS Code Server interface (Code Server images) |

**Note**: Actual encryption, authentication, and external access are configured by the ODH Notebook Controller and OpenShift route/service mesh, not by the images themselves.

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI8 Python 3.8 | registry.access.redhat.com/ubi8/python-38 | No | Base OS image for UBI8-based workbenches |
| UBI9 Python 3.9 | registry.access.redhat.com/ubi9/python-39@sha256:bbac8c29fb0f834f616b3ec07aa78d942a6e4239a5537a52517acaff59350917 | Yes | Primary base OS image for UBI9-based workbenches |
| RHEL9 Base | Various RHEL9 base images | No | Base OS for RHEL-specific builds |
| CentOS Stream 9 | Various CentOS Stream 9 images | No | Base OS for community builds |
| JupyterLab | 3.2-3.6 | Yes | Interactive notebook interface for Jupyter images |
| Jupyter Notebook | 6.4-6.5 | Yes | Notebook server for Jupyter images |
| PyTorch | 1.8-2.2 | No | Deep learning framework for PyTorch images |
| TensorFlow | Various | No | Deep learning framework for TensorFlow images |
| CUDA Toolkit | 11.4-12.1 | No | NVIDIA GPU support for CUDA images |
| ROCm | Various | No | AMD GPU support for ROCm images |
| Habana SynapseAI | 1.10.0, 1.13.0 | No | Intel Habana Gaudi accelerator support |
| RStudio Server | 4.3 | No | R IDE for RStudio images |
| Code Server | Latest | No | VS Code Server for Code Server images |
| Elyra | 3.15-3.16 | No | Pipeline orchestration for data science images |
| ODH-Elyra | 3.16 | No | OpenDataHub fork of Elyra with enhancements |
| Boto3 | 1.17-1.34 | No | AWS SDK for cloud integration |
| KFP (Kubeflow Pipelines) | 2.7 | No | ML pipeline SDK for Kubeflow integration |
| KFP-Tekton | 1.5 | No | Tekton-based pipeline SDK (older versions) |
| Pandas | 1.2-2.2 | No | Data manipulation library |
| NumPy | 1.19-1.26 | No | Numerical computing library |
| Scikit-learn | 0.24-1.4 | No | Machine learning library |
| Matplotlib | 3.4-3.8 | No | Data visualization library |
| CodeFlare SDK | 0.13-0.18 | No | Distributed AI/ML job management |
| OpenShift CLI (oc) | stable | Yes | Kubernetes/OpenShift CLI for cluster interaction |
| Podman/Docker | Latest | Yes (build time) | Container engine for building images |
| RHEL Subscription | N/A | Yes (RHEL builds) | RHEL package repositories for RHEL-based images |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Image Consumer | Launches notebook pods using these images based on user selection |
| ODH Dashboard | Image Metadata Consumer | Displays available notebook images to users via ImageStream annotations |
| OpenShift ImageStreams | Resource Definition | Provides versioned image references for notebook deployment |
| OpenShift BuildConfig | Build Orchestration | Builds images on-cluster for RHEL-based variants (RStudio, CUDA-RStudio) |
| Kubeflow Pipelines | Runtime Integration | Elyra pipelines execute using runtime images |
| Model Mesh / KServe | Indirect | Data science images may be used to develop models deployed to serving platforms |

## Network Architecture

### Services

This component does not deploy Kubernetes Services. Services are created by the ODH Notebook Controller when launching notebook pods.

When deployed as notebook pods, typical service configuration:

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-[name] | ClusterIP | 8888/TCP | 8888 | HTTP | None (mesh provides) | OAuth Proxy | Internal |
| rstudio-[name] | ClusterIP | 8787/TCP | 8787 | HTTP | None (mesh provides) | OAuth Proxy | Internal |
| codeserver-[name] | ClusterIP | 8080/TCP | 8080 | HTTP | None (mesh provides) | OAuth Proxy | Internal |

### Ingress

This component does not define Ingress/Routes. Routes are created by the ODH Notebook Controller.

When deployed, typical ingress configuration:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-[name] | OpenShift Route | [notebook-namespace].[cluster-domain] | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |
| notebook-[name]-oauth | OpenShift Route | [notebook-namespace].[cluster-domain] | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (OAuth) |

### Egress

When running, notebook images may connect to:

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation at runtime |
| Quay.io | 443/TCP | HTTPS | TLS 1.2+ | None/Token | Container image pulls |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Data access via Boto3 |
| PostgreSQL databases | 5432/TCP | PostgreSQL | TLS (optional) | Username/Password | Database connectivity via psycopg |
| MySQL databases | 3306/TCP | MySQL | TLS (optional) | Username/Password | Database connectivity via MySQL Connector |
| MongoDB | 27017/TCP | MongoDB | TLS (optional) | Username/Password | Database connectivity via PyMongo |
| MS SQL Server | 1433/TCP | TDS | TLS (optional) | Username/Password | Database connectivity via pyodbc |
| Kafka brokers | 9092/TCP | Kafka | TLS/SASL | SASL | Event streaming via kafka-python |
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | K8s operations via oc CLI |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH Keys/Token | Source code version control |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Token | Pushing/pulling images from notebooks |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. RBAC is managed by the ODH Notebook Controller for launched notebook pods.

Typical RBAC granted to notebook pods by the controller:

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| notebook-controller-role | "" | pods, services, persistentvolumeclaims | get, list, watch, create, delete |
| notebook-controller-role | apps | deployments, statefulsets | get, list, watch |
| notebook-controller-role | route.openshift.io | routes | get, list, watch, create, delete |
| notebook-controller-role | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |

### RBAC - Role Bindings

This component does not define RoleBindings. RoleBindings are created by the ODH Notebook Controller.

### Secrets

This component references secrets during builds:

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription credentials for RHEL-based BuildConfigs | Platform Admin | No |

Notebook pods may consume various secrets:

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| [user]-notebook-token | Opaque | Jupyter authentication token | Notebook Controller | No |
| aws-connection-* | Opaque | AWS credentials for S3/Boto3 access | User/Data Scientist | No |
| [database]-credentials | Opaque | Database connection credentials | User/Data Scientist | No |
| git-credentials | kubernetes.io/basic-auth or ssh-auth | Git repository access | User/Data Scientist | No |
| pull-secret | kubernetes.io/dockerconfigjson | Container registry authentication | Platform/User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| JupyterLab UI (/) | GET, POST | OAuth Proxy → Bearer Token | OpenShift OAuth Proxy sidecar | User must have namespace access |
| Jupyter API (/api/*) | GET, POST | JWT Token (Jupyter) | JupyterLab | Token-based auth, configured by controller |
| RStudio Server | GET, POST | OAuth Proxy → Password | OpenShift OAuth Proxy sidecar | User must have namespace access |
| Code Server | GET, POST | OAuth Proxy → Password | OpenShift OAuth Proxy sidecar | User must have namespace access |
| OpenShift API (via oc) | All | ServiceAccount Token | Kubernetes API Server | ServiceAccount RBAC permissions |

## Data Flows

### Flow 1: Image Build and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Developer | GitHub (red-hat-data-services/notebooks) | 443/TCP | HTTPS | TLS 1.3 | GitHub Token |
| 2 | GitHub Actions / Konflux | Red Hat Registry (UBI base images) | 443/TCP | HTTPS | TLS 1.2+ | Registry Token |
| 3 | GitHub Actions / Konflux | Quay.io (workbench-images) | 443/TCP | HTTPS | TLS 1.2+ | Quay Token |
| 4 | Quay.io | OpenShift ImageStream | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | ODH Operator | OpenShift API (create ImageStream) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 2: Notebook Pod Launch

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User | ODH Dashboard | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 2 | ODH Dashboard | Kubernetes API (create Notebook CR) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 3 | Notebook Controller | Kubernetes API (create Pod/Service/Route) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Kubelet | ImageStream → Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | User | OpenShift Route → OAuth Proxy | 443/TCP | HTTPS | TLS 1.2+ | OAuth Token |
| 6 | OAuth Proxy | JupyterLab Pod | 8888/TCP | HTTP | None (internal) | Proxied auth |

### Flow 3: Runtime Package Installation

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User (in notebook) | JupyterLab terminal (pip install) | N/A | Local | N/A | N/A |
| 2 | Notebook Pod | PyPI.org | 443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | PyPI.org | Notebook Pod | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 4: Data Science Workflow

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod | S3 Storage (via Boto3) | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM Keys |
| 2 | Notebook Pod | PostgreSQL Database | 5432/TCP | PostgreSQL | TLS (optional) | Username/Password |
| 3 | Notebook Pod | Kubernetes API (KFP pipeline submit) | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 4 | Elyra (in notebook) | Kubeflow Pipelines API | 8888/TCP | HTTP/HTTPS | TLS 1.2+ | Bearer Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | Metadata Consumer | N/A | N/A | N/A | Reads ImageStream annotations to display notebook options |
| ODH Notebook Controller | Image Consumer | N/A | N/A | N/A | Launches pods using these images |
| Kubeflow Pipelines | Runtime SDK | 8888/TCP | HTTP/HTTPS | TLS 1.2+ | Elyra submits pipelines via KFP SDK |
| OpenShift OAuth | Auth Provider | 443/TCP | HTTPS | TLS 1.2+ | OAuth authentication for notebook access |
| OpenShift Image Registry | Image Storage | 443/TCP | HTTPS | TLS 1.2+ | Internal registry for built images |
| Quay.io | Image Registry | 443/TCP | HTTPS | TLS 1.2+ | External registry for published images |
| S3-compatible Storage | Data Access | 443/TCP | HTTPS | TLS 1.2+ | Data lakes accessed via Boto3 from notebooks |
| Git Services | Source Control | 443/TCP | HTTPS/SSH | TLS 1.2+/SSH | Version control integration in JupyterLab |
| PostgreSQL/MySQL/MongoDB | Database Access | Various | Various | TLS (optional) | Data sources for analysis and ML |
| NVIDIA GPU Operator | GPU Access | N/A | N/A | N/A | GPU device plugin for CUDA images |
| Node Feature Discovery | Hardware Detection | N/A | N/A | N/A | Detects GPU/accelerator hardware for scheduling |

## Deployment Architecture

### Image Build Process

The repository supports two build methods:

1. **Local/CI Builds** (Makefile-based):
   - Uses `podman` or `docker` to build images locally or in GitHub Actions
   - Multi-stage build chain: base → minimal → datascience → specialized
   - Pushes to quay.io/opendatahub/workbench-images registry
   - Tags: `[image-name]-[RELEASE]_[DATE]` (e.g., `jupyter-minimal-ubi9-python-3.9-2024a_20240317`)

2. **OpenShift BuildConfig** (On-cluster builds):
   - Used for RHEL-based images requiring subscription access
   - BuildConfig pulls from GitHub repository
   - Mounts `rhel-subscription-secret` for RHEL package access
   - Outputs to local ImageStreamTag
   - Examples: RStudio RHEL9, CUDA RStudio builds

### Manifest Deployment Structure

```
manifests/
├── base/
│   ├── kustomization.yaml                          # Base kustomize config
│   ├── params.env                                   # Image references (digests)
│   ├── commit.env                                   # Git commit metadata
│   ├── jupyter-minimal-notebook-imagestream.yaml    # Minimal Python notebook
│   ├── jupyter-datascience-notebook-imagestream.yaml # Standard Data Science
│   ├── jupyter-pytorch-notebook-imagestream.yaml    # PyTorch GPU
│   ├── jupyter-tensorflow-notebook-imagestream.yaml # TensorFlow GPU
│   ├── jupyter-trustyai-notebook-imagestream.yaml   # TrustyAI explainability
│   ├── jupyter-habana-notebook-imagestream.yaml     # Habana Gaudi
│   ├── jupyter-minimal-gpu-notebook-imagestream.yaml # CUDA minimal
│   ├── code-server-notebook-imagestream.yaml        # VS Code Server
│   ├── rstudio-buildconfig.yaml                     # RStudio BuildConfig + ImageStream
│   └── cuda-rstudio-buildconfig.yaml                # CUDA RStudio BuildConfig
└── overlays/
    └── additional/
        ├── kustomization.yaml
        ├── jupyter-intel-ml-notebook-imagestream.yaml
        ├── jupyter-intel-pytorch-notebook-imagestream.yaml
        └── jupyter-intel-tensorflow-notebook-imagestream.yaml
```

### ImageStream Versioning Strategy

Each ImageStream maintains 4 versions (N, N-1, N-2, N-3):
- **N (latest)**: Current recommended version (e.g., 2024.1) - `opendatahub.io/workbench-image-recommended: "true"`
- **N-1**: Previous version (e.g., 2023.2) - Available but not recommended
- **N-2**: Older version (e.g., 2023.1) - Marked `opendatahub.io/image-tag-outdated: "true"`
- **N-3**: Legacy version (e.g., 1.2) - Marked outdated

This allows users to pin to specific versions while encouraging migration to newer images.

## Container Image Variants

### Base Image Hierarchy

```
Registry Base (UBI8/UBI9/RHEL9/C9S)
  └── Base + Python 3.8/3.9 + oc CLI + micropipenv
      ├── Jupyter Minimal (JupyterLab 3.6 + Notebook 6.5)
      │   ├── Jupyter Data Science (Pandas, NumPy, Scikit-learn, Elyra, KFP, CodeFlare)
      │   └── Jupyter TrustyAI (TrustyAI explainability libraries)
      ├── CUDA Base (NVIDIA CUDA Toolkit)
      │   ├── Jupyter Minimal GPU (CUDA + JupyterLab)
      │   ├── Jupyter PyTorch (PyTorch 2.2 + CUDA 12.1)
      │   └── Jupyter TensorFlow (TensorFlow + CUDA)
      ├── ROCm Base (AMD ROCm)
      │   ├── ROCm PyTorch
      │   └── ROCm TensorFlow
      ├── Habana Base (Intel Habana SynapseAI)
      │   └── Jupyter Habana
      ├── Intel Base (Intel GPU/optimization libraries)
      │   ├── Intel ML Notebook
      │   ├── Intel PyTorch
      │   └── Intel TensorFlow
      ├── RStudio (RStudio Server 4.3 + R 4.3 + Python 3.9)
      └── Code Server (VS Code Server + oc + Python 3.9)
```

### Runtime Images (Elyra Pipeline Execution)

Lightweight images without JupyterLab UI for Elyra pipeline steps:
- `runtime-minimal` (Python 3.8/3.9 only)
- `runtime-datascience` (Data science libraries)
- `runtime-pytorch` (PyTorch + dependencies)
- `runtime-tensorflow` (TensorFlow + dependencies)
- `runtime-rocm-pytorch` (AMD ROCm PyTorch)
- `runtime-rocm-tensorflow` (AMD ROCm TensorFlow)

## Build & Test Infrastructure

### Makefile Targets

Key build targets follow pattern: `[category]-[variant]-[os]-python-[version]`

Examples:
- `base-ubi9-python-3.9`: Base image
- `jupyter-minimal-ubi9-python-3.9`: Minimal Jupyter
- `jupyter-datascience-ubi9-python-3.9`: Data Science notebook
- `jupyter-pytorch-ubi9-python-3.9`: PyTorch GPU notebook
- `cuda-ubi9-python-3.9`: CUDA base layer

Deployment/test targets:
- `deploy9-[notebook-name]`: Deploy to OpenShift cluster (UBI9)
- `test-[notebook-name]`: Run test suite against deployed notebook
- `undeploy9-[notebook-name]`: Clean up deployment

### CI/CD Validation

Scripts in `ci/` directory:
- `check-params-env.sh`: Validates params.env consistency and image digest references
- `check-json.sh`: Validates JSON syntax in dependency files
- `check-runtime-images.sh`: Validates runtime images have required commands (curl, python)
- `security-scan/`: Trivy security scanning for vulnerabilities
- `version-compatibility/`: Cross-version compatibility checks
- `hadolint-config.yaml`: Dockerfile linting configuration
- `yamllint-config.yaml`: YAML linting configuration

### Testing Strategy

Python tests using pytest (tests/test_main.py):
- Image smoke tests (container starts, services running)
- Package availability tests (import checks for key libraries)
- Version compatibility tests

Manual testing via Makefile:
- Deploy notebook to test cluster
- Execute test scripts from `jupyter/[variant]/ubi9-python-3.9/test/`
- Validate runtime image compatibility with `validate-runtime-image` target

## Configuration Management

### ConfigMaps Generated by Kustomize

1. **notebooks-parameters** (from `params.env`):
   - Contains image references with SHA256 digests for all notebook variants
   - Examples: `odh-minimal-notebook-image-n`, `odh-pytorch-gpu-notebook-image-n-1`
   - Substituted into ImageStream specs via Kustomize vars

2. **notebook** (from `commit.env`):
   - Contains git commit hashes for each image build
   - Used in ImageStream annotations: `opendatahub.io/notebook-build-commit`
   - Provides traceability from deployed image to source commit

### Image Metadata (Annotations)

ImageStream annotations provide metadata for ODH Dashboard:

| Annotation | Example Value | Purpose |
|------------|---------------|---------|
| opendatahub.io/notebook-image | "true" | Marks as notebook image |
| opendatahub.io/notebook-image-url | "https://github.com/..." | Link to source code |
| opendatahub.io/notebook-image-name | "PyTorch" | Display name in dashboard |
| opendatahub.io/notebook-image-desc | "Jupyter notebook image with..." | Description text |
| opendatahub.io/notebook-image-order | "40" | Sort order in dashboard (10-90) |
| opendatahub.io/notebook-software | '[{"name":"Python","version":"v3.9"}]' | Installed software versions (JSON) |
| opendatahub.io/notebook-python-dependencies | '[{"name":"PyTorch","version":"2.2"}]' | Python package versions (JSON) |
| opendatahub.io/workbench-image-recommended | "true"/"false" | Recommended version flag |
| opendatahub.io/image-tag-outdated | "true" | Marks older versions as outdated |
| opendatahub.io/default-image | "true" | Default image for new workbenches |
| opendatahub.io/recommended-accelerators | '["nvidia.com/gpu"]' | Hardware accelerator recommendations (JSON) |
| opendatahub.io/notebook-build-commit | "4c7e4f988" | Git commit hash of build |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 4c7e4f988 | 2024-08-08 | - Merge pull request #356 from red-hat-data-services/main<br>- Sync with upstream OpenDataHub repository |
| 1423b8966 | 2024-08-08 | - Merge pull request #355 for digest updates<br>- Update image digests via digest-updater automation |
| 9b2a72142 | 2024-08-09 | - Update image commits for release N via digest-updater-10313212251<br>- Automated commit metadata refresh |
| 9b0d18adf | 2024-08-09 | - Update images for release N via digest-updater-10313212251<br>- Automated image digest updates in params.env |
| 5a42d61f4 | 2024-08-08 | - Merge pull request #353 from digest-updater<br>- Continue digest automation improvements |
| 909743a84 | 2024-08-08 | - Update params.env via digest-updater-10309839691<br>- Automated parameter file updates |
| 618250b4e | 2024-08-08 | - Merge pull request #349 from opendatahub-io/main<br>- Sync latest changes from upstream ODH |
| 1db71cc5f | 2024-08-08 | - Merge pull request #667 from harshad16/remove-install-package<br>- Remove redundant package installations |
| d30b6e62f | 2024-08-08 | - **RHOAIENG-11087**: Fix: Remove install of package in bootstrapper as pre-installed<br>- Reduce image size by eliminating duplicate installs |
| ae4e01f4d | 2024-08-07 | - Merge pull request #666 from jstourac/podmanDigests<br>- Enhanced digest tracking for podman builds |
| 1a7d88fe4 | 2024-08-07 | - [GHA] Print also images digests after the image build in GitHub repo<br>- Improve build transparency with digest logging |
| 9ed174f31 | 2024-08-07 | - **RHOAIENG-10783**: fix(Dockerfiles): combine `fix-permissions` RUN with the preceding RUN when possible<br>- Reduce image layers by combining RUN commands |
| ed363c7ca | 2024-08-07 | - **RHOAIENG-9822**: chore(Makefile): allow not pushing built images in Makefile and allow skipping building dependent images<br>- Add PUSH_IMAGES and BUILD_DEPENDENT_IMAGES variables for flexible builds |
| f84cf6981 | 2024-08-07 | - Merge pull request #664 from caponetto/full-trivy<br>- Expand Trivy security scanning coverage |
| b99fd1ec3 | 2024-08-06 | - Run Trivy image scan for ROCm Pytorch image<br>- Add security scanning for AMD ROCm images |
| ec45de169 | 2024-08-06 | - **RHOAIENG-10783**: fix(rocm): de-vendor the bundled rocm libraries from pytorch<br>- Reduce ROCm image size by removing bundled libraries |
| 7a7e5b655 | 2024-08-02 | - Merge pull request #345 from harshad16/rsync-main<br>- Repository synchronization improvements |
| 85e67e8d7 | 2024-08-02 | - Merge branch 'main' of opendatahub-io/notebooks into rsync-main<br>- Sync with upstream main branch |
| b5322d897 | 2024-08-02 | - Merge pull request #663 from harshad16/fix-annotation<br>- Fix ImageStream annotation issues |
| 55be228fc | 2024-08-02 | - Set the annotation with codeflare-sdk 0.18.0<br>- Update CodeFlare SDK version metadata in annotations |

## Key Features & Capabilities

### Multi-Architecture Support
- **UBI8**: Enterprise RHEL 8 Universal Base Image (Python 3.8)
- **UBI9**: Enterprise RHEL 9 Universal Base Image (Python 3.9) - Primary platform
- **RHEL9**: Full RHEL 9 with subscription access (for BuildConfigs)
- **CentOS Stream 9**: Community builds for upstream ODH

### GPU & Accelerator Support
- **NVIDIA CUDA**: CUDA 11.4, 11.8, 12.1 for GeForce/Tesla GPUs
- **AMD ROCm**: ROCm-optimized PyTorch and TensorFlow for AMD GPUs
- **Intel**: Intel GPU drivers and optimization libraries for Intel Arc/Data Center GPUs
- **Habana Gaudi**: Intel Habana SynapseAI SDK for Gaudi AI accelerators

### ML Framework Support
- **PyTorch**: 1.8 → 2.2 with TorchVision, Tensorboard
- **TensorFlow**: Various versions with Keras integration
- **Scikit-learn**: 0.24 → 1.4 for classical ML
- **XGBoost/LightGBM**: Gradient boosting frameworks
- **ONNX**: Model interoperability with sklearn-onnx

### Data Engineering Tools
- **Cloud SDKs**: Boto3 (AWS), Google Cloud SDK support
- **Databases**: PostgreSQL (psycopg 3.1), MySQL (8.0/8.3), MongoDB (PyMongo 4.5/4.6), MS SQL (pyodbc 5.1)
- **Streaming**: Kafka-Python 2.0 for event streaming
- **Data Processing**: Pandas 1.2→2.2, NumPy 1.19→1.26, Scipy 1.6→1.12

### MLOps & Pipeline Tools
- **Elyra/ODH-Elyra**: 3.15, 3.16 - Visual pipeline editor for Kubeflow/Tekton
- **Kubeflow Pipelines SDK**: KFP 2.7, KFP-Tekton 1.5
- **CodeFlare SDK**: 0.13→0.18 - Distributed ML job orchestration
- **TrustyAI**: Explainability and fairness analysis for responsible AI

### Development Tools
- **JupyterLab**: 3.2→3.6 - Modern notebook interface
- **RStudio Server**: 4.3 - R statistical computing IDE
- **VS Code Server**: Browser-based VS Code via code-server
- **OpenShift CLI**: `oc` tool for cluster interaction
- **Git Integration**: Built-in git support in JupyterLab

## Security & Compliance

### Image Scanning
- **Trivy**: Automated vulnerability scanning in CI/CD
- **Hadolint**: Dockerfile best practices validation
- Templates in `ci/trivy-markdown.tpl` for report generation

### Base Image Provenance
- Uses official Red Hat Universal Base Images (UBI) with SHA256 pinning
- RHEL subscription support for enterprise hardening
- Regular base image updates via automated digest-updater workflows

### Runtime Security
- Non-root user (UID 1001) for notebook processes
- Read-only filesystem support (configurable)
- Seccomp/AppArmor profiles compatible
- NetworkPolicy support (when deployed)

### Secrets Management
- No secrets in images (validated in CI)
- RHEL subscription via mounted secret (build time only)
- Database/cloud credentials via Kubernetes secrets (runtime)

## Operational Considerations

### Image Size Optimization
- Multi-stage builds to minimize final image size
- Combined RUN statements to reduce layers (RHOAIENG-10783)
- De-vendoring of bundled libraries (e.g., ROCm - RHOAIENG-10783)
- `--no-cache` build flag to prevent stale layers

### Version Pinning
- Pipfile.lock for deterministic Python dependency installation via micropipenv
- Base image SHA256 digests in Dockerfiles
- Image digest references in params.env for reproducible deployments

### Update Strategy
- **Digest Updater**: Automated GitHub Actions workflow updates params.env and commit.env
- **N/N-1/N-2/N-3 Versioning**: 4-version retention allows gradual migration
- **Recommended Flag**: Guides users to current stable version

### Resource Requirements (BuildConfig)
- CPU: 1 core request/limit
- Memory: 2Gi request/limit
- Build timeout: Default OpenShift timeout (~15 minutes)
- History: 2 successful + 2 failed builds retained

## Troubleshooting & Debugging

### Common Build Issues
1. **RHEL Subscription Failures**: Verify `rhel-subscription-secret` exists and is valid
2. **Base Image Pull Failures**: Check registry.access.redhat.com accessibility
3. **Dependency Conflicts**: Regenerate Pipfile.lock with `pipenv lock`
4. **Layer Size Bloat**: Combine RUN statements, use `--no-cache`

### Common Runtime Issues
1. **Package Import Failures**: Verify Pipfile.lock includes package, rebuild image
2. **GPU Not Detected**: Check Node Feature Discovery and GPU Operator installed
3. **Permission Denied**: Notebook runs as UID 1001, check PVC/volume permissions
4. **Slow Startup**: Large images may take time to pull, use image pull policies

### Validation Commands
```bash
# Validate params.env consistency
./ci/check-params-env.sh

# Validate runtime image has required commands
make validate-runtime-image image=quay.io/opendatahub/workbench-images:runtime-minimal-ubi9-python-3.9-2024a

# Test notebook deployment
make deploy9-jupyter-minimal
make test-jupyter-minimal
make undeploy9-jupyter-minimal
```

## Future Enhancements & Roadmap

Based on commit history and architecture patterns:
1. **Konflux Migration**: Full transition to Konflux-based builds (RHOAI standard)
2. **Python 3.11/3.12**: Upgrade to newer Python versions as base images become available
3. **JupyterLab 4.x**: Migration to JupyterLab 4.x when stable in ecosystem
4. **ARM64 Support**: Multi-arch images for ARM-based instances
5. **Reduced Image Variants**: Consolidation of overlapping images to reduce maintenance
6. **Enhanced Security Scanning**: Expanded Trivy coverage, SBOM generation
7. **Automated Dependency Updates**: Dependabot/Renovate for Pipfile dependencies

## References & Documentation

- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Upstream**: https://github.com/opendatahub-io/notebooks
- **Published Images**: https://quay.io/opendatahub/workbench-images, https://quay.io/modh
- **Wiki**: https://github.com/opendatahub-io/notebooks/wiki/Workbenches
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)
- **ODH Documentation**: https://opendatahub.io/docs
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai

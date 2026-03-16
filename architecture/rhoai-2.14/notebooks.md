# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v20xx.1-390-g71fd04134
- **Branch**: rhoai-2.14
- **Distribution**: RHOAI
- **Languages**: Python, Bash, Containerfile
- **Deployment Type**: Container Images (OCI/Docker)

## Purpose
**Short**: Provides pre-built container images for data science workbenches including Jupyter, code-server, and RStudio environments.

**Detailed**: This repository builds and maintains a collection of container-based workbench images optimized for data science, machine learning, and research workflows within the Red Hat OpenShift AI (RHOAI) and OpenDataHub (ODH) ecosystems. These images provide ready-to-use development environments with pre-installed tools, libraries, and frameworks. The workbenches support multiple hardware accelerators (NVIDIA CUDA, AMD ROCm, Intel GPU, Habana) and come in various configurations (minimal, data science, PyTorch, TensorFlow, TrustyAI). Images are designed to be launched by the ODH Notebook Controller and run as unprivileged containers (UID 1001) for security. The repository also includes runtime images that support Elyra pipeline execution with integration to object storage for artifact management.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Jupyter Workbenches | Container Images | JupyterLab-based notebooks for interactive development (minimal, datascience, pytorch, tensorflow, trustyai) |
| code-server Workbenches | Container Images | VS Code in browser with Python development environment and extensions |
| RStudio Workbenches | Container Images | RStudio Server for R-based data science workflows |
| Runtime Images | Container Images | Lightweight images for pipeline execution with Elyra bootstrapper support |
| Base Images | Container Images | Foundation images with Python 3.9/3.11 on UBI9/C9S/RHEL9 |
| Hardware Accelerator Images | Container Images | Specialized images with CUDA, ROCm, Intel GPU, or Habana support |
| ImageStream Manifests | Kubernetes Resources | OpenShift ImageStream definitions for workbench image distribution |
| Elyra Bootstrapper | Python Script | Runtime component for executing notebooks/scripts in pipelines with object storage integration |

## APIs Exposed

### Custom Resource Definitions (CRDs)

No CRDs defined - this component provides container images only.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/ | GET, POST, WebSocket | 8888/TCP | HTTP | None (TLS at ingress) | Token/OAuth | JupyterLab web interface and API |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None | Token/OAuth | Jupyter Server API for health checks |
| / | GET, POST | 8080/TCP | HTTP | None | None | code-server web interface (proxied by nginx) |
| /healthz | GET | 8080/TCP | HTTP | None | None | code-server health check endpoint |

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| JupyterLab | 4.2 (2024.2), 3.6 (2024.1) | Yes | Interactive notebook environment |
| code-server | 4.92.2 | Yes | VS Code web interface |
| RStudio Server | Various | Yes | R development environment |
| Python | 3.9, 3.11 | Yes | Runtime environment and kernel |
| NGINX | 1.24 | Yes (code-server) | Reverse proxy for code-server and health checks |
| Elyra | Via bootstrapper | No | Pipeline execution support in runtime images |
| Papermill | Latest | No | Notebook parameterization and execution |
| Minio Client | Latest | No | Object storage integration for pipelines |
| CUDA Toolkit | Various | No | NVIDIA GPU support |
| ROCm | Various | No | AMD GPU support |
| Intel oneAPI | Various | No | Intel GPU support |
| Habana SDK | Various | No | Habana Gaudi accelerator support |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Launch/Lifecycle | Controller that spawns workbench pods using these images |
| ODH Dashboard | UI Selection | Provides UI for users to select and launch workbench images |
| OpenShift ImageStreams | Image Distribution | Mechanism for distributing and versioning workbench images |
| Elyra/KFP | Pipeline Execution | Runtime images execute as pipeline nodes in Kubeflow Pipelines |
| Object Storage (S3/Minio) | Artifact Storage | Runtime images store/retrieve pipeline artifacts and dependencies |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | Token/OAuth (external) | Internal |

**Note**: Services are created per-workbench instance by the ODH Notebook Controller. The above represents the typical service definition used in testing/deployment manifests.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| N/A | OpenShift Route | Varies by deployment | 443/TCP | HTTPS | TLS 1.2+ | Edge/Re-encrypt | External |

**Note**: Ingress/Routes are managed by the ODH Notebook Controller based on cluster configuration, not by this component.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Object Storage (S3/Minio) | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM/Static Creds | Pipeline artifact storage/retrieval (runtime images) |
| Container Registry | 443/TCP | HTTPS | TLS 1.2+ | Token | Pull dependent images during build |
| PyPI/Conda | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime |

## Security

### RBAC - Cluster Roles

No cluster roles defined - this component provides container images only. RBAC is managed by the ODH Notebook Controller.

### RBAC - Role Bindings

No role bindings defined - this component provides container images only. RBAC is managed by the ODH Notebook Controller.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| N/A | N/A | No secrets managed by this component | N/A | N/A |

**Note**: Secrets for object storage credentials, OAuth tokens, etc. are injected by the ODH Notebook Controller into workbench pods.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/ | All | OAuth Proxy (external) | ODH Notebook Controller | User must own notebook instance |
| /notebook/{namespace}/{username}/api | GET | Token (optional) | Jupyter Server | Configurable per instance |

**Security Posture**:
- All images run as non-root user (UID 1001, GID 0)
- Compatible with OpenShift restricted SCC
- No privileged operations required
- File system permissions support arbitrary UIDs in root group (GID 0)
- TLS termination handled at ingress layer (OpenShift Route)
- Secrets mounted as environment variables or files by controller

## Data Flows

### Flow 1: User Access to Jupyter Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy |
| 2 | OpenShift Router | notebook Service | 8888/TCP | HTTP | None (internal) | Forwarded Token |
| 3 | notebook Service | Jupyter Container | 8888/TCP | HTTP | None | Token (optional) |

### Flow 2: Pipeline Execution (Runtime Images)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KFP Pod (Runtime Image) | Object Storage | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM/Static Creds |
| 2 | Bootstrapper | Object Storage | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM/Static Creds |
| 3 | Bootstrapper | Object Storage | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | AWS IAM/Static Creds |

**Step Details**:
1. Download dependencies archive and input artifacts from object storage
2. Execute notebook/script using papermill/python3/Rscript
3. Upload output artifacts, HTML reports, and KFP metadata to object storage

### Flow 3: code-server Access

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | OAuth Proxy |
| 2 | OpenShift Router | notebook Service | 8888/TCP | HTTP | None (internal) | Forwarded Token |
| 3 | notebook Service | NGINX (in container) | 8080/TCP | HTTP | None | None |
| 4 | NGINX | code-server (in container) | localhost:8080 | HTTP | None | None |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Kubernetes API | N/A | Kubernetes API | TLS 1.2+ | Controller launches pods using these images via StatefulSet |
| ODH Dashboard | UI Reference | N/A | N/A | N/A | Dashboard reads ImageStream metadata to display available workbenches |
| OpenShift ImageStream | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Cluster pulls images from registry referenced in ImageStream |
| Elyra/KFP | Container Execution | N/A | N/A | N/A | Pipeline operator executes runtime images as pods |
| Object Storage | S3 API | 443/TCP or 9000/TCP | HTTPS/HTTP | TLS 1.2+ or None | Runtime images upload/download pipeline artifacts |

## Deployment Architecture

### Image Build Process

1. **Base Images**: Built from UBI9/C9S/RHEL9 with Python 3.9 or 3.11
2. **Hardware Accelerator Layers**: CUDA, ROCm, Intel, or Habana support added
3. **Workbench Layers**: Jupyter/code-server/RStudio installed with dependencies
4. **Specialized Variants**: ML frameworks (PyTorch, TensorFlow) or tools (TrustyAI) added
5. **Image Push**: Images pushed to quay.io/opendatahub/workbench-images or quay.io/modh/

### Deployment Manifests

The `manifests/` directory contains:
- **ImageStream Definitions**: Define available workbench images with metadata (Python version, software versions)
- **ConfigMaps**: Store image tags and commit SHAs for versioning
- **Kustomize Overlays**: Additional/optional workbench variants (Intel-optimized images)

These manifests are consumed by:
- **ODH Operator**: Deploys ImageStreams to make workbenches available
- **RHOAI Operator**: Deploys ImageStreams with RHOAI-specific image references

### Container Startup

**Jupyter Workbenches**:
- Entrypoint: `/opt/app-root/bin/start-notebook.sh`
- Starts JupyterLab on port 8888
- Configurable via environment variables: `NOTEBOOK_PORT`, `NOTEBOOK_BASE_URL`, `NOTEBOOK_ROOT_DIR`, `NOTEBOOK_ARGS`
- Elyra setup script executed if present

**code-server Workbenches**:
- Entrypoint: `/opt/app-root/bin/run-code-server.sh`
- Starts supervisord which manages:
  - code-server on localhost:8080
  - NGINX on port 8080 (proxies to code-server and provides health endpoints)
- Python and Jupyter extensions pre-installed

**Runtime Images**:
- Entrypoint: User-defined (typically python3 or bootstrapper.py)
- Minimal tooling: curl, python3, pip
- Designed for ephemeral pipeline execution, not interactive use

## Image Variants

### Jupyter Workbenches

| Variant | Base | ML Frameworks | Use Case |
|---------|------|---------------|----------|
| jupyter-minimal | UBI9 Python 3.9/3.11 | None | Basic notebook environment |
| jupyter-datascience | jupyter-minimal | Pandas, NumPy, SciPy, scikit-learn | General data science |
| jupyter-pytorch | jupyter-minimal | PyTorch | Deep learning with PyTorch |
| jupyter-tensorflow | jupyter-minimal | TensorFlow | Deep learning with TensorFlow |
| jupyter-trustyai | jupyter-minimal | TrustyAI | Explainable AI and model monitoring |
| jupyter-intel-ml | Intel GPU Base | scikit-learn (Intel optimized) | Intel GPU accelerated ML |
| jupyter-intel-pytorch | Intel GPU Base | PyTorch (Intel optimized) | Intel GPU accelerated PyTorch |
| jupyter-intel-tensorflow | Intel GPU Base | TensorFlow (Intel optimized) | Intel GPU accelerated TensorFlow |
| jupyter-rocm-minimal | ROCm Base | None | AMD GPU basic environment |
| jupyter-rocm-pytorch | ROCm Base | PyTorch (ROCm) | AMD GPU accelerated PyTorch |
| jupyter-rocm-tensorflow | ROCm Base | TensorFlow (ROCm) | AMD GPU accelerated TensorFlow |
| jupyter-habana | Habana Base | PyTorch/TensorFlow (Habana) | Habana Gaudi accelerated ML |

### code-server Workbenches

| Variant | Base | Purpose |
|---------|------|---------|
| code-server | UBI9 Python 3.9/3.11 | VS Code in browser with Python and Jupyter extensions |

### RStudio Workbenches

| Variant | Base | Purpose |
|---------|------|---------|
| rstudio | C9S/RHEL9 Python 3.9/3.11 | RStudio Server for R development |

### Runtime Images

| Variant | Base | Purpose |
|---------|------|---------|
| runtime-minimal | UBI9 Python 3.9/3.11 | Minimal runtime for Python scripts |
| runtime-datascience | runtime-minimal | Runtime with data science libraries |
| runtime-pytorch | runtime-minimal | Runtime with PyTorch |
| runtime-tensorflow | runtime-minimal | Runtime with TensorFlow |
| runtime-rocm-pytorch | ROCm Base | AMD GPU runtime for PyTorch |
| runtime-rocm-tensorflow | ROCm Base | AMD GPU runtime for TensorFlow |

## Version Management

Each ImageStream includes multiple tagged versions:
- **N (2024.2)**: Latest recommended version with Python 3.11
- **N-1 (2024.1)**: Previous version with Python 3.9
- **N-2 (2023.2)**: Older version marked as outdated
- **N-3 (2023.1)**: Older version marked as outdated
- **N-4 (1.2)**: Legacy version with Python 3.8

Annotations indicate:
- `opendatahub.io/workbench-image-recommended: "true"` - Recommended for new workbenches
- `opendatahub.io/default-image: "true"` - Default selection in UI
- `opendatahub.io/image-tag-outdated: "true"` - Deprecated versions

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 71fd041 | 2024-10-11 | - Merge PR #409: Cherry-pick to rhoai-2.14 |
| 95bf8d0 | 2024-10-11 | - Merge PR #405: Cherry-pick to rhoai-2.14 |
| 6dd42d9 | 2024-10-11 | - Include 2024.1 images with codeflare-sdk commit 636b66d |
| 6e664a2 | 2024-10-11 | - Revert habana image label changes |
| 8281296 | 2024-10-06 | - Merge PR #398: Adjust RHOAI manifests |
| 064b974 | 2024-10-06 | - Fix validation CI checks |
| 75be4bf | 2024-10-06 | - Fix linting on manifest imagestream YAMLs |
| c77dfdc | 2024-10-06 | - Update imagestream SHAs for 2024b (69688c1) and 2024a (66ff88f) |
| c3fb813 | 2024-10-06 | - Fix annotation for standard datascience 2024b imagestream |
| c0a6243 | 2024-10-06 | - Adjust base image for RStudio builds |
| 13dbeb3 | 2024-10-05 | - Digest updater action: Update notebook images |
| da5d4bf | 2024-10-05 | - Set manifests in correct order with minor fixes |
| 6e14055 | 2024-10-04 | - Merge PR #395: Resync with main branch |
| 6347ae5 | 2024-10-04 | - Merge PR #733: Update odh-elyra version |
| ab54851 | 2024-10-04 | - Digest updater action: Update runtime images |
| 4a5dd28 | 2024-10-04 | - Update odh-elyra from 4.0.2 to 4.0.3 |
| 7fa25ff | 2024-10-04 | - Digest updater action: Update runtime images (PR #391) |
| 102c8e3 | 2024-10-04 | - RHOAIENG-12621: Update github action to latest branch |

## Build and Test

### Build Process

```bash
# Build a specific workbench image
make jupyter-minimal-ubi9-python-3.11 \
  -e IMAGE_REGISTRY=quay.io/${USER}/workbench-images \
  -e RELEASE=2024b

# Build with cache
make jupyter-datascience-ubi9-python-3.11 \
  -e CONTAINER_BUILD_CACHE_ARGS=""

# Build and push images
make jupyter-pytorch-ubi9-python-3.11 \
  -e PUSH_IMAGES=yes
```

### Testing

```bash
# Deploy workbench for testing
make deploy9-jupyter-minimal-ubi9-python-3.11

# Run test suite
make test-jupyter-minimal-ubi9-python-3.11

# Validate runtime image
make validate-runtime-image image=quay.io/opendatahub/workbench-images:runtime-minimal-ubi9-python-3.11

# Cleanup
make undeploy9-jupyter-minimal-ubi9-python-3.11
```

### Local Execution

```bash
# Run Jupyter workbench locally
podman run -it -p 8888:8888 \
  quay.io/opendatahub/workbench-images:jupyter-minimal-ubi9-python-3.11-2024b-20241011-71fd041

# Run code-server workbench locally
podman run -it -p 8080:8080 \
  quay.io/opendatahub/workbench-images:codeserver-ubi9-python-3.11-2024b-20241011-71fd041
```

## Key Files and Directories

```
notebooks/
├── base/                    # Base images with Python and utilities
│   ├── ubi9-python-3.11/   # UBI9 with Python 3.11
│   └── ubi9-python-3.9/    # UBI9 with Python 3.9
├── jupyter/                 # Jupyter workbench variants
│   ├── minimal/            # Minimal JupyterLab
│   ├── datascience/        # Data science stack
│   ├── pytorch/            # PyTorch framework
│   ├── tensorflow/         # TensorFlow framework
│   ├── trustyai/           # TrustyAI tools
│   ├── intel/              # Intel GPU optimized
│   └── rocm/               # AMD GPU optimized
├── codeserver/             # VS Code workbenches
├── rstudio/                # RStudio workbenches
├── runtimes/               # Runtime images for pipelines
│   ├── minimal/
│   ├── datascience/
│   ├── pytorch/
│   ├── tensorflow/
│   ├── rocm-pytorch/
│   └── rocm-tensorflow/
├── cuda/                   # NVIDIA CUDA base images
├── rocm/                   # AMD ROCm base images
├── intel/                  # Intel GPU base images
├── amd/                    # AMD-specific images
├── manifests/              # Deployment manifests
│   ├── base/              # ImageStream and ConfigMap definitions
│   └── overlays/          # Kustomize overlays for variants
├── scripts/                # Utility scripts
├── ci/                     # CI/CD scripts
├── tests/                  # Test suite
├── Makefile               # Build automation
└── pyproject.toml         # Python project configuration
```

## Notes

- **No Operator**: This component does not include a Kubernetes operator. Images are launched by the ODH Notebook Controller.
- **No CRDs**: No custom resources defined. Images are referenced via OpenShift ImageStreams.
- **Multi-Architecture**: Images support x86_64 architecture (amd64). ARM support may be limited.
- **Security Context**: All images designed to run as UID 1001 with supplemental GID 0 (OpenShift restricted SCC compatible).
- **Persistent Storage**: Workbenches expect PVC mounted at `/opt/app-root/src` for user data persistence (managed by controller).
- **Environment Variables**: Workbenches support extensive configuration via env vars (see start-notebook.sh, run-code-server.sh).
- **Health Checks**: Jupyter uses HTTP probe at `/notebook/{namespace}/{username}/api`, code-server uses custom nginx health endpoints.
- **Automated Updates**: GitHub Actions automatically update image digests and dependencies.

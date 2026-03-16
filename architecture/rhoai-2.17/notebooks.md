# Component: Workbench Images (Notebooks)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v20xx.1-567-gcf3ee450e
- **Branch**: rhoai-2.17
- **Distribution**: RHOAI (also used in ODH)
- **Languages**: Python, Shell, Makefile
- **Deployment Type**: Container Images

## Purpose
**Short**: Provides pre-configured workbench container images for data science and machine learning development environments.

**Detailed**: This repository builds and maintains a collection of container images that serve as workbench environments for data scientists and ML engineers. These images include JupyterLab, RStudio Server, and VS Code Server (code-server) variants, each pre-configured with specific Python versions, ML frameworks (PyTorch, TensorFlow), GPU support (CUDA, ROCm, Intel), and data science libraries. The images are designed to be launched by the ODH Notebook Controller and provide browser-based integrated development environments where users can write, edit, debug, and execute code for machine learning workflows. Images are built on UBI9, RHEL9, or CentOS Stream 9 base images and follow a twice-yearly major release cycle (e.g., 2024a, 2024b) with weekly security patches, maintaining support for a minimum of one year.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Base Layers | Foundation images with Python 3.9 or 3.11 on UBI9/RHEL9/C9S |
| Jupyter Minimal | Workbench Image | Minimal JupyterLab environment with Python and basic dependencies |
| Jupyter Data Science | Workbench Image | Standard data science environment with common ML libraries, database clients, and tools |
| Jupyter PyTorch | Workbench Image | PyTorch-optimized environment for deep learning and computer vision |
| Jupyter TensorFlow | Workbench Image | TensorFlow environment for ML model building and training |
| Jupyter TrustyAI | Workbench Image | Environment with model explainability and accountability tools |
| CUDA Notebooks | GPU Workbench Images | GPU-accelerated variants with NVIDIA CUDA Toolkit |
| ROCm Notebooks | GPU Workbench Images | AMD GPU-accelerated variants with ROCm libraries |
| Intel Notebooks | GPU Workbench Images | Intel GPU-accelerated variants with Intel optimization libraries |
| Code Server | IDE Workbench | VS Code Server browser-based IDE for collaborative development |
| RStudio Server | IDE Workbench | R programming environment with RStudio IDE |
| Runtime Images | Headless Execution | Minimal runtime images without JupyterLab UI for pipeline execution |
| ImageStreams | Kubernetes Resources | OpenShift ImageStream definitions referencing container images |
| BuildConfigs | Build Resources | OpenShift BuildConfig definitions for RStudio source builds |

## APIs Exposed

### Custom Resource Definitions (CRDs)

No CRDs defined. This component provides container images consumed by other components.

### HTTP Endpoints

Endpoints are exposed by the running workbench containers when spawned by the notebook controller:

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | Token/OAuth | JupyterLab web interface |
| /api/* | GET, POST | 8888/TCP | HTTP | None | Token/OAuth | Jupyter Server API |
| /lab/* | GET | 8888/TCP | HTTP | None | Token/OAuth | JupyterLab application |
| / | GET | 8787/TCP | HTTP | None | Basic Auth | RStudio Server web interface (RStudio images only) |
| / | GET | 8080/TCP | HTTP | None | Token | VS Code Server web interface (Code Server images only) |

Note: Actual network encryption and authentication are handled by OpenShift routes and the notebook controller deployment, not by the container images themselves.

### gRPC Services

No gRPC services exposed.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9/RHEL9 Base | 9.x | Yes | Operating system base image |
| Python | 3.9, 3.11 | Yes | Programming runtime |
| JupyterLab | 3.5-4.2 | Yes (Jupyter variants) | Interactive notebook interface |
| PyTorch | 2.x | No (PyTorch variants) | Deep learning framework |
| TensorFlow | 2.x | No (TensorFlow variants) | Machine learning framework |
| CUDA Toolkit | 11.8, 12.x | No (CUDA variants) | NVIDIA GPU acceleration |
| ROCm | 5.x, 6.x | No (ROCm variants) | AMD GPU acceleration |
| Intel Extension for PyTorch | Latest | No (Intel variants) | Intel GPU optimization |
| RStudio Server | 2024.04.2 | Yes (RStudio only) | R IDE server |
| Code Server | Latest | Yes (Code Server only) | VS Code server |
| Elyra | Latest | No (Data Science variants) | JupyterLab extension for AI/ML pipelines |
| Pandas | 1.5-2.x | No (Data Science variants) | Data manipulation library |
| NumPy | 1.24+ | No (Data Science variants) | Numerical computing library |
| Scikit-learn | 1.2+ | No (Data Science variants) | Machine learning library |
| Matplotlib | 3.6+ | No (Data Science variants) | Plotting library |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-notebook-controller | Image Consumer | Spawns workbench containers from these images |
| odh-dashboard | Image Registry | Displays available workbench images via ImageStream annotations |
| kubeflow-notebook-controller | Image Consumer | Alternative notebook spawner (upstream) |

## Network Architecture

### Services

Services are created dynamically by the notebook controller when users spawn workbenches. The images themselves do not define services.

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| [dynamic-workbench-service] | ClusterIP | 8888/TCP | 8888 | HTTP | None | Token | Internal |
| [dynamic-rstudio-service] | ClusterIP | 8787/TCP | 8787 | HTTP | None | Basic Auth | Internal |
| [dynamic-codeserver-service] | ClusterIP | 8080/TCP | 8080 | HTTP | None | Token | Internal |

Note: Actual service names are generated by the notebook controller based on workbench instance names.

### Ingress

Ingress routes are created by the notebook controller, not by these images.

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| [dynamic-workbench-route] | OpenShift Route | [generated-hostname] | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

Container egress depends on user workloads. Common patterns:

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI Mirrors | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation |
| Conda Repos | 443/TCP | HTTPS | TLS 1.2+ | None | Conda package installation |
| S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Data access |
| Git Repositories | 443/TCP, 22/TCP | HTTPS, SSH | TLS 1.2+, SSH | Git credentials | Source code management |
| Object Storage | 443/TCP | HTTPS | TLS 1.2+ | S3 API Keys | Model/data storage |
| Container Registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secrets | Custom image pulls |

## Security

### RBAC - Cluster Roles

RBAC is not defined in this repository. Access control is managed by the notebook controller and OpenShift.

### RBAC - Role Bindings

RBAC is not defined in this repository. Access control is managed by the notebook controller and OpenShift.

### Secrets

Secrets are not defined in the image manifests. The following secrets may be consumed at runtime:

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| rhel-subscription-secret | Opaque | RHEL subscription for RStudio BuildConfig | Admin | No |
| aws-connection-* | Opaque | S3 credentials for data access | User/Admin | No |
| git-credentials | kubernetes.io/basic-auth | Git repository access | User | No |
| notebook-oauth-config | Opaque | OAuth configuration for notebook authentication | Notebook Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| JupyterLab UI | All | Token-based or OAuth Proxy | JupyterLab Server | Per-workbench token |
| RStudio Server | All | Basic Auth or OAuth Proxy | RStudio Server | Username/password |
| Code Server | All | Token-based or OAuth Proxy | Code Server | Per-instance token |

Note: OAuth integration and route-level authentication are configured by the notebook controller and OpenShift routes.

## Data Flows

### Flow 1: User Accesses Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | OAuth/Bearer Token |
| 2 | OpenShift Router | Workbench Pod | 8888/TCP | HTTP | None | Token forwarded |
| 3 | Workbench Pod | JupyterLab Process | 8888/TCP | HTTP | None | Internal |

### Flow 2: Install Python Package

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workbench Pod | PyPI/Conda Mirror | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | Workbench Pod | Container Filesystem | - | - | None | None |

### Flow 3: Access S3 Data

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Workbench Pod | S3 Endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Access Keys |
| 2 | S3 Endpoint | Workbench Pod | 443/TCP | HTTPS | TLS 1.2+ | Response |

### Flow 4: Build RStudio Image (BuildConfig)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | OpenShift Build | GitHub | 443/TCP | HTTPS | TLS 1.2+ | None (public repo) |
| 2 | OpenShift Build | Base Image Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 3 | OpenShift Build | Internal Registry | 443/TCP | HTTPS | TLS 1.2+ | Service Account |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| odh-notebook-controller | Container Spawn | - | - | - | Launches workbench pods from these images |
| odh-dashboard | Metadata Query | - | - | - | Reads ImageStream annotations to display workbench options |
| OpenShift Internal Registry | Image Pull | 5000/TCP | HTTPS | TLS | Pulls container images for pod creation |
| Quay.io Registry | Image Pull | 443/TCP | HTTPS | TLS 1.2+ | Pulls pre-built images referenced in ImageStreams |

## Container Image Variants

### Jupyter Workbenches

| Image Name | Base OS | Python | GPU | Key Frameworks/Libraries |
|------------|---------|--------|-----|--------------------------|
| jupyter-minimal | UBI9 | 3.11 | No | JupyterLab 4.2 |
| jupyter-datascience | UBI9 | 3.11 | No | Pandas, NumPy, Scikit-learn, Elyra, DB clients |
| jupyter-pytorch | UBI9 | 3.11 | CUDA/ROCm | PyTorch 2.x, CUDA 12.x/ROCm 6.x |
| jupyter-tensorflow | UBI9 | 3.11 | CUDA/ROCm | TensorFlow 2.x, CUDA 12.x/ROCm 6.x |
| jupyter-trustyai | UBI9 | 3.11 | No | TrustyAI explainability tools |
| jupyter-minimal-gpu | UBI9 | 3.11 | CUDA | CUDA Toolkit 11.8/12.x |
| jupyter-intel-ml | UBI9 | 3.11 | Intel GPU | Intel Extension for PyTorch |
| jupyter-intel-pytorch | UBI9 | 3.11 | Intel GPU | PyTorch + Intel optimizations |
| jupyter-intel-tensorflow | UBI9 | 3.11 | Intel GPU | TensorFlow + Intel optimizations |
| jupyter-rocm-minimal | UBI9 | 3.11 | ROCm | ROCm 6.x |
| jupyter-rocm-pytorch | UBI9 | 3.11 | ROCm | PyTorch + ROCm 6.x |
| jupyter-rocm-tensorflow | UBI9 | 3.11 | ROCm | TensorFlow + ROCm 6.x |

### Other Workbenches

| Image Name | Base OS | Primary Language | GPU | Key Tools |
|------------|---------|------------------|-----|-----------|
| code-server | UBI9 | Python 3.11 | No | VS Code Server, OpenShift CLI |
| rstudio-server | RHEL9/C9S | R 4.4 + Python 3.11 | Optional CUDA | RStudio Server 2024.04.2 |

### Runtime Images

Runtime images are minimal variants without JupyterLab UI, intended for pipeline execution:

| Image Name | Base OS | Python | GPU | Purpose |
|------------|---------|--------|-----|---------|
| runtime-minimal | UBI9 | 3.11 | No | Minimal runtime for Python scripts |
| runtime-datascience | UBI9 | 3.11 | No | Data science runtime for pipelines |
| runtime-pytorch | UBI9 | 3.11 | CUDA/ROCm | PyTorch runtime for model serving |
| runtime-tensorflow | UBI9 | 3.11 | CUDA/ROCm | TensorFlow runtime for model serving |
| runtime-rocm-pytorch | UBI9 | 3.11 | ROCm | PyTorch + ROCm runtime |
| runtime-rocm-tensorflow | UBI9 | 3.11 | ROCm | TensorFlow + ROCm runtime |
| intel-runtime-ml | UBI9 | 3.11 | Intel GPU | Intel-optimized ML runtime |
| intel-runtime-pytorch | UBI9 | 3.11 | Intel GPU | Intel PyTorch runtime |
| intel-runtime-tensorflow | UBI9 | 3.11 | Intel GPU | Intel TensorFlow runtime |

## Deployment Manifests

### ImageStream Resources (manifests/base/)

| Resource Name | Type | Tags | Purpose |
|---------------|------|------|---------|
| s2i-minimal-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1, 1.2 | References Jupyter Minimal images |
| s2i-datascience-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1, 1.2 | References Jupyter Data Science images |
| s2i-pytorch-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1, 1.2 | References PyTorch images |
| s2i-tensorflow-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1, 1.2 | References TensorFlow images |
| s2i-trustyai-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1 | References TrustyAI images |
| code-server-notebook | ImageStream | 2024.2, 2024.1, 2023.2 | References Code Server images |
| rstudio-rhel9 | ImageStream | latest | References RStudio Server images |
| cuda-s2i-minimal-notebook | ImageStream | 2024.2, 2024.1, 2023.2, 2023.1, 1.2 | References CUDA GPU images |
| rocm-minimal-notebook | ImageStream | 2024.2 | References ROCm minimal images |
| rocm-pytorch-notebook | ImageStream | 2024.2 | References ROCm PyTorch images |
| rocm-tensorflow-notebook | ImageStream | 2024.2 | References ROCm TensorFlow images |

### BuildConfig Resources

| Resource Name | Type | Source Repo | Branch | Dockerfile Path | Output |
|---------------|------|-------------|--------|-----------------|--------|
| rstudio-server-rhel9 | BuildConfig | github.com/red-hat-data-services/notebooks | rhoai-2.17 | rstudio/rhel9-python-3.11/Dockerfile | rstudio-rhel9:latest |
| cuda-rstudio-rhel9 | BuildConfig | github.com/red-hat-data-services/notebooks | rhoai-2.17 | rstudio/rhel9-python-3.11/Dockerfile (with CUDA) | cuda-rstudio-rhel9:latest |

### ConfigMaps

| ConfigMap Name | Purpose | Generated From |
|----------------|---------|----------------|
| notebooks-parameters | Stores image references (SHA256 digests) for all workbench images | params.env |
| notebook | Stores build commit information for image traceability | commit.env |

## Build and Release Process

### Build Strategy

- **Container Engine**: Podman or Docker
- **Base Images**: Built on UBI9, RHEL9, or CentOS Stream 9
- **Dependency Management**: Pipenv with locked dependencies (Pipfile.lock)
- **Build Process**: Multi-stage builds using base → minimal → specialized image hierarchy
- **Caching**: Configurable via CONTAINER_BUILD_CACHE_ARGS (default: --no-cache)
- **Registry**: Images published to quay.io/opendatahub/workbench-images and quay.io/modh/* for RHOAI

### Release Cycle

- **Major Releases**: Twice yearly (e.g., 2024a, 2024b) with major/minor version updates
- **Patch Updates**: Weekly security and bug fix updates (PATCH version only)
- **Support Period**: Minimum 1 year per major release
- **Tag Format**: `{image-name}-{release}-{YYYYMMDD}-{commit}` (e.g., jupyter-minimal-ubi9-python-3.11-2024a-20240317-6f4c36b)
- **Version Tags**: N (current), N-1, N-2, N-3, N-4 maintained in ImageStreams

### Image Annotations

Images include OpenDataHub-specific annotations for dashboard integration:
- **opendatahub.io/notebook-image**: "true" flag for workbench images
- **opendatahub.io/notebook-image-name**: Display name
- **opendatahub.io/notebook-image-desc**: Description
- **opendatahub.io/notebook-software**: JSON list of included software
- **opendatahub.io/notebook-python-dependencies**: JSON list of Python libraries
- **opendatahub.io/workbench-image-recommended**: Recommended tag flag
- **opendatahub.io/image-tag-outdated**: Deprecated tag flag

## Recent Changes

| Commit | Date | Changes |
|---------|------|---------|
| cf3ee450e | 2025-01-30 | - Merge pull request #501: RHOAI 2.17 updates |
| b92985704 | 2025-01-30 | - RHOAIENG-17368: Update package versions script for 2.16.1 support |
| 1aeb53469 | 2025-01-30 | - Merge pull request #490: Sync from main branch |
| 3d0f2dd67 | 2025-01-30 | - Update image commits for release N-1 via digest updater |
| 7c5406e61 | 2025-01-30 | - Update image commits for release N-1 |
| 0e00e3a9e | 2025-01-30 | - Update images for release N-1 |
| 8c1bba25d | 2025-01-30 | - Update poetry.lock file to fix CI |
| 7ff6e91db | 2025-01-30 | - Update image commits for release N |
| 3d92ea4fa | 2025-01-30 | - Update images for release N |
| 013350dcc | 2025-01-30 | - Merge pull request #489: Sync downstream main |
| 15eedcf48 | 2025-01-30 | - Update RStudio source build branch |
| 8f0f3efe6 | 2025-01-30 | - Merge from upstream notebooks repository |
| f213a5971 | 2025-01-30 | - Update ImageStream files with new package versions |
| aa71029f3 | 2025-01-30 | - Cherry-pick updates from upstream |
| 23289b8d9 | 2025-01-30 | - Cherry-pick updates from upstream |
| 8ab739e35 | 2025-01-30 | - Merge pull request #836: ODH sync for CodeFlare |
| 5fe1aa8e1 | 2025-01-30 | - Updated notebooks via odh-sync-updater |
| a10b80984 | 2025-01-30 | - Update Pipfile.lock files via renewal action |
| 8a24d011b | 2025-01-30 | - Fix: Use yq instead of sed in deploy target |
| d8917bf01 | 2025-01-30 | - Add Kubeflow Pipelines SDK to dependencies |

## Key Features and Capabilities

### Pre-configured Environments
- **JupyterLab**: Versions 3.5-4.2 with extensions and themes
- **Database Clients**: MySQL, PostgreSQL, MSSQL, MongoDB (in Data Science variants)
- **Git LFS**: For handling large files (audio, video, datasets, graphics)
- **Mesa-libGL**: OpenCV support
- **unixODBC**: Standardized database access
- **libsndfile**: Audio file processing

### GPU Support
- **NVIDIA CUDA**: CUDA Toolkit 11.8 and 12.x for GPU acceleration
- **AMD ROCm**: ROCm 5.x and 6.x for AMD GPU support
- **Intel GPU**: Intel Extension for PyTorch for Intel GPU optimization

### Developer Tools
- **Code Server**: VS Code in the browser for Python/general development
- **RStudio**: Full R development environment with IDE
- **Elyra**: JupyterLab extension for visual pipeline editing (Data Science variants)

### Customization
- **Pip Install Support**: Users can install additional packages at runtime
- **Conda Support**: Conda environment management
- **Custom Images**: Users can derive custom images from these base images
- **Environment Variables**: Configurable startup behavior (NOTEBOOK_PORT, NOTEBOOK_BASE_URL, NOTEBOOK_ROOT_DIR)

## Limitations and Constraints

1. **Image Size**: GPU-enabled images are large (5-10 GB) due to CUDA/ROCm libraries
2. **Build Time**: Full image builds can take 30+ minutes for complex variants
3. **RHEL Subscription**: RStudio BuildConfigs require RHEL subscription secret
4. **GPU Hardware**: GPU-enabled images require appropriate node selectors/tolerations
5. **Python Version Lock**: Each release locks to specific Python version (3.9 or 3.11)
6. **Package Updates**: Only PATCH updates during release lifecycle (no MAJOR/MINOR)
7. **Browser-based**: All workbenches require browser access (no native IDE support)
8. **Resource Requirements**: Minimum 2Gi memory recommended, GPU variants require more

## Testing and Validation

- **Self-tests**: pytest-based tests in tests/ directory
- **Runtime Validation**: validate-runtime-image target for runtime images
- **Required Commands**: Runtime images must have curl and python3 installed
- **Code Server Validation**: Must have curl, python, oc, and code-server
- **RStudio Validation**: Must have curl, python, oc, and /usr/lib/rstudio-server/bin/rserver

## Future Considerations

1. **Python 3.12+**: Migration to newer Python versions in future releases
2. **JupyterLab 5.x**: Upgrade to JupyterLab 5.x series
3. **ROCm Expansion**: More AMD GPU-optimized variants
4. **Intel GPU**: Expanded Intel GPU support as hardware availability increases
5. **Container Optimization**: Reduce image sizes through layer optimization
6. **ARM Support**: Potential ARM64 variants for Apple Silicon and ARM servers
7. **Air-gapped Deployment**: Better support for disconnected environments

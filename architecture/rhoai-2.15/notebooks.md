# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v20xx.1-418-g872a480a3
- **Branch**: rhoai-2.15
- **Distribution**: RHOAI (based on ODH upstream)
- **Languages**: Python, Shell
- **Deployment Type**: Container Images (deployed via ImageStream/BuildConfig)

## Purpose
**Short**: Provides pre-built container images for data science workbenches including Jupyter notebooks, RStudio, and VS Code Server with support for various ML frameworks and hardware accelerators.

**Detailed**: The notebooks repository builds and maintains a collection of container images that serve as interactive development environments (workbenches) for data scientists and ML engineers. These images are built on Red Hat Universal Base Image (UBI9), RHEL9, and CentOS Stream 9, and come pre-configured with popular data science tools, machine learning frameworks (PyTorch, TensorFlow), and libraries. The repository supports multiple hardware accelerators including NVIDIA GPUs (CUDA), AMD GPUs (ROCm), Intel GPUs, and Habana accelerators. Images are published to quay.io/modh (Managed Open Data Hub) registry and deployed in OpenShift/Kubernetes environments using ImageStream resources. The repository maintains both full notebook images (with JupyterLab UI) and lightweight runtime images (for Elyra pipeline execution). Images follow a versioned release strategy with bi-annual major releases (YYYYx format) and weekly security patch updates.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Build Layer | Foundation images providing Python runtime, OS packages, and OpenShift client tools |
| Jupyter Notebooks | Interactive Workbench | Full-featured JupyterLab environments with various ML frameworks and libraries |
| Runtime Images | Lightweight Execution | Minimal images for running Elyra pipeline tasks without UI overhead |
| Code Server | IDE Workbench | VS Code web-based IDE environment for Python development |
| RStudio | IDE Workbench | R-based statistical computing and graphics environment |
| Hardware Accelerator Images | Specialized Builds | CUDA, ROCm, Intel, and Habana-optimized images for GPU/accelerator workloads |
| Build System | Makefile/Podman | Multi-stage build pipeline with dependency chain management |
| Manifests | Kustomize Deployment | ImageStream and BuildConfig resources for OpenShift deployment |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It consumes CRDs defined by other components:
- Uses OpenShift ImageStream API (image.openshift.io/v1)
- Uses OpenShift BuildConfig API (build.openshift.io/v1)
- Notebooks are launched by the ODH Notebook Controller which uses the Kubeflow Notebook CRD

### HTTP Endpoints

Workbench containers expose the following endpoints when deployed:

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None (Pod-local) | OAuth Proxy | JupyterLab web interface |
| /notebook/* | GET, POST | 8888/TCP | HTTP | None (Pod-local) | OAuth Proxy | Jupyter notebook operations |
| /api/* | GET, POST | 8888/TCP | HTTP | None (Pod-local) | OAuth Proxy | Jupyter REST API |
| /lab/* | GET, POST | 8888/TCP | HTTP | None (Pod-local) | OAuth Proxy | JupyterLab UI resources |
| / | GET | 8787/TCP | HTTP | None (Pod-local) | OAuth Proxy | RStudio web interface (RStudio images) |
| / | GET | 8080/TCP | HTTP | None (Pod-local) | OAuth Proxy | Code Server web interface (Code Server images) |

**Note**: In production, these HTTP endpoints are fronted by an OAuth proxy sidecar that provides authentication and TLS termination. Direct access is via HTTPS through OpenShift Routes.

### gRPC Services

| Service | Port | Protocol | Encryption | Auth | Purpose |
|---------|------|----------|------------|------|---------|
| N/A | N/A | N/A | N/A | N/A | No gRPC services exposed |

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Red Hat UBI9 | latest | Yes | Base OS image providing security-hardened container foundation |
| Python | 3.9, 3.11 | Yes | Primary runtime for Jupyter and data science libraries |
| JupyterLab | 3.x, 4.2 | Yes (notebooks) | Web-based interactive development environment |
| Elyra | 3.x-4.x | Yes (runtime) | Pipeline orchestration and notebook scheduling |
| PyTorch | 2.x | No | Deep learning framework for PyTorch images |
| TensorFlow | 2.x | No | Deep learning framework for TensorFlow images |
| CUDA Toolkit | 11.8, 12.x | No | NVIDIA GPU acceleration libraries |
| ROCm | 5.x, 6.x | No | AMD GPU acceleration libraries |
| Intel oneAPI | latest | No | Intel GPU acceleration libraries |
| Habana SDK | latest | No | Habana accelerator libraries |
| OpenShift Client (oc) | stable | Yes | CLI tool for cluster interaction from notebooks |
| Pandas | latest | Yes | Data manipulation and analysis |
| NumPy | latest | Yes | Numerical computing library |
| scikit-learn | latest | Yes | Machine learning algorithms |
| Matplotlib | latest | Yes | Data visualization |
| Code Server | 4.x | No | VS Code web interface (Code Server images) |
| RStudio Server | latest | No | R IDE server (RStudio images) |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | Notebook CR Reconciliation | Creates StatefulSet/Pod from notebook images, manages lifecycle |
| ODH Dashboard | ImageStream Discovery | Lists available notebook images via annotations for user selection |
| OAuth Proxy | HTTP Sidecar | Provides authentication and authorization for notebook access |
| OpenShift Image Registry | Image Pull | Sources container images during pod creation |
| Elyra Pipeline Service | Runtime Image Execution | Executes runtime images as pipeline tasks in KFP/Tekton |
| Model Registry | Optional Integration | Stores and versions ML models from notebooks |
| Data Science Pipelines | Pipeline Execution | Uses runtime images for automated ML workflow steps |

## Network Architecture

### Services

Workbench pods expose services dynamically when created by the Notebook Controller:

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | None | OAuth Proxy | Internal |
| notebook-{name}-tls | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth Proxy | Internal |
| rstudio-{name} | ClusterIP | 8787/TCP | 8787 | HTTP | None | OAuth Proxy | Internal (RStudio) |
| codeserver-{name} | ClusterIP | 8080/TCP | 8080 | HTTP | None | OAuth Proxy | Internal (Code Server) |

**Note**: Service names are generated dynamically based on the Notebook CR name. Services are created by the ODH Notebook Controller.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{name}-route | OpenShift Route | *.apps.{cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

**Note**: Routes are created by the ODH Notebook Controller to expose notebook workbenches externally. TLS termination occurs at the route level, traffic to OAuth proxy is re-encrypted.

### Egress

Workbench containers require egress for package installation and data access:

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation via pip |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Container image pulls for base images |
| cdn.redhat.com | 443/TCP | HTTPS | TLS 1.2+ | Subscription | Red Hat package repositories (RHEL images) |
| mirror.openshift.com | 443/TCP | HTTPS | TLS 1.2+ | None | OpenShift client (oc) downloads |
| S3 endpoints | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Data access from object storage |
| GitHub/GitLab | 443/TCP | HTTPS | TLS 1.2+ | SSH Keys/Tokens | Git operations for notebooks and code |
| Model Registry | 8080/TCP | HTTP | mTLS | Service Account | Model versioning and storage (if enabled) |
| OpenShift API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token | Cluster operations via oc/kubectl |

## Security

### RBAC - Cluster Roles

The notebook images themselves do not create ClusterRoles. RBAC is managed by the ODH Notebook Controller and workbench deployment process. However, the service account used by notebooks may have these typical permissions:

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| system:image-puller | "" | pods, services | get, list |
| notebook-controller-role | kubeflow.org | notebooks | get, list, watch, create, update, patch, delete |
| default (namespace) | "" | configmaps, secrets, persistentvolumeclaims | get, list, watch |

**Note**: Actual RBAC policies are defined by the deployment operator (ODH/RHOAI operator), not by this image repository.

### RBAC - Role Bindings

| Binding Name | Namespace | Role | Service Account |
|--------------|-----------|------|-----------------|
| notebook-sa-binding | User namespace | default | notebook-sa |
| image-puller-binding | User namespace | system:image-puller | default |

**Note**: Role bindings are created by the ODH Notebook Controller when deploying workbench instances.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| notebook-oauth-config | Opaque | OAuth proxy configuration | Notebook Controller | No |
| notebook-oauth-proxy-tls | kubernetes.io/tls | TLS certificates for OAuth proxy | OpenShift Service CA | Yes |
| git-credentials | Opaque | Git authentication for repository access | User/Admin | No |
| aws-credentials | Opaque | S3 access credentials for data storage | User/Admin | No |
| image-pull-secret | kubernetes.io/dockerconfigjson | Pull images from private registries | Admin | No |
| notebook-env-vars | Opaque | Environment variables for notebook configuration | User/Notebook Controller | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| JupyterLab UI | GET, POST | OAuth2 (OpenShift) | OAuth Proxy Sidecar | User must be notebook owner or have namespace access |
| Jupyter API | GET, POST | OAuth2 + Bearer Token | OAuth Proxy Sidecar | Same as UI + API token validation |
| RStudio UI | GET, POST | OAuth2 (OpenShift) | OAuth Proxy Sidecar | User must be notebook owner |
| Code Server UI | GET, POST | OAuth2 (OpenShift) | OAuth Proxy Sidecar | User must be notebook owner |
| Cluster API (oc/kubectl) | ALL | Service Account Token | OpenShift API Server | RBAC based on service account permissions |
| S3 Object Storage | GET, PUT | AWS IAM Credentials | S3 Gateway | IAM policies on bucket/prefix |
| Git Operations | ALL | SSH Key/Personal Token | Git Provider | Repository permissions |

## Data Flows

### Flow 1: User Accessing Notebook Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Route | 443/TCP | HTTPS | TLS 1.2+ (Edge) | OpenShift Session Cookie |
| 2 | Route | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ (Re-encrypt) | OAuth Token Validation |
| 3 | OAuth Proxy | JupyterLab Container | 8888/TCP | HTTP | None (localhost) | Proxy-injected headers |
| 4 | JupyterLab | OpenShift API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |

### Flow 2: Package Installation (pip install)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | JupyterLab Container | PyPI CDN | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | pip | PyPI Repository | 443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | pip | Local Filesystem | N/A | File I/O | None | POSIX permissions |

### Flow 3: Elyra Pipeline Runtime Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Elyra (JupyterLab) | Kubeflow Pipelines API | 8888/TCP | HTTP | None (cluster-local) | Bearer Token |
| 2 | KFP Controller | OpenShift API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 3 | OpenShift Scheduler | Runtime Image Pod | N/A | Pod Creation | N/A | RBAC |
| 4 | Runtime Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Credentials |
| 5 | Runtime Pod | KFP API | 8888/TCP | HTTP | None | Bearer Token (status updates) |

### Flow 4: Image Build and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | CI/CD System | Container Build | N/A | Local | N/A | N/A |
| 2 | Podman/Docker | Quay.io Registry | 443/TCP | HTTPS | TLS 1.2+ | Registry Credentials |
| 3 | ODH Operator | OpenShift API | 6443/TCP | HTTPS | TLS 1.3 | Service Account Token |
| 4 | ImageStream Controller | Quay.io Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 5 | Notebook Controller | Image Registry | 5000/TCP | HTTP | None (internal) | Service Account Token |

### Flow 5: Data Science Workflow (Training)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | JupyterLab Container | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Credentials |
| 2 | Training Process | GPU Driver | N/A | Device I/O | N/A | Device permissions |
| 3 | Training Process | Model Registry | 8080/TCP | HTTP | mTLS | Service Account Token |
| 4 | Model Registry | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Credentials |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Dashboard | ImageStream Annotations | N/A | Kubernetes API | TLS 1.3 | Discovery and display of available notebook images |
| ODH Notebook Controller | Notebook CR Spec | N/A | Kubernetes API | TLS 1.3 | Specifies which image to deploy for workbench |
| OAuth Proxy | HTTP Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | Authentication and authorization gateway |
| Elyra/KFP | Runtime Image Execution | N/A | Pod Execution | N/A | Executes pipeline tasks using runtime images |
| OpenShift Image Registry | Image Pull | 5000/TCP | HTTP | None (internal) | Caches and serves container images |
| Data Science Pipelines | Pipeline Runtime | N/A | Pod Execution | N/A | Runs data processing and ML training tasks |
| Model Mesh/KServe | Model Serving Context | N/A | Model Loading | N/A | Uses models trained in notebooks |
| Git Servers | Git Protocol | 443/TCP, 22/TCP | HTTPS, SSH | TLS 1.2+, SSH | Version control for notebooks and code |
| S3 Object Storage | S3 API | 443/TCP | HTTPS | TLS 1.2+ | Data persistence and model storage |
| Prometheus | Metrics Scraping | 8080/TCP | HTTP | None | JupyterLab metrics (if enabled) |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| 872a480a3 | 2024-10-18 | - Merge pull request for rsync-main updates |
| 44514fd9f | 2024-10-18 | - Updated Elyra and codeflare-sdk annotations |
| 5c4a9c7d4 | 2024-10-18 | - Digest Updater Action: Update Notebook Images |
| 00a138d91 | 2024-10-18 | - Merge rsync-main updates |
| 2a3eb4b50 | 2024-10-18 | - Automated digest update via GitHub action |
| 84a22b441 | 2024-10-18 | - Merge rsync-main updates |
| 36f1e6553 | 2024-10-18 | - Sync from ODH upstream repository |
| 3b3b4634c | 2024-10-17 | - Updated notebooks via odh-sync-updater action |
| eb80da3ac | 2024-10-16 | - Merge version update for odh-elyra 4.1.0 |
| db24a9eef | 2024-10-15 | - Updated odh-elyra from 4.0.3 to 4.1.1 |
| d07426e01 | 2024-10-15 | - Merge poetry venv improvements |
| 856b3d9de | 2024-10-14 | - Pin GitHub runner to ubuntu-22.04 to avoid podman flakes |
| e97cebbbb | 2024-10-14 | - Merge poetry venv fixes |
| 596ca147d | 2024-10-14 | - Merge NumPy version fix for TensorFlow image |
| c168a5c88 | 2024-10-14 | - Fix poetry install in GitHub Actions |
| 671ccb8ff | 2024-10-13 | - Fix TensorFlow image manifest to show proper NumPy version |
| 780424ca8 | 2024-10-11 | - Merge codeflare-sdk blocker fix |
| 7a4a4a713 | 2024-10-11 | - Include new 2024.1 images with updated codeflare-sdk |
| 4ed5bff54 | 2024-10-11 | - Merge Habana accelerator support updates |

## Container Image Variants

This repository produces multiple image variants organized by:

### Base OS Distributions
- **UBI9** (Red Hat Universal Base Image 9): Production RHOAI images
- **RHEL9** (Red Hat Enterprise Linux 9): Enterprise builds
- **C9S** (CentOS Stream 9): Upstream testing and development

### Python Versions
- Python 3.9 (older releases, maintenance mode)
- Python 3.11 (current recommended version)

### Workbench Types

#### Jupyter Notebooks
1. **jupyter-minimal**: Base Jupyter environment with essential packages
2. **jupyter-datascience**: Full data science stack (pandas, scikit-learn, matplotlib)
3. **jupyter-pytorch**: PyTorch deep learning framework
4. **jupyter-tensorflow**: TensorFlow deep learning framework
5. **jupyter-trustyai**: TrustyAI explainability and fairness tools
6. **jupyter-minimal-gpu**: CUDA-enabled minimal notebook
7. **jupyter-pytorch-gpu**: CUDA-enabled PyTorch notebook
8. **jupyter-tensorflow-gpu**: CUDA-enabled TensorFlow notebook

#### Hardware-Specific Variants
- **CUDA**: NVIDIA GPU support (jupyter-*-gpu variants)
- **ROCm**: AMD GPU support (jupyter-rocm-minimal, jupyter-rocm-pytorch, jupyter-rocm-tensorflow)
- **Intel**: Intel GPU support (Intel oneAPI variants)
- **Habana**: Habana Gaudi accelerator support (deprecated in recent versions)

#### Alternative IDEs
- **code-server**: VS Code web-based IDE
- **rstudio**: RStudio IDE for R programming

#### Runtime Images
- **runtime-minimal**: Lightweight Python runtime for Elyra pipelines
- **runtime-datascience**: Data science runtime for pipeline execution
- **runtime-pytorch**: PyTorch runtime for ML pipeline tasks
- **runtime-tensorflow**: TensorFlow runtime for ML pipeline tasks
- **runtime-rocm-pytorch**: AMD GPU-enabled PyTorch runtime
- **runtime-rocm-tensorflow**: AMD GPU-enabled TensorFlow runtime

### Image Registry and Tagging

**Primary Registry**: `quay.io/modh` (Managed Open Data Hub)

**Tagging Scheme**:
- Format: `{image-type}-{release}-{date}-{commit}`
- Example: `jupyter-datascience-ubi9-python-3.11-2024b-20241018-872a480`
- Weekly tag: `jupyter-datascience-ubi9-python-3.11-2024b-weekly` (latest patch)

**Version Support Policy**:
- Major releases: Twice per year (YYYYa, YYYYb format)
- Patch updates: Weekly security and bug fixes
- Support window: Minimum 1 year (typically 2 concurrent versions supported)
- N, N-1: Recommended and supported
- N-2, N-3, N-4: Available but deprecated (shown as outdated in UI)

### Build Dependencies

Images follow a hierarchical build chain:
```
Base Image (UBI9/RHEL9/C9S + Python)
  └─> Jupyter Minimal OR Runtime Minimal
       └─> Jupyter Datascience / PyTorch / TensorFlow
            └─> Specialized variants (TrustyAI, GPU-enabled)
```

Hardware accelerator images branch from base:
```
Base Image + CUDA/ROCm/Intel libraries
  └─> GPU-enabled Jupyter/Runtime variants
```

### Deployment via ImageStream

OpenShift ImageStream resources in `manifests/base/` define:
- Image metadata and annotations for ODH Dashboard
- Software versions (Python, JupyterLab, framework versions)
- Recommended/deprecated status flags
- Image ordering for UI display
- Multiple version tags (N, N-1, N-2, N-3, N-4) for rollback support

## Build and Release Process

### Local Development Build
```bash
make jupyter-minimal-ubi9-python-3.11 \
  -e IMAGE_REGISTRY=quay.io/myuser/workbench-images \
  -e RELEASE=2024b
```

### CI/CD Pipeline
1. **Source Changes**: Code/Dockerfile updates committed to repository
2. **Automated Builds**: GitHub Actions or OpenShift CI triggers builds
3. **Dependency Scanning**: Security scans via Quay.io vulnerability detection
4. **Image Push**: Tagged images pushed to quay.io/modh registry
5. **Digest Updates**: Automated PR updates image digests in manifests/base/params.env
6. **Manifest Sync**: ImageStream manifests updated with new image references
7. **Deployment**: ODH/RHOAI operator reconciles updated ImageStreams

### Weekly Patch Process
1. Base image updates (UBI9/RHEL9 patches)
2. Python package security updates (pip packages)
3. Rebuild all image variants
4. Update `params.env` with new image digests
5. Tag with YYYYMMDD date stamp
6. Update `-weekly` tag to latest build

### Major Release Process (Bi-annual)
1. Review and update all dependency versions
2. Test compatibility matrix (Python, JupyterLab, frameworks)
3. Update documentation and release notes
4. Create new version tag (e.g., 2024b)
5. Mark previous N-2 version as deprecated
6. Update ODH Dashboard metadata

## Testing and Validation

### Test Types
- **Unit Tests**: pytest-based tests in `tests/` directory
- **Container Tests**: Validate image structure and installed packages
- **Integration Tests**: Deploy notebooks and verify functionality
- **Runtime Validation**: Test Elyra pipeline execution with runtime images

### Test Execution
```bash
# Python unit tests
poetry run pytest

# Deploy and test specific notebook
make deploy9-jupyter-minimal
make test-jupyter-minimal
make undeploy9-jupyter-minimal

# Validate runtime image
make validate-runtime-image image=quay.io/modh/runtime-minimal-ubi9-python-3.11:2024b-weekly
```

### Quality Gates
- All images must pass security scanning
- Required commands must be present (curl, python, oc)
- JupyterLab must start successfully
- Kernels must execute basic Python code
- Package installations (pip) must work
- Git operations must function

## Configuration and Customization

### Environment Variables (Common)
- `JUPYTER_ENABLE_LAB`: Enable JupyterLab interface (default: yes)
- `JUPYTER_IMAGE_SPEC`: Image specification for spawner
- `NOTEBOOK_ARGS`: Additional Jupyter server arguments
- `JUPYTER_TOKEN`: Authentication token (usually managed by OAuth proxy)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: S3 credentials
- `GIT_CREDENTIALS`: Git authentication configuration

### Volume Mounts (Typical Deployment)
- `/opt/app-root/src`: User workspace (PVC-backed persistent storage)
- `/opt/app-root/runtimes`: Elyra runtime configurations
- `/etc/ssl/certs`: TLS certificate bundles for external access

### Custom Package Installation
Users can install additional packages at runtime:
```bash
pip install --user <package-name>
```

Persistent installations across restarts require:
- Installing in user directory (`--user` flag)
- Using persistent volume for `/opt/app-root/src`
- Creating custom derived images (for admin-managed packages)

## Monitoring and Observability

### Logs
- **Container logs**: `kubectl logs <notebook-pod> -c notebook`
- **OAuth proxy logs**: `kubectl logs <notebook-pod> -c oauth-proxy`
- **JupyterLab logs**: Accessible via UI (Help → Show Log Console)

### Metrics
- JupyterLab can expose Prometheus metrics (if metrics extension enabled)
- Resource usage: CPU, Memory, GPU utilization (via Kubernetes metrics)
- OpenShift monitoring integration for pod-level metrics

### Health Checks
- **Liveness probe**: HTTP GET to JupyterLab endpoint
- **Readiness probe**: Verifies Jupyter server is accepting connections
- **Startup probe**: Allows time for initial JupyterLab startup

## Security Considerations

### Container Security
- Built on Red Hat UBI9 (security-hardened base)
- Regular vulnerability scanning via Quay.io
- Weekly security patch updates
- Non-root user execution (UID 1001)
- Read-only root filesystem support (where applicable)

### Network Security
- All external traffic via OAuth-protected routes
- No direct pod-to-pod communication required
- Egress controls for package installation sources
- Optional network policies for namespace isolation

### Secrets Management
- Git credentials stored in Kubernetes secrets
- S3 credentials injected via environment variables
- No hardcoded credentials in images
- OAuth tokens managed by proxy sidecar

### Data Protection
- User data persisted to PVCs with encryption at rest (if CSI driver supports)
- Notebook files contain code/data - apply appropriate access controls
- Model artifacts may contain sensitive IP - use RBAC to restrict access

## Troubleshooting

### Common Issues

**Issue**: Notebook pod fails to start
- Check image pull errors: `kubectl describe pod <notebook-pod>`
- Verify ImageStream is importing correctly: `oc get imagestream`
- Check pull secret configuration

**Issue**: Package installation fails (pip)
- Verify egress connectivity to pypi.org
- Check for proxy configuration requirements
- Ensure sufficient storage in PVC

**Issue**: GPU not detected
- Verify node has GPU resources: `kubectl describe node`
- Check for CUDA/ROCm driver installation on node
- Ensure GPU-enabled image variant is used
- Verify resource requests include `nvidia.com/gpu` or `amd.com/gpu`

**Issue**: OAuth authentication fails
- Check OAuth proxy logs for errors
- Verify route TLS configuration
- Ensure user has permissions on namespace

## Future Enhancements

Based on recent commit history and roadmap:
- Continued Elyra version updates for pipeline improvements
- Expanded hardware accelerator support (Intel, Habana)
- Migration to Konflux build system (RHOAI 3.0+)
- JupyterLab 4.x standardization across all images
- Enhanced air-gapped installation support
- Improved CI/CD automation for digest updates

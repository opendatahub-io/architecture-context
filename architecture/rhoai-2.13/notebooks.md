# Component: Workbench Images (Notebooks)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks.git
- **Version**: v20xx.1-299-ge3bef34d1
- **Branch**: rhoai-2.13
- **Distribution**: RHOAI
- **Languages**: Python, Dockerfile, Shell, NGINX configuration
- **Deployment Type**: Container Images (ImageStreams)

## Purpose
**Short**: Provides pre-built container images for data science workbenches including Jupyter, VS Code, and RStudio environments with support for multiple hardware accelerators.

**Detailed**: The notebooks repository builds and maintains a collection of container images that serve as interactive development environments (workbenches) for data scientists and ML engineers. These images provide Jupyter notebooks, VS Code Server, and RStudio Server pre-configured with common data science libraries, ML frameworks (PyTorch, TensorFlow), and hardware acceleration support (NVIDIA CUDA, AMD ROCm, Intel Habana, Intel GPUs). The images are deployed as OpenShift ImageStreams and launched by the ODH/RHOAI notebook controller when users create workbench instances. The repository follows a layered build approach with base images, framework-specific images, and specialized runtime images for model serving. Images are versioned with twice-yearly major releases (e.g., 2024a) and weekly security patches, with a minimum one-year support lifecycle.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Image | Foundation layer with Python, system packages, and OpenShift tooling (oc client) |
| Jupyter Minimal | Container Image | Minimal JupyterLab environment with base notebook functionality |
| Jupyter DataScience | Container Image | Full data science stack with pandas, numpy, scikit-learn, database connectors |
| Jupyter PyTorch | Container Image | PyTorch ML framework with GPU support via CUDA/ROCm |
| Jupyter TensorFlow | Container Image | TensorFlow ML framework with GPU support via CUDA/ROCm |
| Jupyter TrustyAI | Container Image | Specialized image for AI explainability and fairness analysis |
| Jupyter Habana | Container Image | Intel Habana Gaudi accelerator support for ML workloads |
| CodeServer | Container Image | VS Code in browser with Python extensions and NGINX proxy |
| RStudio | Container Image | RStudio Server for R-based data analysis with NGINX proxy |
| Runtime Images | Container Image | Minimal images for serving models in production (no IDE) |
| CUDA Support | Container Layer | NVIDIA GPU acceleration libraries and drivers |
| ROCm Support | Container Layer | AMD GPU acceleration libraries and drivers |
| Intel Support | Container Layer | Intel GPU and oneAPI acceleration libraries |

## APIs Exposed

### Custom Resource Definitions (CRDs)

No CRDs are defined in this repository. Workbench images are consumed by the ODH/RHOAI notebook controller which manages Notebook CRD instances.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET | 8888/TCP | HTTP | None | None | JupyterLab web interface (Jupyter images) |
| /api/kernels | GET | 8888/TCP | HTTP | None | None | Jupyter kernel management API |
| /api/kernels/ | GET, POST | 8888/TCP | HTTP | None | None | Kernel lifecycle and culling API (via CGI) |
| /codeserver/ | GET | 8888/TCP | HTTP | None | None | VS Code web interface (CodeServer images) |
| /codeserver/healthz | GET | 8888/TCP | HTTP | None | None | Health check endpoint for CodeServer |
| /rstudio/ | GET | 8888/TCP | HTTP | None | None | RStudio web interface (RStudio images) |
| /rstudio/events/get_events | GET | 8888/TCP | HTTP | None | None | RStudio heartbeat endpoint |

**Note**: TLS termination and authentication are handled by the notebook controller and OpenShift Routes/Ingress. Workbench containers expose HTTP only on localhost within the pod.

### gRPC Services

No gRPC services are exposed by workbench images.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9 Base Image | registry.access.redhat.com/ubi9/python-39 | Yes | Base operating system and Python runtime |
| JupyterLab | ~3.6.7 | Yes (Jupyter images) | Interactive notebook web interface |
| Jupyter Server | ~2.13.0 | Yes (Jupyter images) | Backend server for Jupyter notebooks |
| code-server | v4.22.0 | Yes (CodeServer images) | VS Code in browser implementation |
| RStudio Server | 2023.12.1-402 | Yes (RStudio images) | R development environment server |
| NGINX | 1.24 | Yes (CodeServer/RStudio) | Reverse proxy for health checks and routing |
| supervisord | Latest | Yes (CodeServer/RStudio) | Process manager for multi-service containers |
| ODH Elyra | ~3.16.7 | No | Pipeline authoring and execution for Kubeflow |
| PyTorch | Various | No | Deep learning framework (PyTorch images) |
| TensorFlow | Various | No | Deep learning framework (TensorFlow images) |
| CUDA Toolkit | Various | No | NVIDIA GPU acceleration libraries |
| ROCm | Various | No | AMD GPU acceleration libraries |
| Intel oneAPI | Various | No | Intel GPU/Habana acceleration libraries |
| pandas | ~2.2.0 | No | Data manipulation library (DataScience images) |
| scikit-learn | ~1.4.0 | No | Machine learning library (DataScience images) |
| boto3 | ~1.34.50 | No | AWS SDK for S3/cloud storage access |
| codeflare-sdk | ~0.19.1 | No | Distributed computing framework integration |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| notebook-controller | Managed By | Launches workbench pods from these images |
| kubeflow-notebooks | CRD Consumer | Notebook controller creates pods using Notebook CRD |
| oauth-proxy | Sidecar | Provides authentication for workbench access |
| odh-dashboard | UI Integration | Dashboard presents available workbench images to users |
| kfp-tekton | Pipeline Integration | Elyra submits pipelines to Kubeflow Pipelines/Tekton |
| model-mesh | Model Serving | Runtime images used for serving deployed models |

## Network Architecture

### Services

Workbench images do not define Kubernetes Services directly. Services are created dynamically by the notebook controller when launching workbench instances.

**Typical Service (created by controller)**:

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook-{name} | ClusterIP | 8888/TCP | 8888 | HTTP | None | oauth-proxy | Internal (via Route) |

### Ingress

Workbench images do not define Ingress resources. OpenShift Routes are created by the notebook controller.

**Typical Route (created by controller)**:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{name} | OpenShift Route | {name}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (authenticated) |

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages at runtime via pip |
| CRAN (cran.rstudio.com) | 443/TCP | HTTPS | TLS 1.2+ | None | Install R packages at runtime (RStudio images) |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Keys | Access datasets and model artifacts via boto3 |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH Keys/Tokens | Clone repositories via jupyterlab-git/nbgitpuller |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Pull secrets | Pull additional container images (notebooks as sidecars) |
| Kubeflow Pipelines API | 8888/TCP | HTTP | None | K8s SA token | Submit pipeline runs from Elyra extension |
| OpenShift API | 6443/TCP | HTTPS | TLS 1.2+ | K8s SA token | Interact with cluster via oc client |

## Security

### RBAC - Cluster Roles

No ClusterRoles are defined in this repository. RBAC is managed by the notebook controller and workbench pods run with minimal permissions.

**Typical RBAC (created by controller)**:
- ServiceAccount: notebook-{name}
- RoleBinding: Grants access to read ConfigMaps, Secrets in workbench namespace
- No elevated cluster permissions required

### RBAC - Role Bindings

No RoleBindings are defined in this repository. Bindings are created dynamically by the notebook controller.

### Secrets

Workbench images do not provision secrets. Users can mount secrets into workbench pods for credentials.

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {user-secret} | Opaque | User-provided credentials (API keys, tokens) | User/Admin | No |
| git-credentials | kubernetes.io/ssh-auth | Git repository access for nbgitpuller | User | No |
| aws-credentials | Opaque | AWS S3 access keys for boto3 | User | No |
| data-connection | Opaque | Object storage credentials for data science work | User/Dashboard | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /* | GET, POST, PUT, DELETE, WebSocket | OAuth2 Proxy (OpenShift) | oauth-proxy sidecar | User must be authenticated to OpenShift cluster |
| /api/kernels | GET, POST | OAuth2 Proxy | oauth-proxy sidecar | Same user that owns the workbench pod |

**Authentication Flow**:
1. User accesses workbench via OpenShift Route (HTTPS)
2. oauth-proxy sidecar intercepts request, validates OpenShift session
3. On success, request forwarded to workbench container on localhost:8888
4. Workbench container serves content without additional auth (trusts sidecar)

### Network Policies

No NetworkPolicies are defined in this repository. Network policies are managed by ODH/RHOAI installation.

**Typical Policies (cluster-level)**:
- Allow ingress from OpenShift Router to workbench pods
- Allow egress to internet (PyPI, CRAN, Git, S3)
- Allow egress to OpenShift API server
- Allow egress to Kubeflow Pipelines

## Data Flows

### Flow 1: User Accesses Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 session cookie |
| 2 | OpenShift Router | oauth-proxy (sidecar) | 8443/TCP | HTTPS | TLS 1.2+ | OAuth2 token validation |
| 3 | oauth-proxy | Jupyter container | 8888/TCP | HTTP | None | Trusted (same pod) |
| 4 | Jupyter container | User Browser | 8888→443/TCP | HTTP→HTTPS | TLS 1.2+ (router) | OAuth2 (router) |

### Flow 2: Notebook Installs Python Package

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter container (pip) | PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | PyPI | Jupyter container | 443/TCP | HTTPS | TLS 1.2+ | None |

### Flow 3: Notebook Accesses S3 Data

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter container (boto3) | S3 endpoint | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM credentials (from secret) |
| 2 | S3 endpoint | Jupyter container | 443/TCP | HTTPS | TLS 1.2+ | AWS signature validation |

### Flow 4: Elyra Submits Pipeline

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter container (Elyra) | Kubeflow Pipelines API | 8888/TCP | HTTP | None | K8s ServiceAccount token |
| 2 | KFP API | Jupyter container | 8888/TCP | HTTP | None | Token validation |
| 3 | KFP API | Tekton/Argo | 8080/TCP | HTTP | None | Internal cluster auth |

### Flow 5: CodeServer/RStudio Health Check

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubelet | NGINX (localhost) | 8888/TCP | HTTP | None | None (localhost) |
| 2 | NGINX | code-server/rstudio | 8787/TCP | HTTP | None | None (localhost) |
| 3 | code-server/rstudio | NGINX | 8787/TCP | HTTP | None | None (localhost) |
| 4 | NGINX | Kubelet | 8888/TCP | HTTP | None | None (localhost) |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| notebook-controller | Pod Launcher | N/A | Kubernetes API | TLS 1.2+ | Creates pods from workbench images |
| oauth-proxy | Sidecar Container | 8888/TCP | HTTP | None (localhost) | Provides authentication for workbench access |
| odh-dashboard | UI Integration | N/A | N/A | N/A | Lists available workbench images from ImageStreams |
| Kubeflow Pipelines | REST API | 8888/TCP | HTTP | None | Submits ML pipelines from Elyra extension |
| OpenShift Registry | Image Pull | 5000/TCP | HTTPS | TLS 1.2+ | Pulls workbench images during pod creation |
| S3/Object Storage | boto3 SDK | 443/TCP | HTTPS | TLS 1.2+ | Reads/writes datasets and model artifacts |
| Git Repositories | HTTPS/SSH | 443/TCP or 22/TCP | HTTPS/SSH | TLS 1.2+/SSH | Clones repositories via jupyterlab-git |
| Model Mesh | Runtime Images | N/A | N/A | N/A | Runtime images used as serving containers |

## Build and Release Process

### Image Build Pipeline

| Step | Tool | Purpose |
|------|------|---------|
| 1. Source Checkout | Git | Clone repository at specific branch/tag |
| 2. Build Base Images | Podman/Docker + Makefile | Build foundational images (base-ubi9-python-3.9) |
| 3. Build Framework Images | Podman/Docker + Makefile | Build layered images (jupyter-minimal, cuda, etc.) |
| 4. Run Tests | Pytest + Kubernetes | Deploy test pods and validate functionality |
| 5. Push Images | Podman/Docker | Push to quay.io/modh registry (RHOAI) |
| 6. Update Manifests | Kustomize | Update ImageStream digests in manifests |
| 7. Deploy ImageStreams | kubectl/oc | Apply ImageStreams to OpenShift cluster |

### Image Naming Convention

Format: `quay.io/modh/{image-name}@sha256:{digest}`

Examples:
- `quay.io/modh/odh-minimal-notebook-container@sha256:eed810f9...`
- `quay.io/modh/cuda-notebooks@sha256:d8295bcf...`
- `quay.io/modh/codeserver@sha256:4b6b563e...`

### Release Cadence

| Release Type | Frequency | Scope | Naming |
|-------------|-----------|-------|--------|
| Major Release | Twice per year | OS updates, Python version, major library updates | 2024a, 2024b, 2025a |
| Patch Release | Weekly | Security patches, minor version updates | 20240115, 20240122 |
| Support Lifecycle | 1 year minimum | Two major releases supported concurrently | N and N-1 versions |

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| e3bef34d1 | 2024-10-24 | Merge pull request #421 from atheo89/RHOAIENG-13467<br>- Deactivate Habana notebook from manifests and repository docs |
| d0b445946 | 2024-10-23 | Deactivate Habana notebook from manifests and repository docs |
| 63bf1029f | 2024-09-02 | Merge remote-tracking branch 'upstream/main' into rhoai-2.13 |
| 6be50fc31 | 2024-08-29 | Merge pull request #373 from red-hat-data-services/digest-updater-10620686351<br>- Update image commits and digests for release N and N-1 |
| 482eed142 | 2024-08-29 | Update image commits for release N-1 via digest-updater-10620686351 GitHub action |
| 5f025203e | 2024-08-29 | Update images for release N-1 via digest-updater-10620686351 GitHub action |
| e7536e120 | 2024-08-29 | Update image commits for release N via digest-updater-10620686351 GitHub action |
| f924dcd61 | 2024-08-29 | Update images for release N via digest-updater-10620686351 GitHub action |
| dcfa02e18 | 2024-08-29 | Merge pull request #369 from atheo89/update-kfp-downstream<br>- Update the kfp package version in image manifest to match the reality |
| f6988b759 | 2024-08-29 | Merge pull request #368 from atheo89/fix-runtime-updeter-workflow<br>- Update runtimes workflow to don't break when a file does not exists |
| 8d675686e | 2024-08-29 | Update the kfp package version in image manifest to match the reality |
| 242584b78 | 2024-08-29 | Update runtimes workflow to don't break when a file does not exists |
| 217444c74 | 2024-08-29 | Merge pull request #364 from harshad16/rsync-main<br>- Sync with upstream main branch |
| c614d8f25 | 2024-08-28 | Fix the ci build issue with ci/ci/generate_code.sh |
| 49cf17343 | 2024-08-28 | Merge branch 'main' of opendatahub-io/notebooks into rsync-main |
| d7e0dc561 | 2024-08-27 | Merge remote-tracking branch 'upstream/main' into rhoai-2.13 |
| 5923bd648 | 2024-08-26 | Update image digest and runtime gh actions to include the new rocm images |
| 244d1860e | 2024-08-22 | Merge pull request #680 from paulovmr/RHOAIENG-11090<br>- Create a script to automate multiple library upgrades |
| 3eb1bf996 | 2024-08-22 | Create a script to automate multiple library upgrades |
| f04b97838 | 2024-08-22 | Merge pull request #685 from harshad16/fix-branding<br>- Fix branding issues |

## Image Variants

### Jupyter Images

| Image | Base | Python | Key Packages | Hardware | Use Case |
|-------|------|--------|--------------|----------|----------|
| jupyter-minimal | UBI9 | 3.9, 3.11 | JupyterLab 3.6.7, basic notebook tools | CPU | Minimal notebook environment for testing |
| jupyter-datascience | jupyter-minimal | 3.9, 3.11 | pandas, numpy, scikit-learn, matplotlib, boto3, Elyra, DB connectors | CPU | General data science and ML development |
| jupyter-pytorch | cuda/rocm | 3.9, 3.11 | PyTorch, CUDA/ROCm libraries | NVIDIA/AMD GPU | Deep learning with PyTorch |
| jupyter-tensorflow | cuda/rocm | 3.9, 3.11 | TensorFlow, CUDA/ROCm libraries | NVIDIA/AMD GPU | Deep learning with TensorFlow |
| jupyter-trustyai | jupyter-datascience | 3.9, 3.11 | TrustyAI explainability libraries | CPU | AI fairness and explainability analysis |
| jupyter-habana | habana | 3.8 | Habana Gaudi SDK, PyTorch/TensorFlow | Intel Habana Gaudi | Deep learning on Intel Habana accelerators |
| jupyter-intel-ml | intel | 3.9, 3.11 | Intel oneAPI, TensorFlow/PyTorch optimized for Intel | Intel GPU | ML workloads on Intel GPUs |

### CodeServer Images

| Image | Base | Python | Key Packages | Hardware | Use Case |
|-------|------|--------|--------------|----------|----------|
| codeserver | base | 3.9, 3.11 | code-server 4.22.0, NGINX, Python extensions, oc client | CPU | VS Code in browser for Python development |

### RStudio Images

| Image | Base | R Version | Python | Key Packages | Hardware | Use Case |
|-------|------|-----------|--------|--------------|----------|----------|
| rstudio | base | 4.3.3 | 3.9, 3.11 | RStudio Server, tidyverse, tidymodels, plumber, vetiver, NGINX | CPU | R-based data analysis and model development |
| cuda-rstudio | cuda | 4.3.3 | 3.9, 3.11 | RStudio Server, CUDA libraries, tidyverse | NVIDIA GPU | GPU-accelerated R workloads |

### Runtime Images (Model Serving)

| Image | Base | Python | Key Packages | Hardware | Use Case |
|-------|------|--------|--------------|----------|----------|
| runtime-minimal | base | 3.9, 3.11 | Minimal Python, curl | CPU | Lightweight serving container for simple models |
| runtime-datascience | base | 3.9, 3.11 | pandas, numpy, scikit-learn | CPU | Serving scikit-learn and traditional ML models |
| runtime-pytorch | base | 3.9, 3.11 | PyTorch (CPU) | CPU | Serving PyTorch models without GPU |
| runtime-tensorflow | base | 3.9, 3.11 | TensorFlow (CPU) | CPU | Serving TensorFlow models without GPU |
| runtime-rocm-pytorch | rocm | 3.9, 3.11 | PyTorch, ROCm | AMD GPU | Serving PyTorch models on AMD GPUs |
| runtime-rocm-tensorflow | rocm | 3.9, 3.11 | TensorFlow, ROCm | AMD GPU | Serving TensorFlow models on AMD GPUs |

## Known Limitations

1. **JupyterLab Version**: Images are pinned to JupyterLab 3.6.x due to extension compatibility. Upgrade to JupyterLab 4.x blocked until critical extensions (Elyra, jupyter-server-proxy) support it.

2. **NGINX Overhead**: CodeServer and RStudio images require NGINX proxy layer for health checks, adding memory overhead (~50MB) and complexity. This is necessary because the ODH notebook controller expects Jupyter-compatible `/api/kernels` endpoint for culling.

3. **No mTLS**: Workbench containers expose plain HTTP on localhost, relying entirely on oauth-proxy sidecar for authentication. No mutual TLS between sidecar and workbench container.

4. **Python Version Constraints**: UBI9 base images limit Python versions to what's available in Red Hat repos. Cannot easily add Python 3.12+ without custom builds.

5. **GPU Driver Management**: CUDA/ROCm images include GPU libraries but not kernel drivers. Host nodes must have GPU drivers pre-installed via Node Feature Discovery (NFD) and GPU Operator.

6. **Storage Performance**: Workbench pods use ReadWriteOnce PVCs which can cause performance issues with large datasets. No built-in support for parallel filesystems or distributed storage.

7. **Memory Limits**: Large ML frameworks (PyTorch + CUDA) can require 4-8GB base memory before user workload. Default resource requests may be insufficient for GPU images.

8. **Habana Support Deprecated**: As of rhoai-2.13, Habana notebook images are deactivated from manifests but still present in repository for backward compatibility.

## Troubleshooting

### Common Issues

| Issue | Symptom | Root Cause | Solution |
|-------|---------|------------|----------|
| Workbench pod crash-loops | Pod Status: CrashLoopBackOff | Insufficient memory for GPU libraries | Increase memory request to 8Gi for CUDA/ROCm images |
| pip install fails | ModuleNotFoundError after pip install | Missing group write permissions | Run `chmod -R g+w /opt/app-root/lib/python*/site-packages` |
| CodeServer health check fails | Pod Status: Not Ready | NGINX not started or misconfigured | Check supervisord logs: `cat /var/log/supervisor/*` |
| Cannot access S3 data | boto3.exceptions.NoCredentialsError | Missing or incorrectly mounted secret | Verify AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars |
| GPU not detected | PyTorch/TensorFlow reports no GPU | Wrong node selector or missing GPU drivers | Verify node has `nvidia.com/gpu` resource and GPU operator running |
| Elyra pipeline submit fails | 401 Unauthorized from KFP | Invalid or expired ServiceAccount token | Restart workbench pod to refresh SA token |
| Out of disk space | OSError: No space left on device | PVC full from large datasets/checkpoints | Increase PVC size or clean up old files in ~/work directory |

## Metrics and Observability

Workbench images do not expose Prometheus metrics directly. Observability is provided by:

1. **Container Logs**: stdout/stderr captured by OpenShift logging
2. **Health Checks**: HTTP liveness/readiness probes on `/api/kernels` or `/api`
3. **Activity Tracking**: NGINX access logs in JSON format for notebook culling
4. **Resource Usage**: jupyter-resource-usage extension shows CPU/memory in JupyterLab UI

**Key Log Locations**:
- Jupyter: stdout from `jupyter lab` process
- CodeServer: `/var/log/nginx/codeserver.access.log` (JSON), stdout from code-server
- RStudio: `/var/log/nginx/rstudio.access.log` (JSON), RStudio Server logs
- NGINX: `/var/log/nginx/access.log`, `/var/log/nginx/error.log`

## Configuration

### Environment Variables

| Variable | Default | Purpose | Images |
|----------|---------|---------|--------|
| NOTEBOOK_PORT | 8888 | Port for Jupyter server | Jupyter |
| NOTEBOOK_BASE_URL | / | Base URL path for Jupyter | Jupyter |
| NOTEBOOK_ROOT_DIR | $HOME | Root directory for Jupyter | Jupyter |
| NOTEBOOK_ARGS | "" | Additional arguments for `jupyter lab` | Jupyter |
| NB_PREFIX | "" | Notebook prefix path from JupyterHub | All |
| AWS_ACCESS_KEY_ID | - | AWS credentials for S3 access | All (if using boto3) |
| AWS_SECRET_ACCESS_KEY | - | AWS credentials for S3 access | All (if using boto3) |
| GIT_COMMITTER_NAME | - | Git user name for commits | All (if using git) |
| GIT_COMMITTER_EMAIL | - | Git user email for commits | All (if using git) |

### Volume Mounts

| Path | Purpose | Type | Required |
|------|---------|------|----------|
| /opt/app-root/src | User workspace and notebooks | PVC | Yes |
| /opt/app-root/src/.local | User-installed Python packages and configs | PVC | Yes (shared with workspace) |
| /etc/ssl/certs/ca-bundle.crt | Custom CA certificates | ConfigMap | No |
| /run/secrets/kubernetes.io/serviceaccount | ServiceAccount token for K8s API | Secret (auto-mounted) | Yes |

## Performance Tuning

### Resource Recommendations

| Image Type | CPU Request | CPU Limit | Memory Request | Memory Limit | GPU |
|------------|-------------|-----------|----------------|--------------|-----|
| jupyter-minimal | 1 core | 2 cores | 2Gi | 4Gi | 0 |
| jupyter-datascience | 1 core | 4 cores | 4Gi | 8Gi | 0 |
| jupyter-pytorch (CPU) | 2 cores | 8 cores | 8Gi | 16Gi | 0 |
| jupyter-pytorch (GPU) | 4 cores | 16 cores | 16Gi | 32Gi | 1 |
| jupyter-tensorflow (GPU) | 4 cores | 16 cores | 16Gi | 32Gi | 1 |
| codeserver | 1 core | 2 cores | 2Gi | 4Gi | 0 |
| rstudio | 2 cores | 4 cores | 4Gi | 8Gi | 0 |
| runtime-minimal | 0.5 cores | 1 core | 512Mi | 1Gi | 0 |
| runtime-pytorch | 1 core | 4 cores | 2Gi | 4Gi | 0 |

### Storage Performance

- **Minimum PVC size**: 10Gi for basic workloads, 50Gi for ML workloads with datasets
- **Recommended storage class**: Fast SSD-backed storage (e.g., gp3 on AWS, Premium SSD on Azure)
- **Access mode**: ReadWriteOnce (workbench pods are not replicated)
- **Dataset optimization**: Use object storage (S3) for large datasets instead of PVC

### Network Performance

- **Egress bandwidth**: Ensure cluster has sufficient egress for downloading packages (PyPI can be 100+ MB for ML packages)
- **Image pull time**: CUDA images are 5-10GB; use image pre-pulling or registry mirrors for faster startup
- **WebSocket timeout**: Ensure Route timeout is set to at least 3600s for long-running notebook kernels

## Security Considerations

1. **User Workload Isolation**: Workbench pods run as non-root user (UID 1001) with arbitrary UIDs supported for OpenShift SCC compliance.

2. **No Privilege Escalation**: Containers do not require privileged mode or host access, even for GPU workloads (GPU access via device plugin).

3. **Secrets Management**: Never bake credentials into images. Mount secrets as environment variables or files at runtime.

4. **Supply Chain Security**: Images built from Red Hat UBI base with signed packages. SBOM available via container scanning tools.

5. **CVE Patching**: Weekly image rebuilds incorporate OS and Python package security updates. Users should upgrade to latest patch release.

6. **Network Segmentation**: Consider NetworkPolicies to restrict egress to only required destinations (PyPI, S3, internal services).

7. **Code Execution Risk**: Users have full Python execution within their workbench. Use Pod Security Standards and resource limits to mitigate malicious/runaway code.

8. **Data Exfiltration**: Workbenches have egress to internet by default. Monitor network traffic or restrict egress for sensitive environments.

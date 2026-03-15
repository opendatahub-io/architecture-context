# Component: Notebook Images

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v1.1.1-312-gd01ea509b
- **Branch**: rhoai-2.6
- **Distribution**: RHOAI
- **Languages**: Python, Shell, Dockerfile
- **Deployment Type**: Container Images (ImageStreams)

## Purpose
**Short**: Pre-built container images for Jupyter notebooks and IDE environments optimized for data science and machine learning workloads.

**Detailed**: This component provides a comprehensive collection of container images that serve as interactive development environments for data scientists and ML engineers in RHOAI. The images are built in a layered architecture starting from Red Hat Universal Base Images (UBI) and include various configurations: minimal Jupyter notebooks, data science stacks with pre-installed ML libraries (scikit-learn, pandas, matplotlib), GPU-accelerated variants with CUDA and cuDNN, framework-specific images (PyTorch, TensorFlow), specialized images for TrustyAI and Habana AI accelerators, and alternative IDEs like code-server (VS Code) and RStudio. These images are consumed by the RHOAI Notebook Controller which spawns them as StatefulSets in user namespaces. The repository also provides runtime-only variants (without Jupyter) for executing notebook code in Data Science Pipelines via Elyra/Kubeflow integration.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Base Images | Container Images | Foundation images with Python 3.8/3.9 and base dependencies on UBI8/UBI9/C9S |
| Jupyter Minimal | Container Image | Lightweight JupyterLab 3.x environment with minimal dependencies |
| Jupyter Data Science | Container Image | Full-featured notebook with ML libraries, database clients, Elyra for pipelines |
| Jupyter PyTorch | Container Image | Data science base + PyTorch framework |
| Jupyter TensorFlow | Container Image | Data science base + TensorFlow framework |
| Jupyter TrustyAI | Container Image | Data science base + TrustyAI explainability libraries |
| CUDA Base | Container Image | Base image + NVIDIA CUDA 11.8, cuDNN 8.9 for GPU acceleration |
| CUDA Jupyter Variants | Container Images | GPU-accelerated versions of minimal/datascience/pytorch/tensorflow |
| Habana Jupyter | Container Images | Data science notebooks with Habana AI accelerator support (versions 1.9.0, 1.10.0, 1.11.0) |
| Runtime Images | Container Images | Python environments without Jupyter for pipeline step execution |
| Code-server | Container Image | VS Code IDE in browser with Python 3.9 and NGINX proxy |
| RStudio | Container Image | RStudio Server IDE for R programming |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It provides container images that are referenced by ImageStream resources and consumed by the Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None | Token/Cookie | Jupyter Server REST API |
| /notebook/{namespace}/{username}/lab | GET | 8888/TCP | HTTP | None | Token/Cookie | JupyterLab UI |
| /notebook/{namespace}/{username}/tree | GET | 8888/TCP | HTTP | None | Token/Cookie | Jupyter file browser |
| /api | GET | 8080/TCP | HTTP | None | None | Code-server readiness probe (NGINX) |
| / | GET | 8080/TCP | HTTP | None | Password | Code-server IDE interface |

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI8 Python 3.8 | registry.access.redhat.com/ubi8/python-38 | Yes | Base container image for Python 3.8 variants |
| UBI9 Python 3.9 | registry.access.redhat.com/ubi9/python-39 | Yes | Base container image for Python 3.9 variants |
| CentOS Stream 9 Python 3.9 | quay.io/centos/python-39 | No | Alternative base for code-server and RStudio |
| NVIDIA CUDA | 11.8.0 | No | GPU acceleration libraries for CUDA variants |
| NVIDIA cuDNN | 8.9.0 | No | Deep learning primitives for GPU acceleration |
| JupyterLab | 3.2-3.6 | Yes | Interactive notebook interface |
| Elyra | 3.15 | No | Visual pipeline editor for Data Science Pipelines |
| code-server | 4.16.1 | No | VS Code in browser |
| NGINX | 1.22 | No | Reverse proxy for code-server health checks |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| Notebook Controller | Spawner | Launches these images as StatefulSets when users create workbenches |
| Data Science Pipelines | Runtime Execution | Executes runtime images as Tekton pipeline steps via Elyra |
| OpenShift ImageStreams | Image Distribution | Distributes versioned images to user namespaces |
| Dashboard | Image Selection | Displays available notebook images for user selection |
| Model Registry | Integration | Data science notebooks can register models to model registry |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | notebook-port (8888) | HTTP | None | Token/Cookie | Internal |

**Note**: The notebook service is created per-workbench by the Notebook Controller. Encryption and authentication are typically enforced by OpenShift Route or Istio VirtualService that fronts this service.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-{namespace}-{username} | OpenShift Route or Istio VirtualService | {cluster-domain} | 443/TCP | HTTPS | TLS 1.2+ | Edge/Passthrough | External |

**Note**: Ingress is managed by the Notebook Controller or Service Mesh operator, not by this component.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io/modh/* | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Container image pulls |
| PyPI (pypi.org) | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation at runtime |
| Data Science Pipeline API | 8888/TCP | HTTP | mTLS (if Service Mesh) | Bearer Token | Elyra pipeline submission |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 | Data access via boto3 |
| MongoDB | 27017/TCP | MongoDB Protocol | TLS optional | Username/Password | Database connectivity (if configured) |
| PostgreSQL | 5432/TCP | PostgreSQL Protocol | TLS optional | Username/Password | Database connectivity (if configured) |
| MSSQL | 1433/TCP | TDS Protocol | TLS optional | Username/Password | Database connectivity (if configured) |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. The Notebook Controller manages RBAC for spawned notebook pods.

### RBAC - Role Bindings

This component does not define RoleBindings. User permissions are managed by the Notebook Controller.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {workbench}-notebook-token | Opaque | Jupyter authentication token | Notebook Controller | No |
| aws-connection-{name} | Opaque | S3 credentials for data access | User/Dashboard | No |
| generic-s3-secret | Opaque | Default S3 storage credentials | User/Dashboard | No |

**Note**: Secrets are mounted into notebook pods at runtime by the Notebook Controller.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | GET, POST, PUT, DELETE, PATCH | Bearer Token (JWT from OAuth), Session Cookie | OpenShift OAuth Proxy or Istio AuthorizationPolicy | User must own workbench or have namespace edit permissions |
| /api (Jupyter REST API) | GET, POST, DELETE | Token parameter or Authorization header | JupyterLab | Token match or empty token (if disabled) |

### Container Security

| Feature | Configuration | Purpose |
|---------|---------------|---------|
| User | UID 1001, GID 0 | Non-root execution, OpenShift SCC compatibility |
| Read-only Root Filesystem | No | Jupyter requires writable /opt/app-root for pip installs |
| Capabilities | Default (no special caps) | Minimal privileges |
| SELinux | container_t | OpenShift default SELinux context |

## Data Flows

### Flow 1: User Accesses Jupyter Notebook

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router/Istio Gateway | 443/TCP | HTTPS | TLS 1.2+ | OAuth Bearer Token |
| 2 | OpenShift Router/Istio Gateway | OAuth Proxy (if used) | 8888/TCP | HTTP | None (pod network) | Bearer Token validation |
| 3 | OAuth Proxy | Notebook Service (ClusterIP) | 8888/TCP | HTTP | mTLS (if Service Mesh) | Session Cookie |
| 4 | Notebook Service | Notebook Pod (StatefulSet) | 8888/TCP | HTTP | None (pod network) | Jupyter Token/Cookie |

### Flow 2: Notebook Accesses S3 Storage

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod | S3 Endpoint (AWS or MinIO) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 (from mounted secret) |

### Flow 3: Elyra Submits Pipeline to Data Science Pipelines

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Notebook Pod (Elyra) | Data Science Pipeline API | 8888/TCP | HTTP | mTLS (if Service Mesh) | Bearer Token (from ServiceAccount) |
| 2 | Data Science Pipeline API | Tekton Pipeline Controller | 8080/TCP | HTTP | mTLS (if Service Mesh) | ServiceAccount Token |
| 3 | Tekton PipelineRun | Pulls Runtime Image | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 4 | Runtime Image Execution | S3 Storage (input/output) | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature v4 |

### Flow 4: Image Build and Distribution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Build System (Konflux) | Quay.io Registry | 443/TCP | HTTPS | TLS 1.2+ | Robot Account Token |
| 2 | ImageStream Import | Quay.io Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 3 | Kubelet (Image Pull) | Internal Registry or Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| Notebook Controller | Kubernetes API (StatefulSet creation) | 6443/TCP | HTTPS | TLS 1.2+ | Spawns notebook pods from these images |
| Data Science Pipelines | Container Execution | N/A | N/A | N/A | Executes runtime images in Tekton pipeline steps |
| Dashboard | Image Metadata (ImageStream annotations) | 6443/TCP | HTTPS | TLS 1.2+ | Displays available notebook types and versions |
| Model Registry | HTTP REST API | 8080/TCP | HTTP | mTLS (if Service Mesh) | Registers trained models from notebooks |
| OpenShift Image Registry | Container Image Pull | 443/TCP or 5000/TCP | HTTPS | TLS 1.2+ | Pulls images for pod creation |

## Image Variants and Layering

### Python 3.8 (UBI8-based)

```
ubi8/python-38
  └─ base-ubi8-python-3.8
      ├─ jupyter-minimal-ubi8-python-3.8
      │   └─ jupyter-datascience-ubi8-python-3.8
      │       ├─ jupyter-trustyai-ubi8-python-3.8
      │       ├─ habana-jupyter-1.9.0-ubi8-python-3.8
      │       ├─ habana-jupyter-1.10.0-ubi8-python-3.8
      │       └─ habana-jupyter-1.11.0-ubi8-python-3.8
      ├─ cuda-ubi8-python-3.8
      │   └─ cuda-jupyter-minimal-ubi8-python-3.8
      │       └─ cuda-jupyter-datascience-ubi8-python-3.8
      │           ├─ cuda-jupyter-pytorch-ubi8-python-3.8
      │           └─ cuda-jupyter-tensorflow-ubi8-python-3.8
      ├─ runtime-minimal-ubi8-python-3.8
      ├─ runtime-datascience-ubi8-python-3.8
      └─ runtime-pytorch-ubi8-python-3.8
```

### Python 3.9 (UBI9-based)

```
ubi9/python-39
  └─ base-ubi9-python-3.9
      ├─ jupyter-minimal-ubi9-python-3.9
      │   └─ jupyter-datascience-ubi9-python-3.9
      │       ├─ jupyter-pytorch-ubi9-python-3.9
      │       ├─ jupyter-tensorflow-ubi9-python-3.9
      │       └─ jupyter-trustyai-ubi9-python-3.9
      ├─ cuda-ubi9-python-3.9
      │   └─ cuda-jupyter-minimal-ubi9-python-3.9
      │       └─ cuda-jupyter-datascience-ubi9-python-3.9
      │           ├─ cuda-jupyter-pytorch-ubi9-python-3.9
      │           └─ cuda-jupyter-tensorflow-ubi9-python-3.9
      ├─ runtime-minimal-ubi9-python-3.9
      ├─ runtime-datascience-ubi9-python-3.9
      ├─ runtime-pytorch-ubi9-python-3.9
      └─ cuda-runtime-tensorflow-ubi9-python-3.9
```

### Python 3.9 (C9S-based - IDEs)

```
centos/python-39
  └─ c9s-python-3.9
      ├─ code-server-c9s-python-3.9 (VS Code)
      └─ r-studio-c9s-python-3.9 (RStudio)
```

## Installed Software by Image Type

### Base Images
- Python 3.8 or 3.9
- pip, micropipenv
- OpenShift CLI (oc)
- mesa-libGL

### Jupyter Minimal
- Base + JupyterLab 3.2-3.6
- Jupyter Notebook 6.4-6.5
- IPython kernel

### Jupyter Data Science
- Jupyter Minimal +
- **ML Libraries**: scikit-learn, pandas, numpy, scipy, matplotlib
- **Data Access**: boto3 (S3), kafka-python, pymongo, pyodbc, psycopg (PostgreSQL), mysql-connector-python
- **Pipelines**: Elyra 3.15, kfp-tekton 1.5
- **SDK**: codeflare-sdk 0.12
- **Database CLIs**: mongocli, mssql-tools18
- **Tools**: jq, git-lfs, unixODBC, libsndfile

### CUDA Images
- Data Science base +
- NVIDIA CUDA 11.8.0
- cuDNN 8.9.0
- NCCL 2.15.5
- CUDA development tools

### Framework-Specific (PyTorch/TensorFlow)
- Data Science or CUDA Data Science base +
- Framework-specific libraries (PyTorch or TensorFlow with GPU support)

### Code-server
- C9S Python 3.9 base +
- code-server 4.16.1
- NGINX 1.22 (reverse proxy)
- OpenShift CLI (oc)

### Runtime Images
- Base image +
- Framework libraries (minimal/datascience/pytorch/tensorflow)
- **No Jupyter** - optimized for pipeline execution

## Deployment Manifests

### ImageStream Resources (manifests/base/)

| ImageStream | Display Name | Image Registry | Versions |
|-------------|--------------|----------------|----------|
| s2i-minimal-notebook | Minimal Python | quay.io/modh/odh-minimal-notebook-container | 2023.2, 2023.1, 1.2 (N, N-1, N-2) |
| s2i-generic-data-science-notebook | Standard Data Science | quay.io/modh/odh-generic-data-science-notebook | 2023.2, 2023.1, 1.2 |
| s2i-minimal-gpu-notebook | CUDA | quay.io/modh/cuda-notebooks | 2023.2, 2023.1, 1.2 |
| s2i-pytorch-gpu-notebook | PyTorch | quay.io/modh/odh-pytorch-notebook | 2023.2, 2023.1, 1.2 |
| s2i-tensorflow-gpu-notebook | TensorFlow | quay.io/modh/cuda-notebooks | 2023.2, 2023.1, 1.2 |
| s2i-trustyai-notebook | TrustyAI | quay.io/modh/odh-trustyai-notebook | 2023.2, 2023.1 |
| s2i-habana-notebook | HabanaAI | quay.io/modh/odh-habana-notebooks | 2023.2 (latest) |
| code-server-notebook | code-server | quay.io/modh/codeserver | 2023.2 |

### Kustomize Structure

```
manifests/
├─ base/
│  ├─ kustomization.yaml          # Main kustomize file
│  ├─ params.env                   # Image references (SHA256 digests)
│  ├─ commit.env                   # Build commit hashes
│  └─ *-imagestream.yaml           # ImageStream definitions
└─ overlays/
   └─ additional/
      └─ kustomization.yaml        # Additional overlays
```

## Build and Release Process

### Build Process
1. **Source**: Dockerfiles organized by variant (base, jupyter, cuda, habana, runtimes, codeserver, rstudio)
2. **Dependencies**: Pipfile.lock for Python package pinning (reproducible builds)
3. **Build Tool**: Konflux CI/CD (for RHOAI), Makefile for local builds
4. **Registry**: quay.io/modh/* (RHOAI managed registry)
5. **Layered Builds**: Images build on top of each other (base → minimal → datascience → framework)

### Versioning
- **Image Tags**: Release-based (2023.2, 2023.1, 1.2 representing N, N-1, N-2)
- **Git Tags**: v1.1.1-312-gd01ea509b
- **Digest-based References**: params.env uses SHA256 digests for immutable references

### Distribution
1. Images built by Konflux and pushed to quay.io/modh
2. ImageStream manifests deployed by opendatahub-operator or RHOAI operator
3. ImageStream imports images into OpenShift internal registry (optional)
4. Notebook Controller references ImageStream tags when spawning workbenches

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| d01ea509b | 2024 | Merge pull request #120 from red-hat-data-services/release-2023b |
| 0c19110b3 | 2024 | Merge pull request #122 from harshad16/fix-typo |
| 85b648c89 | 2024 | HotFix: Fix the typo and keep code-server case-sensitive |
| 9bb914047 | 2024 | Merge pull request #121 from red-hat-data-services/digest-updater-7647215869 |
| 538e1f5e5 | 2024 | Update image commits for release N via digest-updater-7647215869 GitHub action |
| 22b641f29 | 2024 | Update image commits for release N via digest-updater-7647215869 GitHub action |
| bb8bd701d | 2024 | Update images for release N via digest-updater-7647215869 GitHub action |
| ef31e06f6 | 2024 | Merge pull request #119 from harshad16/rsync-2023b |
| 335b18dbf | 2024 | Merge branch '2023b' of https://github.com/opendatahub-io/notebooks into rsync-2023b |
| b8bdaccaa | 2024 | Merge pull request #391 from harshad16/sync-2023b |
| 2fb84db71 | 2024 | Fix: Use code-server reference in all the files |
| 89f54c8cb | 2024 | Use Titlecase for annotation naming |
| a643e4b66 | 2024 | [Fix] of typo of the code-server package in the relevant manifest |
| 099365ded | 2024 | Fix: update the typo of ubi9 on trusty ai notebook and lint fixing |
| 3ca215cab | 2024 | Update the pipfile.lock via the weekly workflow action |
| 2a7a7733f | 2024 | Merge pull request #117 from red-hat-data-services/release-2023b |
| 357e2f375 | 2024 | Merge pull request #115 from atheo89/update-vscode-sha-release |
| 0288d9549 | 2024 | Fix: Code Server notebook sha digest on the params.env file (rhoai-2.6) |
| b826d7c41 | 2024 | Update the pipfile.lock via the weekly workflow action |
| 0e26442e4 | 2024 | Merge pull request #111 from red-hat-data-services/digest-updater-7507558242 |

**Recent Activity Summary**:
- Automated image digest updates for release 2023b (release N)
- Code-server naming fixes and consistency improvements
- Weekly Pipfile.lock updates for security patches
- Synchronization between opendatahub-io upstream and red-hat-data-services RHOAI fork
- TrustyAI notebook UBI9 migration fixes

## Configuration Options

### Environment Variables (Notebook Runtime)

| Variable | Default | Purpose |
|----------|---------|---------|
| NOTEBOOK_PORT | 8888 | JupyterLab server port |
| NOTEBOOK_BASE_URL | / | Base URL path for Jupyter |
| NOTEBOOK_ROOT_DIR | $HOME | Jupyter working directory |
| NOTEBOOK_ARGS | (empty) | Additional Jupyter server arguments |
| NVIDIA_VISIBLE_DEVICES | all | GPU device visibility (CUDA images) |
| NVIDIA_DRIVER_CAPABILITIES | compute,utility | GPU capabilities (CUDA images) |

### Jupyter Server Configuration

- **Token Authentication**: Controlled via ServerApp.token (disabled in managed environments with OAuth)
- **Password Authentication**: Controlled via ServerApp.password (disabled in RHOAI)
- **CORS**: ServerApp.allow_origin="*" for OAuth proxy compatibility
- **Quit Button**: Disabled (ServerApp.quit_button=False) to prevent accidental shutdown

## Testing

### Test Structure
- **Location**: Each image variant has a `test/` directory
- **Framework**: Kubernetes-based end-to-end tests
- **CI**: OpenShift CI (Prow) runs tests on PRs

### Test Targets (Makefile)
- `deployX-{NOTEBOOK_NAME}`: Deploy notebook to test cluster (X=8 for UBI8, X=9 for UBI9)
- `test-{NOTEBOOK_NAME}`: Run test suite against deployed notebook
- `undeployX-{NOTEBOOK_NAME}`: Clean up test deployment
- `validate-runtime-image`: Verify runtime image has curl and python3

## Operational Considerations

### Resource Requirements (Default)
- **CPU**: 500m requests/limits
- **Memory**: 2Gi requests/limits
- **Storage**: Ephemeral (unless PVC mounted by Notebook Controller)

### Startup Time
- **Minimal**: ~10-20 seconds
- **Data Science**: ~20-30 seconds
- **CUDA**: ~30-60 seconds (GPU allocation + library loading)

### Health Checks
- **Liveness**: TCP socket probe on port 8888 (5s initial delay, 5s period)
- **Readiness**: HTTP GET /notebook/{namespace}/{username}/api (10s initial delay, 5s period)

### Logging
- **JupyterLab Logs**: stdout/stderr captured by OpenShift (accessible via `oc logs`)
- **NGINX Logs** (code-server): /var/log/nginx (ephemeral)

### Troubleshooting

| Issue | Symptoms | Resolution |
|-------|----------|------------|
| Image Pull Failure | Pod stuck in ImagePullBackOff | Verify ImageStream import, check pull secrets |
| Startup Timeout | Pod fails readiness probe | Check resource limits, GPU availability (CUDA), view logs |
| Permission Denied | Cannot write to filesystem | Verify SCC, PVC permissions (must be GID 0 or 1001) |
| Missing Python Package | ImportError at runtime | Install via `pip install --user` or request image update |
| GPU Not Detected | PyTorch/TF can't find GPU | Verify node has GPU, NVIDIA device plugin running, limits set |

## Future Enhancements

Based on recent commit patterns and RHOAI roadmap:

1. **Python 3.11**: Migration to newer Python version for performance and features
2. **JupyterLab 4.x**: Upgrade to latest JupyterLab major version
3. **ARM64 Support**: Multi-arch builds for ARM-based nodes
4. **Air-gapped Improvements**: Better support for disconnected environments
5. **Custom Package Injection**: Mechanisms to add custom packages without rebuilding images
6. **Enhanced GPU Support**: AMD ROCm, Intel oneAPI support beyond NVIDIA CUDA

## Related Documentation

- **README.md**: User-facing documentation for building and testing images
- **CONTRIBUTING.md**: Guidelines for adding new notebook variants
- **Upstream**: https://github.com/opendatahub-io/notebooks (ODH community version)

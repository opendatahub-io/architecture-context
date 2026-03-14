# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v20xx.2-1184-gead872594
- **Branch**: rhoai-3.3
- **Distribution**: RHOAI, ODH
- **Languages**: Python 3.12/3.14, Shell, Dockerfile
- **Deployment Type**: Container Images / User Workbenches

## Purpose
**Short**: Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data scientists to develop, train, and experiment with machine learning models.

**Detailed**: The Notebooks component is a collection of pre-built container images that serve as interactive development environments for data science workloads. These workbench images are launched by users through the RHOAI/ODH dashboard and provide integrated tooling for Python, R, and machine learning frameworks. The component includes Jupyter notebooks with various ML frameworks (PyTorch, TensorFlow), RStudio for R development, CodeServer (VS Code in browser), and lightweight runtime images for Elyra pipeline execution. Images are optimized for different hardware accelerators (CPU, NVIDIA CUDA, AMD ROCM) and include pre-installed libraries for data science workflows. These images are published as OpenShift ImageStreams, allowing users to select and launch workbenches dynamically.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Jupyter Minimal | Container Image | Lightweight Jupyter Lab environment with Python 3.12 and core libraries |
| Jupyter DataScience | Container Image | Jupyter Lab with expanded data science libraries (pandas, numpy, sklearn) |
| Jupyter PyTorch | Container Image | Jupyter Lab with PyTorch ML framework for CUDA/ROCM GPUs |
| Jupyter TensorFlow | Container Image | Jupyter Lab with TensorFlow ML framework for CUDA/ROCM GPUs |
| Jupyter TrustyAI | Container Image | Jupyter Lab with TrustyAI explainability and fairness tools |
| Jupyter PyTorch+LLMCompressor | Container Image | Jupyter Lab with PyTorch and LLM compression tools for model optimization |
| RStudio Workbench | Container Image | RStudio IDE for R development with CPU/CUDA support |
| CodeServer Workbench | Container Image | VS Code (code-server) IDE in browser with data science tools |
| Runtime Images | Container Image | Lightweight images for Elyra pipeline node execution (no IDE) |
| Base Images | Container Image Build Stage | Foundation images with CPU/CUDA/ROCM libraries for workbench builds |
| ImageStream Manifests | Kustomize Deployment | OpenShift ImageStream definitions referencing published images |

## APIs Exposed

### Custom Resource Definitions (CRDs)

**None** - This component provides container images only. Workbench deployment is managed by the ODH Notebook Controller operator, which creates standard Kubernetes resources (StatefulSet, Service, PVC).

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/{namespace}/{username}/ | GET, POST | 8888/TCP | HTTP | None (internal) | OAuth proxy (external) | JupyterLab web interface |
| /notebook/{namespace}/{username}/api | GET | 8888/TCP | HTTP | None (internal) | OAuth proxy (external) | Jupyter Server API for kernel management |
| /notebook/{namespace}/{username}/lab | GET | 8888/TCP | HTTP | None (internal) | OAuth proxy (external) | JupyterLab UI endpoint |
| /notebook/{namespace}/{username}/terminals/websocket | WebSocket | 8888/TCP | HTTP | None (internal) | OAuth proxy (external) | Terminal websocket for shell access |
| / | GET, POST | 8888/TCP | HTTP | None | None | RStudio/CodeServer web interface (port varies by IDE) |

**Note**: Workbenches run as user pods behind OAuth proxy sidecar. Direct access to port 8888 is internal only; external access is via HTTPS through OpenShift routes with OAuth authentication.

### gRPC Services

**None** - Workbenches expose HTTP-based Jupyter Server API only.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9 Python 3.12 | registry.access.redhat.com/ubi9/python-312 | Yes | Base OS and Python runtime |
| CUDA Base Images | CUDA 12.6/12.8/13.0 | No (GPU only) | NVIDIA GPU acceleration libraries |
| ROCM Base Images | ROCM 6.2/6.3/6.4 | No (AMD GPU only) | AMD GPU acceleration libraries |
| JupyterLab | 4.4 | Yes (Jupyter images) | Interactive notebook IDE |
| PyTorch | 2.x | No (PyTorch images) | Deep learning framework |
| TensorFlow | 2.x | No (TensorFlow images) | Deep learning framework |
| RStudio Server | Latest | Yes (RStudio images) | R IDE server |
| code-server | Latest | Yes (CodeServer images) | VS Code server for browser |
| OpenShift CLI (oc) | Stable | Yes | Kubernetes cluster management from workbench |
| Pandoc | Latest | Yes | Document format conversion (PDF export) |
| TeX Live | Latest | Yes | LaTeX rendering for notebook PDF export |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-notebook-controller | Creates workbench pods | Operator that deploys user workbenches using these images |
| odh-dashboard | Displays ImageStreams | UI for users to browse and launch workbench images |
| kubeflow-pipelines (Elyra) | Uses runtime images | Executes pipeline nodes in runtime containers |
| oauth-proxy | Sidecar container | Provides authentication for workbench access |
| Persistent Volume Claims | Volume mounts | Storage for user notebooks and data |
| OpenShift Routes | HTTP ingress | External access to workbench web interfaces |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {workbench-name}-notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | OAuth proxy enforced | Internal |

**Note**: Each user workbench creates its own Service named by the workbench instance. Services are ClusterIP and accessed via OpenShift Routes with oauth-proxy sidecar.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {workbench-name} | OpenShift Route | {workbench}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | edge | External |

**Note**: Routes are created by odh-notebook-controller when user launches workbench. TLS termination occurs at route level; internal traffic to pod is HTTP.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation at runtime |
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | None | Pulling container images |
| registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Red Hat subscription | Pulling RHEL base images |
| mirror.openshift.com | 443/TCP | HTTPS | TLS 1.2+ | None | Downloading OpenShift CLI (oc) |
| Kubernetes API Server | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token | kubectl/oc commands from workbench |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM / Access Keys | Data access from notebooks (user-configured) |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH keys / PAT | Cloning repositories from notebooks |

## Security

### RBAC - Cluster Roles

**None** - Workbench images do not define cluster-level RBAC. The odh-notebook-controller operator manages RBAC for workbench pods.

Workbench pods inherit service account permissions configured by the notebook controller, typically limited to:
- Read/write to namespace-scoped resources (ConfigMaps, Secrets within user namespace)
- Read access to ImageStreams for discovering available images
- No cluster-admin or cross-namespace permissions by default

### RBAC - Role Bindings

**None defined by this component** - RoleBindings are created by odh-notebook-controller when deploying user workbenches. Users cannot modify RBAC from within workbench containers.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {workbench}-oauth-config | Opaque | OAuth proxy configuration for workbench authentication | odh-notebook-controller | No |
| {workbench}-tls | kubernetes.io/tls | TLS certificate for HTTPS route (if using reencrypt) | OpenShift cert manager | Yes (90 days) |

**Note**: Users may create additional secrets for credentials (Git, S3, API tokens) mounted into workbench pods.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/{namespace}/{username}/* | GET, POST, WebSocket | OAuth proxy (OpenShift OAuth) | oauth-proxy sidecar | User must have namespace access |
| Jupyter Server API (/api) | GET, POST | Disabled (token='', password='') | Jupyter Server config | Relies on OAuth proxy for auth |

**Security Model**:
- External access requires OpenShift OAuth authentication (enforced by oauth-proxy sidecar)
- Jupyter Server authentication disabled (no token/password) - assumes OAuth proxy handles auth
- Users can only access workbenches in namespaces they have permissions for
- Workbenches run as non-root user (UID 1001)
- Security context constraints (SCC) limit container capabilities

## Data Flows

### Flow 1: User Accesses Workbench via Browser

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None (initial) |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ | OAuth redirect |
| 3 | OAuth Proxy | OpenShift OAuth Server | 6443/TCP | HTTPS | TLS 1.2+ | OAuth token exchange |
| 4 | OAuth Proxy | Jupyter Server (container) | 8888/TCP | HTTP | None | OAuth validated |
| 5 | Jupyter Server | User Browser (response) | 8888/TCP → 443/TCP | HTTP → HTTPS | None → TLS 1.2+ | Session cookie |

### Flow 2: Install Python Package from Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Jupyter Terminal (pod) | pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | pypi.org | Jupyter Container | 443/TCP → ephemeral | HTTPS | TLS 1.2+ | None |
| 3 | pip/uv installer | Workbench filesystem | N/A | Local FS | None | UID 1001 permissions |

### Flow 3: Run Elyra Pipeline Node (Runtime Image)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Elyra (Jupyter) | Kubeflow Pipelines API | 8888/TCP | HTTP | None | Bearer Token |
| 2 | Kubeflow Pipelines | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |
| 3 | Kubernetes | Runtime Image (pod) | N/A | N/A | N/A | Pod creation |
| 4 | Runtime Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS credentials from secret |

### Flow 4: Build Container Image (Konflux CI/CD)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Git commit | Konflux Tekton Pipelines | 443/TCP | HTTPS | TLS 1.2+ | GitHub webhook |
| 2 | Tekton Pipeline | Buildah (build pod) | N/A | N/A | N/A | Pipeline ServiceAccount |
| 3 | Buildah | registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull secret |
| 4 | Buildah | quay.io/opendatahub | 443/TCP | HTTPS | TLS 1.2+ | Push secret |
| 5 | Konflux | ImageStream (update) | 6443/TCP | HTTPS | TLS 1.2+ | Service Account Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| odh-notebook-controller | Kubernetes API (creates StatefulSet) | 6443/TCP | HTTPS | TLS 1.2+ | Deploys workbench pods using these images |
| odh-dashboard | Reads ImageStreams | 6443/TCP | HTTPS | TLS 1.2+ | Displays available workbench images to users |
| oauth-proxy | Sidecar container | 8888/TCP | HTTP | None | Protects workbench access with OpenShift OAuth |
| Kubeflow Pipelines | Launches runtime images | 6443/TCP | HTTPS | TLS 1.2+ | Executes Elyra pipeline nodes in runtime containers |
| Persistent Storage | Volume mounts | N/A | Local FS | None | Stores user notebooks and data |
| OpenShift Routes | HTTP routing | 443/TCP | HTTPS | TLS 1.2+ | Exposes workbenches externally |
| Konflux CI/CD | Builds and publishes images | 443/TCP | HTTPS | TLS 1.2+ | Automated image builds from Git commits |

## Build & Deployment Architecture

### Container Build Process

| Stage | Tool | Input | Output | Purpose |
|-------|------|-------|--------|---------|
| 1. Base Image | Dockerfile.konflux.{cpu\|cuda\|rocm} | UBI9 Python / CUDA / ROCM images | cpu-base / cuda-base / rocm-base | OS dependencies, accelerator libs |
| 2. Workbench Build | Dockerfile.konflux.{cpu\|cuda\|rocm} | Base image + pylock.toml | Workbench image | Install Python packages, IDE (Jupyter/RStudio/CodeServer) |
| 3. Konflux Pipeline | Tekton PipelineRun | Git commit | Multi-arch image (x86_64, aarch64, ppc64le, s390x) | Build, scan, sign, push to Quay |
| 4. ImageStream Update | kustomization.yaml | params.env (image digest) | Updated ImageStream tags | Make new image version discoverable |

### Deployment Process

| Stage | Component | Resource Created | Purpose |
|-------|-----------|------------------|---------|
| 1. User Action | odh-dashboard | Notebook CRD | User clicks "Create workbench" in dashboard |
| 2. Controller Reconcile | odh-notebook-controller | StatefulSet | Creates workbench pod with selected image |
| 3. Resource Creation | odh-notebook-controller | Service, Route, PVC, ConfigMaps, Secrets | Networking and storage for workbench |
| 4. Pod Start | Kubernetes Scheduler | Pod (with oauth-proxy + workbench containers) | Runs start-notebook.sh entrypoint |
| 5. Health Checks | Kubelet | HTTP/TCP probes | Validates Jupyter Server on port 8888 |
| 6. Route Active | OpenShift Router | External HTTPS access | User can access workbench via browser |

## Image Inventory

### Workbench Images (Jupyter)

| Image Name | Accelerator | Python | Frameworks | Published To |
|------------|-------------|--------|------------|--------------|
| odh-workbench-jupyter-minimal-cpu-py312-ubi9 | CPU | 3.12 | JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-minimal-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-minimal-rocm-py312-ubi9 | ROCM 6.3 | 3.12 | JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-datascience-cpu-py312-ubi9 | CPU | 3.12 | JupyterLab 4.4, pandas, sklearn | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | PyTorch, JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-rocm-py312-ubi9 | ROCM 6.3 | 3.12 | PyTorch (ROCM), JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-tensorflow-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | TensorFlow, JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-tensorflow-rocm-py312-ubi9 | ROCM 6.3 | 3.12 | TensorFlow (ROCM), JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-trustyai-cpu-py312-ubi9 | CPU | 3.12 | TrustyAI, JupyterLab 4.4 | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-llmcompressor-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | PyTorch, LLM Compressor | registry.redhat.io, quay.io/opendatahub |

### Workbench Images (Other IDEs)

| Image Name | Accelerator | IDE | Published To |
|------------|-------------|-----|--------------|
| odh-workbench-codeserver-datascience-cpu-py312-ubi9 | CPU | VS Code (code-server) | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-rstudio-minimal-cpu-py312-c9s | CPU | RStudio Server | registry.redhat.io, quay.io/opendatahub |
| odh-workbench-rstudio-minimal-cuda-py312-c9s | CUDA 12.8 | RStudio Server | registry.redhat.io, quay.io/opendatahub |

### Runtime Images (Elyra Pipelines)

| Image Name | Accelerator | Python | Frameworks | Published To |
|------------|-------------|--------|------------|--------------|
| odh-pipeline-runtime-minimal-cpu-py312-ubi9 | CPU | 3.12 | Core libraries | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-datascience-cpu-py312-ubi9 | CPU | 3.12 | pandas, sklearn | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | PyTorch | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-llmcompressor-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | PyTorch, LLM Compressor | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-tensorflow-cuda-py312-ubi9 | CUDA 12.8 | 3.12 | TensorFlow | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-rocm-py312-ubi9 | ROCM 6.3 | 3.12 | PyTorch (ROCM) | registry.redhat.io, quay.io/opendatahub |
| odh-pipeline-runtime-tensorflow-rocm-py312-ubi9 | ROCM 6.3 | 3.12 | TensorFlow (ROCM) | registry.redhat.io, quay.io/opendatahub |

**Note**: Images are multi-architecture (x86_64, aarch64, ppc64le, s390x where supported by accelerator vendor).

## Recent Changes

| Commit | Date | Changes |
|--------|------|---------|
| ead872594 | 2025-03-13 | - RHAIENG-2646: add loop to retry package installation when it fails |
| b801e5de0 | 2025-03-13 | - upgrade wheels package to fix cve-2026-24049 (#1899) |
| cc8d4d0e4 | 2025-03-13 | - sync pipelineruns with konflux-central - 9fd8f6f |
| ed9148427 | 2025-03-13 | - RHOAIENG-50338: fix(trusty): set constraint on setuptools for from-source builds (#1921) |
| a2a3d89a6 | 2025-03-13 | - sync pipelineruns with konflux-central - ae43974 |
| f162f6dd4 | 2025-03-12 | - Merge pull request #1835: Update Konflux references for rhoai-3.3 |
| b62255911 | 2025-03-12 | - Update Konflux references |
| 55700739e | 2025-03-12 | - sync pipelineruns with konflux-central - 5bc9547 |
| 74a97bf55 | 2025-03-12 | - sync pipelineruns with konflux-central - 073cb6c |
| f88354f54 | 2025-03-12 | - sync pipelineruns with konflux-central - 557e967 |
| 2a9b8c72c | 2025-03-11 | - Merge cherry-pick #1846 to rhoai-3.3 |
| e36fe53a1 | 2025-03-11 | - RHAIENG-2458: fix(ppc64le): update ONNX version to 1.20.1 (#1856) |
| e7a08fe9d | 2025-03-11 | - Add restart comment to Jupyter datasource YAML |
| 235c13eb9 | 2025-03-11 | - Add restart comment in YAML configuration |
| c602b7731 | 2025-03-11 | - Add restart comment to pipeline YAML |
| 0a6dd5ffb | 2025-03-11 | - Add git-auth secret to pipeline configuration |
| 47cac0909 | 2025-03-11 | - Add restart comment in pipeline YAML |
| 5b7054b13 | 2025-03-10 | - Add git-auth configuration updates |
| 7a9fafb9c | 2025-03-10 | - Add restart comment in pipeline YAML |

**Recent Themes**:
- Migration to Konflux CI/CD for automated builds
- Security updates (CVE fixes, dependency upgrades)
- Multi-architecture support improvements (ppc64le, aarch64)
- Integration with Konflux central pipeline definitions
- Bug fixes for package installation reliability

## Configuration

### Environment Variables (Workbench Pods)

| Variable | Default | Purpose |
|----------|---------|---------|
| NOTEBOOK_PORT | 8888 | Port for Jupyter Server to listen on |
| NOTEBOOK_BASE_URL | /notebook/{namespace}/{username} | Base URL path for Jupyter Server |
| NOTEBOOK_ROOT_DIR | ${HOME} | Root directory for notebook files |
| NOTEBOOK_ARGS | (server config) | Additional arguments passed to `jupyter lab` |
| PIP_INDEX_URL | https://pypi.org/simple | Python package index URL |
| UV_DEFAULT_INDEX | https://pypi.org/simple | UV package manager index URL |

### Build-time Configuration

| File | Purpose |
|------|---------|
| pylock.toml | Locked Python dependencies with hashes for reproducible builds |
| Dockerfile.konflux.{cpu\|cuda\|rocm} | Multi-stage build definition for workbench images |
| start-notebook.sh | Entrypoint script that starts Jupyter/RStudio/CodeServer |
| jupyter_server_config.py | Jupyter Server configuration (disables PDF exporters) |
| manifests/base/params.env | Image name to digest mappings for ImageStreams |
| .tekton/*.yaml | Konflux pipeline definitions for automated builds |

## Troubleshooting

### Common Issues

| Issue | Diagnosis | Resolution |
|-------|-----------|------------|
| Workbench pod stuck in ImagePullBackOff | Check image registry authentication | Verify pull secrets exist in namespace |
| Workbench crashes on startup | Check pod logs for startup errors | Verify NOTEBOOK_ARGS environment variable format |
| Cannot install packages from workbench | Check egress network policy | Ensure pypi.org access allowed |
| GPU not detected in CUDA/ROCM images | Verify node has GPU and drivers | Check node labels and tolerations |
| Workbench route returns 503 | Check pod readiness probe | Verify Jupyter Server started on port 8888 |

### Health Check Endpoints

| Endpoint | Type | Port | Success Criteria | Purpose |
|----------|------|------|------------------|---------|
| /notebook/{namespace}/{username}/api | HTTP GET | 8888/TCP | Status 200 | Readiness probe - Jupyter API responding |
| 8888 | TCP Socket | 8888/TCP | Connection accepted | Liveness probe - Port listening |

## Notes

- **No persistent services**: Workbench images are user-launched containers, not platform services. Each user can launch multiple workbenches.
- **Stateful workbenches**: Deployed as StatefulSets with PVCs to preserve user data across pod restarts.
- **OAuth proxy pattern**: External authentication handled by oauth-proxy sidecar; Jupyter Server auth disabled (token/password='').
- **Runtime vs Workbench images**: Runtime images are headless (no IDE) for Elyra pipeline execution; workbench images include full IDE.
- **Konflux builds**: All images built via Konflux pipelines (Tekton) with multi-arch support, security scanning, and image signing.
- **Image versioning**: ImageStreams maintain N-6 version history (7 versions) to support rollback and gradual adoption.
- **Base image strategy**: Shared base images (base-images/) reduce duplication; workbench images layer IDE and packages on top.
- **Accelerator support**: GPU images require nodes with NVIDIA/AMD GPUs and appropriate device plugins installed.
- **Package management**: Images use UV package manager for fast, reliable dependency resolution with hash verification.

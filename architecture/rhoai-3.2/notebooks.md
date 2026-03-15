# Component: Notebooks

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks.git
- **Version**: v3.2.0
- **Branch**: rhoai-3.2
- **Distribution**: RHOAI (with upstream OpenDataHub variant)
- **Languages**: Python, Shell (Bash), Dockerfile
- **Deployment Type**: Container Images (Workbenches and Runtimes)

## Purpose
**Short**: Provides pre-built container images for data science workbenches (Jupyter, RStudio, CodeServer) and pipeline runtimes used in RHOAI/ODH environments.

**Detailed**: This repository builds and maintains a comprehensive collection of data science workbench and runtime container images for the Red Hat OpenShift AI (RHOAI) and OpenDataHub (ODH) platforms. The workbench images provide interactive development environments including JupyterLab, RStudio, and CodeServer (VS Code), each with multiple variants supporting CPU-only, NVIDIA CUDA GPU, and AMD ROCm GPU acceleration. The runtime images are lightweight variants designed for executing pipelines in Kubeflow Pipelines (KFP) and Elyra environments. All images are built using Red Hat Universal Base Images (UBI9) or CentOS Stream 9, support multiple architectures (x86_64, arm64, ppc64le, s390x where applicable), and are built via Konflux CI/CD pipelines. These images are consumed by the ODH Notebook Controller component which manages the lifecycle of data scientist workspaces in OpenShift.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Jupyter Minimal | Workbench Image | Minimal JupyterLab environment with Python 3.12 and core data science libraries |
| Jupyter DataScience | Workbench Image | JupyterLab with extended data science libraries (pandas, scikit-learn, matplotlib) |
| Jupyter PyTorch | Workbench Image | JupyterLab with PyTorch deep learning framework and CUDA/ROCm GPU support |
| Jupyter TensorFlow | Workbench Image | JupyterLab with TensorFlow deep learning framework and CUDA/ROCm GPU support |
| Jupyter TrustyAI | Workbench Image | JupyterLab with TrustyAI explainability and fairness tools |
| Jupyter PyTorch+LLMCompressor | Workbench Image | JupyterLab with PyTorch and LLM compression tools for model optimization |
| CodeServer DataScience | Workbench Image | VS Code Server with data science libraries for code-centric development |
| RStudio Minimal | Workbench Image | RStudio Server for R-based data science workflows |
| Runtime Minimal | Pipeline Runtime | Lightweight Python runtime for pipeline task execution |
| Runtime DataScience | Pipeline Runtime | Pipeline runtime with common data science libraries |
| Runtime PyTorch | Pipeline Runtime | Pipeline runtime with PyTorch for GPU-accelerated ML training |
| Runtime TensorFlow | Pipeline Runtime | Pipeline runtime with TensorFlow for GPU-accelerated ML training |
| Base Images | Build Dependencies | Foundation images providing CPU/CUDA/ROCm base layers with Python |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define any CRDs. It provides container images that are referenced by ImageStream resources and consumed by the ODH Notebook Controller.

### HTTP Endpoints

These are the default ports exposed by workbench containers when running:

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| / | GET/POST | 8888/TCP | HTTP | None | Token/OAuth | JupyterLab main interface (Jupyter workbenches) |
| /api | GET/POST | 8888/TCP | HTTP | None | Token/OAuth | Jupyter Server REST API |
| /notebook/{namespace}/{notebook}/api | GET/POST | 8888/TCP | HTTP | None | Token/OAuth | Jupyter API via ODH proxy |
| / | GET/POST | 8080/TCP | HTTP | None | Token/OAuth | CodeServer (VS Code) web interface |
| / | GET/POST | 8787/TCP | HTTP | None | Basic Auth | RStudio Server web interface |

**Note**: In production deployments via ODH/RHOAI, these containers run behind an OAuth proxy service that provides TLS termination and authentication. Direct container access uses HTTP, while external access is HTTPS via OpenShift Routes.

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| Red Hat UBI9/RHEL9 | 9.6 | Yes | Base operating system for container images |
| CentOS Stream 9 | Latest | Yes | Alternative base OS for RStudio images |
| Python | 3.11, 3.12 | Yes | Primary programming language runtime |
| JupyterLab | 4.4 | Yes (workbenches) | Interactive notebook development environment |
| jupyter-server | ~2.17.0 | Yes (workbenches) | Backend server for Jupyter environments |
| NVIDIA CUDA | 12.6, 12.8 | No (GPU only) | GPU acceleration for PyTorch/TensorFlow |
| AMD ROCm | 6.2, 6.3, 6.4 | No (GPU only) | GPU acceleration for AMD GPUs |
| PyTorch | Latest stable | No (ML images) | Deep learning framework |
| TensorFlow | Latest stable | No (ML images) | Deep learning framework |
| RStudio Server | Latest | Yes (RStudio) | R development environment |
| code-server | Latest | Yes (CodeServer) | VS Code in browser |
| pandas | Latest | No (DataScience) | Data manipulation library |
| scikit-learn | Latest | No (DataScience) | Machine learning library |
| matplotlib | Latest | No (DataScience) | Data visualization library |
| OpenShift Client (oc) | Latest stable | Yes | CLI tool for OpenShift interaction |
| micropipenv | 1.9.0 | Yes | Python dependency management |
| uv | 0.9.6 | Yes | Fast Python package installer |

### Internal ODH/RHOAI Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| odh-notebook-controller | Image Consumer | Launches and manages workbench pods from these images |
| odh-dashboard | Image Reference | Lists available notebook images in UI |
| kubeflow-pipelines | Runtime Consumer | Executes pipeline tasks using runtime images |
| elyra | Runtime Consumer | Executes notebooks as pipeline tasks |
| oauth-proxy | HTTP Proxy | Provides authentication and TLS termination for workbench access |
| cert-manager | Certificate Provisioning | Provides TLS certificates for secure notebook access |
| OpenShift ImageStreams | Image Distribution | Manages image versions and tags for deployment |

## Network Architecture

### Services

**Note**: This component provides container images, not Kubernetes services. When deployed by the ODH Notebook Controller, each workbench instance gets its own Service resource.

Typical workbench deployment creates:

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| {notebook}-notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal (proxied) |
| oauth-proxy (sidecar) | ClusterIP | 8443/TCP | 8443 | HTTPS | TLS 1.2+ | OAuth2 | Internal |

### Ingress

Workbench access is provided via OpenShift Routes with OAuth proxy:

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| {notebook}-notebook | OpenShift Route | {notebook}-{namespace}.apps.{cluster} | 443/TCP | HTTPS | TLS 1.2+ | Edge | External |

### Egress

Workbench containers typically communicate with:

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token | Access cluster resources, create jobs |
| S3-compatible storage | 443/TCP | HTTPS | TLS 1.2+ | AWS Signature | Access data from object storage |
| Git repositories | 443/TCP | HTTPS | TLS 1.2+ | SSH Key/Token | Clone repositories, push changes |
| PyPI/Python Package Index | 443/TCP | HTTPS | TLS 1.2+ | None | Install Python packages |
| quay.io/registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Pull base images during builds |
| Container registries | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Push custom images |

## Security

### RBAC - Cluster Roles

**Note**: This component does not define ClusterRoles. RBAC is managed by the ODH Notebook Controller which launches these images.

Typical workbench pods run with:

| Role Name | API Group | Resources | Verbs |
|-----------|-----------|-----------|-------|
| Notebook ServiceAccount | "" | pods, services | get, list |
| Notebook ServiceAccount | "" | configmaps, secrets | get, list |
| Notebook ServiceAccount | "batch" | jobs | create, get, list, delete |

### RBAC - Role Bindings

RBAC bindings are created by the ODH Notebook Controller per workbench instance.

### Secrets

Container images reference these secret types when deployed:

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| {notebook}-oauth-config | Opaque | OAuth proxy configuration | odh-notebook-controller | No |
| {notebook}-tls | kubernetes.io/tls | TLS certificate for HTTPS | cert-manager | Yes |
| {user}-pull-secret | kubernetes.io/dockerconfigjson | Pull images from private registries | User/Admin | No |
| aws-connection-{name} | Opaque | S3 storage credentials | User | No |
| git-ssh-key | kubernetes.io/ssh-auth | Git repository access | User | No |

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| https://{notebook}.apps.{cluster}/ | GET/POST | OAuth2 (OpenShift) | oauth-proxy sidecar | User must be namespace member |
| http://localhost:8888/ | GET/POST | Jupyter Token | Jupyter Server | Token in cookie or query param |
| Kubernetes API | ALL | ServiceAccount Token | kube-apiserver | RBAC via ServiceAccount |

### Container Security

| Security Feature | Implementation | Purpose |
|------------------|----------------|---------|
| Non-root user | UID 1001 | Containers run as non-privileged user |
| Read-only rootfs | No | Workbenches need write access for user workspace |
| Capabilities drop | ALL | Minimal Linux capabilities |
| Seccomp profile | runtime/default | Restrict syscalls |
| SELinux | Enforcing | Container isolation on RHEL/OpenShift |
| Vulnerability scanning | Konflux/Clair | Detect CVEs in image layers |
| SBOM generation | Konflux | Track component versions |
| Signature verification | Cosign | Verify image authenticity |

## Data Flows

### Flow 1: User Accesses Jupyter Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | oauth-proxy pod | 8443/TCP | HTTPS | TLS 1.2+ | None |
| 3 | oauth-proxy | OpenShift OAuth | 443/TCP | HTTPS | TLS 1.2+ | OAuth2 Token |
| 4 | oauth-proxy | Jupyter container | 8888/TCP | HTTP | None | None (authenticated) |
| 5 | Jupyter container | Jupyter Server | localhost | HTTP | None | Session token |

### Flow 2: Pipeline Runtime Executes Task

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | KFP Controller | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |
| 2 | Kubernetes API | Runtime Pod | - | - | - | - |
| 3 | Runtime Pod | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS IAM/Secret Key |
| 4 | Runtime Pod | Kubernetes API | 6443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Image Build and Publish (Konflux)

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | GitHub Webhook | Konflux EventListener | 443/TCP | HTTPS | TLS 1.2+ | Webhook Secret |
| 2 | Tekton PipelineRun | GitHub | 443/TCP | HTTPS | TLS 1.2+ | GitHub Token |
| 3 | Tekton Build Task | Image Registry (UBI) | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 4 | Tekton Build Task | quay.io | 443/TCP | HTTPS | TLS 1.2+ | Push Token |
| 5 | Tekton Build Task | Vulnerability Scanner | 443/TCP | HTTPS | TLS 1.2+ | API Token |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | Pod Creation | 6443/TCP | HTTPS | TLS 1.2+ | Deploy workbench pods from these images |
| ODH Dashboard | Metadata Query | N/A | N/A | N/A | Display available notebook images via ImageStream annotations |
| Kubeflow Pipelines | Pod Creation | 6443/TCP | HTTPS | TLS 1.2+ | Execute pipeline tasks using runtime images |
| Elyra | Pod Creation | 6443/TCP | HTTPS | TLS 1.2+ | Submit notebook-based pipelines |
| OAuth Proxy | HTTP Proxy | 8888/TCP | HTTP | None | Authenticate and authorize workbench access |
| OpenShift ImageStream | Image Reference | N/A | N/A | N/A | Manage image versions and metadata |
| Konflux Build System | Image Build | 443/TCP | HTTPS | TLS 1.2+ | Build and publish container images |
| quay.io Registry | Image Storage | 443/TCP | HTTPS | TLS 1.2+ | Store and distribute container images |

## Build and Deployment Architecture

### Build Process (Konflux)

| Stage | Tool | Input | Output | Platform |
|-------|------|-------|--------|----------|
| Source Checkout | Tekton git-clone | GitHub repository | Source code | linux/amd64, linux/arm64 |
| Base Image Pull | buildah | UBI9/RHEL9/C9S images | Base layers | Multi-arch |
| Dependency Install | uv/micropipenv | pylock.toml, Pipfile.lock | Python packages | Multi-arch |
| Container Build | buildah | Dockerfile.konflux.{cpu\|cuda\|rocm} | Container image | Multi-arch |
| Vulnerability Scan | Clair/Snyk | Container image | CVE report | linux/amd64 |
| SBOM Generation | syft | Container image | SBOM (SPDX/CycloneDX) | linux/amd64 |
| Image Signing | Cosign | Container image | Signature | N/A |
| Image Push | skopeo | Signed image | quay.io registry | Multi-arch manifest |

### Deployment Process

Images are deployed by end users via ODH Dashboard or by administrators via ImageStream updates:

| Step | Actor | Action | Resource Type |
|------|-------|--------|---------------|
| 1 | Admin | Apply ImageStream manifests | ImageStream |
| 2 | ImageStream | Pull images from quay.io | Container images |
| 3 | User | Create notebook via Dashboard | Notebook CR |
| 4 | Notebook Controller | Reconcile Notebook CR | Pod, Service, Route |
| 5 | Kubelet | Pull workbench image | Container image from ImageStream |
| 6 | Kubelet | Start workbench container | Running pod |

## Image Variants and Tags

### Workbench Images

| Image Name | Accelerator | Python | Base OS | Architectures | Registry |
|------------|-------------|--------|---------|---------------|----------|
| odh-workbench-jupyter-minimal-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-workbench-jupyter-datascience-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-workbench-jupyter-trustyai-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-workbench-jupyter-minimal-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64, arm64 | quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-workbench-jupyter-tensorflow-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64, arm64 | quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-llmcompressor-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-workbench-jupyter-minimal-rocm-py312-ubi9 | AMD ROCm 6.3 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-workbench-jupyter-pytorch-rocm-py312-ubi9 | AMD ROCm 6.3 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-workbench-jupyter-tensorflow-rocm-py312-ubi9 | AMD ROCm 6.3 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-workbench-codeserver-datascience-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-workbench-rstudio-minimal-cpu-py312-c9s | CPU | 3.12 | C9S | x86_64, arm64 | quay.io/opendatahub |
| odh-workbench-rstudio-minimal-cuda-py312-c9s | NVIDIA CUDA 12.8 | 3.12 | C9S | x86_64, arm64 | quay.io/opendatahub |

### Runtime Images

| Image Name | Accelerator | Python | Base OS | Architectures | Registry |
|------------|-------------|--------|---------|---------------|----------|
| odh-pipeline-runtime-minimal-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-pipeline-runtime-datascience-cpu-py312-ubi9 | CPU | 3.12 | UBI9 | x86_64, arm64, ppc64le, s390x | quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-pipeline-runtime-tensorflow-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-llmcompressor-cuda-py312-ubi9 | NVIDIA CUDA 12.8 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-pipeline-runtime-pytorch-rocm-py312-ubi9 | AMD ROCm 6.3 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |
| odh-pipeline-runtime-tensorflow-rocm-py312-ubi9 | AMD ROCm 6.3 | 3.12 | UBI9/RHEL9.6 | x86_64 | quay.io/opendatahub |

### Version Tags

Images use calendar versioning (CalVer) with the pattern `YYYY.N`:
- `2025.2` - Current stable release (N)
- `2025.1` - Previous release (N-1)
- `2024.2` - Two releases back (N-2)
- Older versions maintained for compatibility

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2026-01-12 | fff8594 | sync pipelineruns with konflux-central |
| 2026-01-09 | 0f8616e | [rhoai-3.2] RHOAIENG-43410: Bump codeflare-sdk to 0.33.1 |
| 2026-01-07 | b0cb479 | RHOAIENG-42632: Remove useless v3-0-push pipelines from rhoai-3.2 branch |
| 2026-01-07 | 623db05 | RHOAIENG-43410: Bump codeflare-sdk to version 0.33.1 |
| 2025-12-30 | 91f5c07 | RHOAIENG-42632: Validate RHDS Tekton pipelines use appropriate konflux build arguments |
| 2026-01-05 | 935cdf3 | sync pipelineruns with konflux-central |
| 2025-12-20 | a161137 | sync pipelineruns with konflux-central |
| 2025-12-19 | d2edc42 | [rhoai-3.2] codeserver: Increment build trigger value |
| 2025-12-19 | 7566950 | [rhoai-3.2] Add .trigger-build file for UBI9 Python 3.12 |
| 2025-12-19 | db39e2a | Merge pull request from main |
| 2025-12-19 | dfaf49c | Cherry-pick RHAIENG-2111 to rhoai-3.2 |
| 2025-12-02 | 2582a7e | RHAIENG-2111: Remove unsafe activation key to be safe |
| 2025-12-19 | f14bf0d | RHAIENG-2111: Remove unsafe activation key |
| 2025-12-19 | 621ea6a | Merge remote-tracking branch upstream/main |
| 2025-12-19 | be9831f | NO-JIRA: Add SC3041 and SC3020 to hadolint ignore list |
| 2025-12-19 | cff36ad | sync pipelineruns with konflux-central |
| 2025-12-18 | c50008a | Merge pull request: Remove restart comment from YAML |
| 2025-12-18 | 948c9b1 | Remove restart comment from YAML configuration |
| 2025-12-18 | 863a2a5 | Merge remote-tracking branch upstream/main into rhoai-3.2 |
| 2025-12-18 | e774ba0 | Merge pull request: RStudio offboard RHDS |

## Testing and Validation

### Test Types

| Test Type | Tool | Scope | Frequency |
|-----------|------|-------|-----------|
| Unit Tests | pytest | Python code validation | Every commit |
| Container Tests | testcontainers | Image functionality | Every build |
| Browser Tests | Playwright | JupyterLab UI | Weekly |
| Integration Tests | papermill | Notebook execution | Every build |
| GPU Tests | pytest + testcontainers | CUDA/ROCm functionality | Per GPU build |
| Vulnerability Scans | Clair/Snyk | CVE detection | Every build |
| Compliance Scans | Konflux | License/SBOM validation | Every build |

### Quality Gates

All images must pass before merge/release:
- All unit tests passing
- Container starts successfully
- No critical/high CVEs
- SBOM generated
- Image signed with Cosign
- Multi-architecture build successful
- Dependencies locked with hash verification

## Maintenance and Updates

### Dependency Updates

| Dependency Type | Update Frequency | Automation |
|-----------------|------------------|------------|
| Python packages | Monthly | Renovate bot + manual review |
| Base OS (UBI9/RHEL9) | Monthly | Konflux rebuild triggers |
| CUDA/ROCm drivers | Per vendor release | Manual update + testing |
| JupyterLab | Per stable release | Manual update + testing |
| PyTorch/TensorFlow | Per stable release | Manual update + testing |

### Image Lifecycle

- **N (Current)**: Fully supported, recommended for new deployments
- **N-1**: Supported, security updates only
- **N-2**: Deprecated, security updates for critical issues
- **N-3+**: Unsupported, available for compatibility only

Support window: Minimum 6 months per major version

## Known Limitations

1. **GPU Support**: CUDA and ROCm images limited to x86_64 architecture (vendor limitation)
2. **RStudio**: Limited to C9S base (RHEL9 variant available but not all architectures)
3. **Write Access**: Workbenches require writable filesystem for user workspace (cannot use read-only rootfs)
4. **Image Size**: GPU-enabled images are 5-10GB due to CUDA/ROCm runtime dependencies
5. **Build Time**: Multi-architecture builds can take 30-60 minutes due to dependency compilation
6. **Python Version**: Transitioning from 3.11 to 3.12, some legacy images still on 3.11

## Related Documentation

- [Repository Wiki](https://github.com/opendatahub-io/notebooks/wiki/Workbenches)
- [Contributing Guide](CONTRIBUTING.md)
- [Agents Guide](Agents.md)
- [Update Notes](UPDATES.md)
- [CodeServer Extensions](codeserver/Extensions.md)

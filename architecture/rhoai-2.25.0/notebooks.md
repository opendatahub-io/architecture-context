# Component: Notebooks (Workbench Images)

## Metadata
- **Repository**: https://github.com/red-hat-data-services/notebooks
- **Version**: v2.25.2-55-g349bd5ebb
- **Branch**: rhoai-2.25
- **Distribution**: RHOAI (Red Hat OpenShift AI)
- **Languages**: Python, Bash, Makefile, Dockerfile
- **Deployment Type**: Container Images (Workbenches and Runtimes)

## Purpose
**Short**: Container image repository providing JupyterLab, VS Code, and RStudio workbench environments, plus Kubeflow Pipelines runtime images for data science workflows in RHOAI.

**Detailed**: This repository contains the source code, build configurations, and deployment manifests for workbench and runtime container images used in Red Hat OpenShift AI (RHOAI) and Open Data Hub (ODH). It provides pre-configured development environments (workbenches) for data scientists including Jupyter notebooks, VS Code Server, and RStudio, each with different ML framework stacks (PyTorch, TensorFlow, TrustyAI). Additionally, it provides lightweight runtime images for executing Kubeflow Pipelines tasks. Images are built on UBI9 (Universal Base Image 9) and support multiple hardware accelerators including CPU-only, NVIDIA CUDA GPUs, and AMD ROCm GPUs. All images are built using Red Hat's Konflux CI/CD platform and deployed via OpenShift ImageStreams.

The repository implements a versioned release strategy with major updates twice yearly (named YYYY.N format like 2025.2) and weekly patch updates for security fixes. Each image variant supports multiple Python versions (currently 3.11 and 3.12) and maintains N through N-6 version history for backward compatibility.

## Architecture Components

| Component | Type | Purpose |
|-----------|------|---------|
| Jupyter Workbenches | Container Images | Interactive notebook environments with JupyterLab 4.4 for data science and ML development |
| Code Server Workbenches | Container Images | VS Code-based development environments with code-server for Python development |
| RStudio Workbenches | Container Images | RStudio Server environments for R-based data science workflows |
| Runtime Images | Container Images | Lightweight images for executing Kubeflow Pipelines tasks without interactive UI |
| Base Images | Build Artifacts | Foundation images with CUDA/ROCm drivers and Python environments |
| Kustomize Manifests | Deployment Config | OpenShift ImageStream definitions for image deployment |
| Tekton Pipelines | Build Config | Konflux multi-arch build pipelines for container images |
| Build Scripts | Automation | Python/Bash scripts for image building, testing, and validation |

## APIs Exposed

### Custom Resource Definitions (CRDs)

This component does not define CRDs. It provides container images that are referenced by ImageStreams and consumed by the ODH Notebook Controller.

### HTTP Endpoints

| Path | Method | Port | Protocol | Encryption | Auth | Purpose |
|------|--------|------|----------|------------|------|---------|
| /notebook/\{namespace\}/\{username\} | GET, POST | 8888/TCP | HTTP | None | ODH Notebook Controller | Jupyter Server base URL |
| /notebook/\{namespace\}/\{username\}/api | GET | 8888/TCP | HTTP | None | ODH Notebook Controller | Jupyter API endpoint for health checks |
| /notebook/\{namespace\}/\{username\}/lab | GET | 8888/TCP | HTTP | None | ODH Notebook Controller | JupyterLab UI interface |
| / | GET, POST | 8787/TCP | HTTP | None | ODH Notebook Controller | RStudio Server interface |
| / | GET, POST | 8080/TCP | HTTP | None | ODH Notebook Controller | Code Server (VS Code) interface |

### gRPC Services

This component does not expose gRPC services.

## Dependencies

### External Dependencies

| Component | Version | Required | Purpose |
|-----------|---------|----------|---------|
| UBI9 Python Base Image | registry.access.redhat.com/ubi9/python-312:latest | Yes | Base OS and Python runtime for all images |
| CUDA Base Image | quay.io/rhoai/cuda-* | Conditional | NVIDIA GPU support for CUDA-enabled images |
| ROCm Base Image | quay.io/rhoai/rocm-* | Conditional | AMD GPU support for ROCm-enabled images |
| JupyterLab | 4.4 | Yes | Interactive notebook interface for Jupyter workbenches |
| PyTorch | 2.x | Conditional | Deep learning framework for PyTorch images |
| TensorFlow | 2.x | Conditional | Deep learning framework for TensorFlow images |
| TrustyAI | Latest | Conditional | Explainable AI toolkit for TrustyAI images |
| LLMCompressor | Latest | Conditional | LLM compression toolkit for llmcompressor images |
| OpenShift Client (oc) | stable | Yes | OpenShift CLI tool included in all images |
| uv | 0.8.12 | Yes | Fast Python package installer |
| micropipenv | 1.9.0 | Yes | Lightweight pip wrapper for requirements installation |

### Internal ODH Dependencies

| Component | Interaction Type | Purpose |
|-----------|------------------|---------|
| ODH Notebook Controller | CRD Consumer | Launches workbench pods using these container images |
| ODH Dashboard | Image Registry | Lists available workbench images from ImageStreams |
| Kubeflow Pipelines | Runtime Consumer | Executes pipeline tasks using runtime images |
| Model Mesh | Runtime Consumer | Uses runtime images for model serving initialization |

## Network Architecture

### Services

| Service Name | Type | Port | Target Port | Protocol | Encryption | Auth | Exposure |
|--------------|------|------|-------------|----------|------------|------|----------|
| notebook | ClusterIP | 8888/TCP | 8888 | HTTP | None | None | Internal (via ODH OAuth proxy) |
| rstudio | ClusterIP | 8787/TCP | 8787 | HTTP | None | None | Internal (via ODH OAuth proxy) |
| code-server | ClusterIP | 8080/TCP | 8080 | HTTP | None | None | Internal (via ODH OAuth proxy) |

**Note**: Services are created dynamically by ODH Notebook Controller when workbenches are launched. Direct container-to-container encryption is not used; TLS termination occurs at the OpenShift Route/Ingress level managed by the ODH Dashboard.

### Ingress

| Name | Type | Hosts | Port | Protocol | Encryption | TLS Mode | Exposure |
|------|------|-------|------|----------|------------|----------|----------|
| notebook-\{username\} | OpenShift Route | dynamically assigned | 443/TCP | HTTPS | TLS 1.2+ | Edge | External (via OpenShift Router) |

**Note**: Routes are created by ODH Notebook Controller with OAuth proxy sidecar for authentication.

### Egress

| Destination | Port | Protocol | Encryption | Auth | Purpose |
|-------------|------|----------|------------|------|---------|
| quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Container image pulls |
| registry.redhat.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret | Red Hat container registry access |
| mirror.openshift.com | 443/TCP | HTTPS | TLS 1.2+ | None | Download OpenShift CLI (oc) during build |
| pypi.org | 443/TCP | HTTPS | TLS 1.2+ | None | Python package installation at build time |
| S3 Compatible Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 | Kubeflow Pipelines artifact storage (runtime images) |
| Object Storage | 443/TCP | HTTPS | TLS 1.2+ | S3 credentials | Data access from notebooks |

## Security

### RBAC - Cluster Roles

This component does not define ClusterRoles. RBAC is managed by the ODH Notebook Controller which launches these images.

### RBAC - Role Bindings

This component does not define RoleBindings. The workbench pods run with the ServiceAccount assigned by the ODH Notebook Controller.

### Secrets

| Secret Name | Type | Purpose | Provisioned By | Auto-Rotate |
|-------------|------|---------|----------------|-------------|
| N/A - Pull Secret | kubernetes.io/dockerconfigjson | Pull images from authenticated registries | OpenShift Installation | No |
| N/A - User credentials | Opaque | Mounted by users for data access, cloud credentials | End Users | No |

**Note**: This component does not create secrets. Secrets are managed by users and the platform.

### Authentication & Authorization

| Endpoint | Methods | Auth Mechanism | Enforcement Point | Policy |
|----------|---------|----------------|-------------------|--------|
| /notebook/\{namespace\}/\{username\}/* | ALL | OAuth Proxy (OpenShift OAuth) | OAuth2 Proxy Sidecar | Only authenticated OpenShift users can access their own notebooks |
| Container Registry | PULL | Pull Secret | Kubelet | Only authenticated service accounts can pull images |

**Note**: Workbench containers themselves do not enforce authentication. The ODH OAuth proxy sidecar container handles authentication before requests reach the workbench application (Jupyter/VS Code/RStudio).

## Data Flows

### Flow 1: User Accesses Jupyter Workbench

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | User Browser | OpenShift Router | 443/TCP | HTTPS | TLS 1.2+ | None |
| 2 | OpenShift Router | OAuth Proxy Sidecar | 8443/TCP | HTTPS | TLS 1.2+ (internal CA) | OpenShift OAuth |
| 3 | OAuth Proxy Sidecar | Jupyter Container | 8888/TCP | HTTP | None | None (localhost) |
| 4 | Jupyter Container | Object Storage | 443/TCP | HTTPS | TLS 1.2+ | S3 Credentials |

### Flow 2: Kubeflow Pipeline Task Execution

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Kubeflow Pipeline Controller | Runtime Container (Pod) | N/A | N/A | N/A | ServiceAccount Token |
| 2 | Runtime Container | S3 Storage | 443/TCP | HTTPS | TLS 1.2+ | AWS SigV4 |
| 3 | Runtime Container | Kubeflow API | 443/TCP | HTTPS | TLS 1.2+ | ServiceAccount Token |

### Flow 3: Image Build and Deployment

| Step | Source | Destination | Port | Protocol | Encryption | Auth |
|------|--------|-------------|------|----------|------------|------|
| 1 | Konflux Pipeline | GitHub | 443/TCP | HTTPS | TLS 1.2+ | Git Token |
| 2 | Konflux Build Task | UBI Registry | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |
| 3 | Konflux Build Task | Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Push Secret |
| 4 | OpenShift ImageStream | Quay.io | 443/TCP | HTTPS | TLS 1.2+ | Pull Secret |

## Integration Points

| Component | Interaction Type | Port | Protocol | Encryption | Purpose |
|-----------|------------------|------|----------|------------|---------|
| ODH Notebook Controller | ImageStream Reference | N/A | N/A | N/A | Launches workbench pods using images from ImageStreams |
| ODH Dashboard | ImageStream Query | 6443/TCP | HTTPS | TLS 1.2+ | Lists available workbench images to users |
| Kubeflow Pipelines | Container Execution | N/A | N/A | N/A | Runs pipeline tasks in runtime containers |
| OpenShift Image Registry | Image Pull | 5000/TCP | HTTPS | TLS 1.2+ (internal CA) | Pulls images for pod creation |
| Konflux Build System | CI/CD Pipeline | 443/TCP | HTTPS | TLS 1.2+ | Builds and pushes container images |

## Container Images Catalog

### Workbench Images - Jupyter

| Image Name | Accelerator | Python | ML Frameworks | Use Case |
|------------|-------------|--------|---------------|----------|
| jupyter-minimal-cpu | CPU | 3.12 | None | Minimal notebook for general Python development |
| jupyter-minimal-cuda | NVIDIA GPU | 3.12 | CUDA 12.6/12.8 | Minimal GPU-enabled notebook |
| jupyter-minimal-rocm | AMD GPU | 3.12 | ROCm 6.2/6.4 | Minimal AMD GPU-enabled notebook |
| jupyter-datascience-cpu | CPU | 3.12 | Pandas, Scikit-learn, Matplotlib | Data science with common libraries |
| jupyter-pytorch-cuda | NVIDIA GPU | 3.12 | PyTorch 2.x, CUDA | Deep learning with PyTorch on NVIDIA GPUs |
| jupyter-pytorch-rocm | AMD GPU | 3.12 | PyTorch 2.x, ROCm | Deep learning with PyTorch on AMD GPUs |
| jupyter-pytorch-llmcompressor-cuda | NVIDIA GPU | 3.12 | PyTorch 2.x, LLMCompressor | LLM compression and quantization |
| jupyter-tensorflow-cuda | NVIDIA GPU | 3.12 | TensorFlow 2.x, CUDA | Deep learning with TensorFlow on NVIDIA GPUs |
| jupyter-tensorflow-rocm | AMD GPU | 3.12 | TensorFlow 2.x, ROCm | Deep learning with TensorFlow on AMD GPUs |
| jupyter-trustyai-cpu | CPU | 3.12 | TrustyAI, Pandas | Explainable AI and model analysis |

### Workbench Images - Code Server (VS Code)

| Image Name | Accelerator | Python | Frameworks | Use Case |
|------------|-------------|--------|------------|----------|
| codeserver-datascience-cpu | CPU | 3.12 | Pandas, Scikit-learn | VS Code IDE for data science |

### Workbench Images - RStudio

| Image Name | Accelerator | Python | R Support | Use Case |
|------------|-------------|--------|-----------|----------|
| rstudio-minimal-cpu | CPU | 3.11 | R 4.x | RStudio Server for R development |
| rstudio-minimal-cuda | NVIDIA GPU | 3.11 | R 4.x, CUDA | RStudio with GPU support |

### Runtime Images (Kubeflow Pipelines)

| Image Name | Accelerator | Python | Frameworks | Use Case |
|------------|-------------|--------|------------|----------|
| runtime-minimal-cpu | CPU | 3.12 | None | Minimal Python runtime for simple pipeline tasks |
| runtime-datascience-cpu | CPU | 3.12 | Pandas, Scikit-learn | Data processing pipeline tasks |
| runtime-pytorch-cuda | NVIDIA GPU | 3.12 | PyTorch 2.x | ML training/inference in pipelines (NVIDIA) |
| runtime-pytorch-rocm | AMD GPU | 3.12 | PyTorch 2.x | ML training/inference in pipelines (AMD) |
| runtime-pytorch-llmcompressor-cuda | NVIDIA GPU | 3.12 | PyTorch, LLMCompressor | LLM compression in pipelines |
| runtime-tensorflow-cuda | NVIDIA GPU | 3.12 | TensorFlow 2.x | TensorFlow pipeline tasks (NVIDIA) |
| runtime-tensorflow-rocm | AMD GPU | 3.12 | TensorFlow 2.x | TensorFlow pipeline tasks (AMD) |

## Build and Deployment Architecture

### Build Process (Konflux)

| Stage | Tool | Input | Output | Platform Support |
|-------|------|-------|--------|------------------|
| Source Clone | Tekton Git Task | GitHub Repository | Source Code | N/A |
| Multi-Arch Build | Buildah | Dockerfile.konflux.* | Container Image | linux/x86_64, linux/arm64, linux/ppc64le, linux/s390x |
| Security Scan | Clair/Trivy | Container Image | Vulnerability Report | All platforms |
| Image Push | Skopeo | Container Image | Quay.io Registry | All platforms |
| ImageStream Update | Kustomize | ConfigMap (params.env) | OpenShift ImageStream | N/A |

### Deployment Process

| Step | Component | Action | Output |
|------|-----------|--------|--------|
| 1 | User via ODH Dashboard | Select workbench image and size | Notebook CRD created |
| 2 | ODH Notebook Controller | Reconcile Notebook CRD | StatefulSet created |
| 3 | Kubernetes Scheduler | Schedule Pod | Pod assigned to node |
| 4 | Kubelet | Pull image from ImageStream | Container image pulled to node |
| 5 | Kubelet | Start container | Workbench running |
| 6 | ODH Notebook Controller | Create Route with OAuth proxy | User can access workbench |

## Version Management

### Release Strategy

| Release Type | Frequency | Version Format | Scope |
|--------------|-----------|----------------|-------|
| Major Release | Twice yearly | YYYY.N (e.g., 2025.2) | Major/minor version updates to OS, Python, ML frameworks |
| Patch Release | Weekly | YYYY.N-YYYYMMDD | Security patches, bug fixes (patch version only) |
| Support Window | 1 year minimum | N and N-1 releases | Two concurrent supported versions |
| Version History | 7 versions | N through N-6 | Backward compatibility for migration |

### Current Version Matrix

| Image Variant | Current (2025.2) | Previous (2025.1) | Status |
|---------------|------------------|-------------------|--------|
| Python Version | 3.12 | 3.11 | Both supported |
| JupyterLab | 4.4 | 4.4 | Stable |
| Base OS | UBI9 | UBI9 | Stable |
| CUDA | 12.6, 12.8 | 12.6 | Multiple versions |
| ROCm | 6.2, 6.4 | 6.2 | Multiple versions |

## Recent Changes

| Date | Commit | Changes |
|------|--------|---------|
| 2026-03-12 | 349bd5ebb | chore(ktlo): move the up-to-date ntb/ and scripts/dockerfile_fragments from main over here |
| 2026-03-11 | 2ea012e9e | sync pipelineruns with konflux-central - 19bdad4 |
| 2026-03-05 | 9606e18c8 | NO-JIRA: run uv run scripts/dockerfile_fragments.py |
| 2026-03-05 | 3c7560e79 | chore(ktlo): move the up-to-date ntb/ and scripts/dockerfile_fragments from main over here |
| 2026-03-05 | 1615e6de1 | RHAIENG-287, AIPCC-6072: fix(tests): exclude MPI libraries from unsatisfied dependency checks in CUDA AIPCC test |
| 2026-02-26 | fdb7b5eba | Fix for wheels wording error |
| 2026-02-26 | 95cba6dfa | sync pipelineruns with konflux-central - e68c3cf |
| 2026-02-20 | 4d15f5953 | Merge pull request #1908 from odh-on-pz/trustyai-fix |
| 2026-02-19 | 792ee980d | updated file (trustyai) |
| 2026-02-19 | 550ad4ab8 | Fixed pandas issue for trustyai |
| 2026-02-19 | 25b87e9b7 | Merge pull request #1915 from red-hat-data-services/llmcomp-pull |
| 2026-02-19 | fa0b76fe3 | Adds a pull request pipeline for missing pytorch-llmcompressor-cuda |
| 2026-02-19 | 226675f76 | Merge pull request #1914 from red-hat-data-services/fix_trusty |

## Testing and Validation

### Test Categories

| Test Type | Framework | Target | Execution Environment |
|-----------|-----------|--------|----------------------|
| Container Selftest | pytest + testcontainers | Verify packages, commands, ports | Podman/Docker local |
| Browser UI Test | Playwright | Verify JupyterLab UI functionality | Kubernetes cluster |
| Runtime Validation | pytest | Verify runtime image compatibility | Kubernetes cluster |
| Security Scan | Trivy | Vulnerability detection | Konflux pipeline |
| Linting | hadolint, yamllint, ruff | Code quality | GitHub Actions |

### Image Validation Checks

| Check | Command | Purpose |
|-------|---------|---------|
| Required Commands | `which curl python3` | Ensure essential tools present |
| Port Listening | TCP probe on 8888 | Verify Jupyter server starts |
| API Endpoint | HTTP GET /api | Verify Jupyter API responds |
| Package Imports | `python -c "import torch"` | Verify ML frameworks installed |
| GPU Detection | `nvidia-smi` or `rocm-smi` | Verify GPU access (accelerator images) |

## Troubleshooting

### Common Issues

| Issue | Symptom | Resolution |
|-------|---------|------------|
| Image Pull Failure | Pod stuck in ImagePullBackOff | Verify pull secret configured, check image tag in ImageStream |
| Jupyter Won't Start | Liveness probe fails | Check container logs, verify port 8888 accessible |
| GPU Not Detected | `nvidia-smi` not found | Ensure node has GPU, verify NFD operator running |
| Package Import Error | `ModuleNotFoundError` | Check image variant matches requirements, consider custom image |
| Slow Build Times | Builds timeout | Adjust Konflux timeout, check network connectivity |

## References

- **GitHub Repository**: https://github.com/red-hat-data-services/notebooks
- **Upstream (ODH)**: https://github.com/opendatahub-io/notebooks
- **Container Registry**: https://quay.io/repository/opendatahub/workbench-images
- **Wiki**: https://github.com/opendatahub-io/notebooks/wiki/Workbenches
- **Contributing Guide**: https://github.com/opendatahub-io/notebooks/blob/main/CONTRIBUTING.md

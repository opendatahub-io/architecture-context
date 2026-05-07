workspace {
    model {
        user = person "Data Scientist" "Creates and uses interactive notebook workbenches for ML/data science work"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Multi-image build factory producing interactive IDE environments and pipeline runtime images for RHOAI" {
            jupyterMinimal = container "jupyter-minimal" "Minimal JupyterLab with base Python 3.12" "Container Image (UBI9)"
            jupyterDatascience = container "jupyter-datascience" "JupyterLab + pandas, scikit-learn, boto3, Elyra, Codeflare-SDK" "Container Image (UBI9)"
            jupyterPytorch = container "jupyter-pytorch" "JupyterLab + PyTorch + CUDA GPU support" "Container Image (CUDA)"
            jupyterTensorflow = container "jupyter-tensorflow" "JupyterLab + TensorFlow + CUDA GPU support" "Container Image (CUDA)"
            jupyterTrustyai = container "jupyter-trustyai" "JupyterLab + TrustyAI fairness/explainability + Java 17" "Container Image (UBI9)"
            jupyterLLMCompressor = container "jupyter-pytorch-llmcompressor" "JupyterLab + PyTorch + LLMCompressor for model compression" "Container Image (CUDA)"
            jupyterROCm = container "jupyter-minimal-rocm" "Minimal JupyterLab with AMD ROCm GPU support" "Container Image (ROCm)"
            codeserver = container "codeserver" "VS Code (code-server) in-browser IDE + NGINX proxy" "Container Image (UBI9)"
            rstudioCPU = container "rstudio-cpu" "RStudio Server IDE + R 4.5.1 + NGINX proxy" "Container Image (RHEL9)"
            rstudioCUDA = container "rstudio-cuda" "RStudio Server IDE with CUDA GPU support" "Container Image (CUDA)"
            runtimeMinimal = container "runtime-minimal" "Headless Python runtime for Elyra pipeline execution" "Container Image (UBI9)"
            runtimeDatascience = container "runtime-datascience" "Headless runtime with data science libraries" "Container Image (UBI9)"
            runtimePytorch = container "runtime-pytorch" "Headless runtime with PyTorch + CUDA" "Container Image (CUDA)"
            runtimeTensorflow = container "runtime-tensorflow" "Headless runtime with TensorFlow + CUDA" "Container Image (CUDA)"
            imagestreams = container "ImageStream Manifests" "Kustomize manifests producing OpenShift ImageStream resources" "Kustomize/YAML"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Creates StatefulSet pods, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and launching workbenches" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests into the cluster" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar providing OAuth + RBAC authentication for workbench access" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines / Tekton" "Pipeline orchestrator that runs runtime images as pipeline steps" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Pipeline editor bundled in datascience workbenches" "Internal RHOAI"
        codeflareSDK = softwareSystem "Codeflare-SDK" "Distributed computing job submission from notebooks" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training" "Python SDK for distributed training jobs" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io / Quay.io for image storage" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Model artifacts and pipeline data storage" "External"
        konflux = softwareSystem "Konflux" "CI/CD build system for container images" "External"
        aipcc = softwareSystem "AIPCC Base Images" "AI Platform Container Collection base layers (UBI9, CUDA, ROCm)" "External"

        # Relationships
        user -> rhoaiDashboard "Selects workbench image and creates Workbench" "HTTPS/443"
        user -> kubeRBACProxy "Accesses workbench IDE" "HTTPS/8443"

        rhoaiDashboard -> notebooks "Reads ImageStream metadata to show available images"
        rhoaiDashboard -> notebookController "Triggers workbench creation"

        notebookController -> notebooks "Creates StatefulSet running workbench image"
        notebookController -> kubeRBACProxy "Injects as sidecar into workbench pods"
        rhodsOperator -> notebooks "Deploys ImageStream manifests from manifests/base"

        kubeRBACProxy -> notebooks "Proxies authenticated requests to IDE" "HTTP/8888, HTTP/8787"
        kubeRBACProxy -> k8sAPI "Validates OAuth tokens via SubjectAccessReview" "HTTPS/6443"

        kubeflowPipelines -> notebooks "Uses runtime images for pipeline step execution"
        elyra -> kubeflowPipelines "Submits pipelines" "HTTPS/443"

        notebooks -> k8sAPI "oc CLI commands, pipeline submission" "HTTPS/6443"
        notebooks -> s3Storage "Pipeline artifact storage" "HTTPS/443"
        notebooks -> aipcc "Base image layers (CPU, CUDA, ROCm)"

        konflux -> notebooks "Builds container images from Dockerfile.konflux.*"
        konflux -> containerRegistry "Pushes built images" "HTTPS/443"
        k8sAPI -> containerRegistry "Pulls workbench/runtime images" "HTTPS/443"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout
        }

        container notebooks "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates workbenches and runs ML experiments in RHOAI"
        mlEngineer = person "ML Engineer" "Builds and submits pipelines using Elyra"

        notebooksDownstream = softwareSystem "Notebooks (Workbench Images)" "Container image build repository producing ~35 workbench and runtime images for RHOAI" {
            jupyterMinimal = container "Jupyter Minimal" "Base JupyterLab 4.2 on UBI9 Python 3.11/3.12" "Container Image" "Image"
            jupyterDataScience = container "Jupyter Data Science" "Data science libraries, database CLIs, Elyra pipeline integration" "Container Image" "Image"
            jupyterPyTorch = container "Jupyter PyTorch CUDA" "PyTorch with NVIDIA CUDA 12.6.3 GPU acceleration" "Container Image" "Image"
            jupyterTensorFlow = container "Jupyter TensorFlow CUDA" "TensorFlow with NVIDIA CUDA 12.6.3 GPU acceleration" "Container Image" "Image"
            jupyterTrustyAI = container "Jupyter TrustyAI" "Explainability and fairness libraries with Java 17" "Container Image" "Image"
            jupyterROCmPT = container "Jupyter ROCm PyTorch" "PyTorch with AMD ROCm 6.2.4 GPU acceleration" "Container Image" "Image"
            jupyterROCmTF = container "Jupyter ROCm TensorFlow" "TensorFlow with AMD ROCm 6.2.4 GPU acceleration" "Container Image" "Image"
            codeServer = container "Code Server" "VS Code (code-server 4.98) with NGINX 1.24 reverse proxy" "Container Image" "Image"
            rstudio = container "RStudio Server" "RStudio with R 4.4.3 on C9S/RHEL9, NGINX reverse proxy" "Container Image" "Image"
            runtimeMinimal = container "Runtime Minimal" "Lightweight Python for Elyra pipeline execution" "Container Image" "Image"
            runtimeDataScience = container "Runtime Data Science" "Data science libraries for pipeline steps" "Container Image" "Image"
            runtimeMLFrameworks = container "Runtime ML Frameworks" "PyTorch/TensorFlow CUDA and ROCm variants" "Container Image" "Image"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize base + overlays defining OpenShift ImageStreams" "Kustomize YAML" "Manifest"
            tektonPipelines = container "Tekton PipelineRuns" "Konflux CI build definitions per image variant" "Tekton YAML" "CI/CD"
            buildSandbox = container "Build Sandbox" "sandbox.py + buildinputs for isolated Dockerfile builds" "Python/Go" "Tool"

            jupyterMinimal -> jupyterDataScience "base layer for"
            jupyterDataScience -> jupyterPyTorch "base layer for"
            jupyterDataScience -> jupyterTensorFlow "base layer for"
            jupyterDataScience -> jupyterTrustyAI "base layer for"
            jupyterDataScience -> jupyterROCmPT "base layer for"
            jupyterDataScience -> jupyterROCmTF "base layer for"
            runtimeMinimal -> runtimeDataScience "base layer for"
            runtimeDataScience -> runtimeMLFrameworks "base layer for"
            tektonPipelines -> buildSandbox "uses for build context"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Creates StatefulSets and injects kube-rbac-proxy sidecar for workbenches" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests and manages RHOAI platform" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and managing workbenches" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Orchestrates ML pipeline execution using runtime images" "Internal ODH"
        konfluxCI = softwareSystem "Konflux CI" "Builds container images via Tekton PipelineRuns on PR" "External"
        openShiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster operations" "External"
        quayRegistry = softwareSystem "quay.io/opendatahub" "Container image registry for built images" "External"
        baseImageRegistry = softwareSystem "Red Hat Container Registry" "Source for UBI9 and C9S base images" "External"
        nvidiaRepo = softwareSystem "NVIDIA CUDA Repository" "CUDA 12.6.3, cuDNN 9.5, NCCL 2.23 packages" "External"
        amdROCm = softwareSystem "AMD ROCm Repository" "ROCm 6.2.4 SDK packages" "External"
        pyPI = softwareSystem "PyPI" "Python Package Index for user package installation" "External"
        cran = softwareSystem "CRAN" "R package repository for RStudio users" "External"

        dataScientist -> rhoaiDashboard "Selects workbench type" "HTTPS/443"
        dataScientist -> notebooksDownstream "Uses workbench" "HTTPS/443 via Gateway"
        mlEngineer -> notebooksDownstream "Submits pipeline via Elyra" "HTTPS/443"

        rhoaiDashboard -> imageStreamManifests "Reads annotations to present workbench options"
        rhodsOperator -> imageStreamManifests "Deploys ImageStream resources" "kustomize"
        notebookController -> notebooksDownstream "Creates StatefulSets using workbench images" "ImageStream reference"
        kubeflowPipelines -> runtimeMinimal "Runs pipeline steps" "Container exec"
        kubeflowPipelines -> runtimeDataScience "Runs pipeline steps" "Container exec"
        kubeflowPipelines -> runtimeMLFrameworks "Runs pipeline steps" "Container exec"

        notebooksDownstream -> openShiftAPI "oc CLI, Kubernetes API access" "HTTPS/6443"
        notebooksDownstream -> kubeflowPipelines "Elyra pipeline submission" "HTTPS/443"
        notebooksDownstream -> pyPI "User-initiated package install" "HTTPS/443"
        notebooksDownstream -> cran "R package installation" "HTTPS/443"

        konfluxCI -> tektonPipelines "Triggers builds on PR" "PipelinesAsCode webhook"
        tektonPipelines -> baseImageRegistry "Pulls base images" "HTTPS/443"
        tektonPipelines -> nvidiaRepo "Pulls CUDA packages" "HTTPS/443"
        tektonPipelines -> amdROCm "Pulls ROCm packages" "HTTPS/443"
        tektonPipelines -> quayRegistry "Pushes built images" "HTTPS/443"
    }

    views {
        systemContext notebooksDownstream "SystemContext" {
            include *
            autoLayout
        }

        container notebooksDownstream "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Image" {
                shape RoundedBox
                background #4a90e2
                color #ffffff
            }
            element "Manifest" {
                shape Folder
                background #95a5a6
                color #ffffff
            }
            element "CI/CD" {
                shape Hexagon
                background #f5a623
                color #ffffff
            }
            element "Tool" {
                shape Component
                background #7ed321
                color #ffffff
            }
        }
    }
}

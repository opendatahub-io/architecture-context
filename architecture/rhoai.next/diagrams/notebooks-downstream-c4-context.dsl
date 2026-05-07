workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML/AI development"
        developer = person "Developer" "Contributes code and Dockerfiles to notebooks-downstream repo"

        notebooksDownstream = softwareSystem "Notebooks-Downstream" "Builds and publishes ~35 container images for interactive data science workbenches (Jupyter, RStudio, code-server) and pipeline runtimes for RHOAI" {
            jupyterImages = container "Jupyter Notebook Images" "JupyterLab-based workbenches with variants for CPU, CUDA 12.6.3, and ROCm 6.2.4 across Python 3.11/3.12" "Container Image (UBI 9)"
            codeServerImage = container "Code Server Image" "VS Code (code-server v4.98.0) in browser with NGINX proxy and supervisord" "Container Image (UBI 9)"
            rstudioImages = container "RStudio Server Images" "RStudio Server 2024.12.1 with R 4.4.3, NGINX proxy, supervisord; C9S and RHEL9 variants" "Container Image (UBI 9 / C9S / RHEL 9)"
            runtimeImages = container "Pipeline Runtime Images" "Headless Python environments for Elyra/DSP pipeline step execution" "Container Image (UBI 9)"
            buildSystem = container "Build System" "Makefile + Tekton/Konflux CI/CD pipelines for multi-arch image builds" "Make, Tekton, Go"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions with 6 tagged versions (N through N-5) and SHA256 digest pinning" "Kustomize YAML"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Launches workbench images as StatefulSet pods, injects auth sidecars, manages routing" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for selecting and managing workbenches; reads ImageStream annotations" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Applies kustomize manifests to create/update ImageStreams on cluster" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines (Elyra)" "Pipeline orchestrator that uses runtime images for notebook-based pipeline steps" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed training job management; SDK bundled in datascience images" "Internal RHOAI"

        quayRegistry = softwareSystem "quay.io/modh" "Container image registry for built workbench and runtime images" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster operations" "External"
        nvidiaRuntime = softwareSystem "NVIDIA Container Runtime" "GPU passthrough for CUDA images via env vars" "External"
        amdRuntime = softwareSystem "AMD ROCm Runtime" "GPU passthrough for ROCm images via device plugin" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD platform triggering multi-arch builds on PRs via PipelineRuns" "External"
        github = softwareSystem "GitHub" "Source code hosting and PR-based development workflow" "External"

        # Relationships - Users
        dataScientist -> rhoaiDashboard "Selects workbench type" "HTTPS/443, OAuth2/OIDC"
        dataScientist -> jupyterImages "Uses for interactive development" "HTTPS/443 via HTTPRoute → HTTP/8888"
        dataScientist -> codeServerImage "Uses VS Code in browser" "HTTPS/443 via HTTPRoute → HTTP/8787"
        dataScientist -> rstudioImages "Uses R IDE in browser" "HTTPS/443 via HTTPRoute → HTTP/8787"
        developer -> github "Submits PRs with Dockerfile changes" "HTTPS/443"

        # Relationships - Internal Platform
        notebookController -> jupyterImages "Launches as StatefulSets" "ImageStream reference"
        notebookController -> codeServerImage "Launches as StatefulSets" "ImageStream reference"
        notebookController -> rstudioImages "Launches as StatefulSets" "ImageStream reference"
        rhoaiDashboard -> kustomizeManifests "Reads ImageStream annotations for workbench UI" "K8s API/6443"
        rhodsOperator -> kustomizeManifests "Applies to create/update ImageStreams" "HTTPS/6443"
        dsPipelines -> runtimeImages "Executes pipeline steps" "Image reference"
        kubeflowTraining -> jupyterImages "SDK bundled for distributed training submission" "In-image SDK"

        # Relationships - External
        buildSystem -> quayRegistry "Pushes built images" "HTTPS/443"
        konflux -> buildSystem "Triggers multi-arch builds on PRs" "Tekton PipelineRun"
        jupyterImages -> openshiftAPI "oc CLI from workbenches" "HTTPS/6443, Bearer Token"
        jupyterImages -> nvidiaRuntime "GPU compute (CUDA images)" "Container runtime hook"
        jupyterImages -> amdRuntime "GPU compute (ROCm images)" "Container runtime hook"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container Image (UBI 9)" {
                background #438dd5
                color #ffffff
            }
            element "Container Image (UBI 9 / C9S / RHEL 9)" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

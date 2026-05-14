workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML development"
        developer = person "Developer" "Contributes code and triggers CI builds via pull requests"

        notebooksDownstream = softwareSystem "Notebooks Downstream" "Builds and publishes ~35 container images for interactive data science workbenches and pipeline runtimes on RHOAI" {
            jupyterImages = container "Jupyter Notebook Images" "JupyterLab workbenches with CPU/CUDA/ROCm variants (minimal, datascience, pytorch, tensorflow, trustyai)" "Container Image (UBI 9)"
            codeServerImage = container "Code Server Image" "VS Code (code-server) in browser with NGINX proxy and supervisord" "Container Image (UBI 9)"
            rstudioImages = container "RStudio Server Images" "RStudio IDE with R 4.4.3, NGINX proxy (C9S/RHEL9 CPU/CUDA variants)" "Container Image (C9S/RHEL 9)"
            runtimeImages = container "Pipeline Runtime Images" "Headless Python environments for Elyra pipeline step execution" "Container Image (UBI 9)"
            buildSystem = container "Build System" "Makefile + Tekton/Konflux pipelines for multi-arch image builds" "GNU Make, Tekton"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions with N through N-5 versioned tags and SHA256 digest pinning" "Kustomize"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Launches workbench images as StatefulSets, injects auth sidecars, manages pod lifecycle" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Reads ImageStream annotations to display available workbench types to users" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Applies kustomize manifests to create/update ImageStreams on cluster" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines / Elyra" "Executes notebook-based pipeline steps using runtime images" "Internal RHOAI"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed training job submission (SDK bundled in images)" "Internal RHOAI"

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster operations" "External"
        quayRegistry = softwareSystem "quay.io/modh" "Container image registry for built images" "External"
        nvidiaRepo = softwareSystem "NVIDIA CUDA Repository" "CUDA toolkit and cuDNN packages for GPU images" "External"
        amdRepo = softwareSystem "AMD ROCm Repository" "ROCm packages for AMD GPU images" "External"
        pypi = softwareSystem "PyPI" "Python package index for dependency installation" "External"
        github = softwareSystem "GitHub" "Source code hosting and PR-triggered CI" "External"

        # User interactions
        dataScientist -> rhoaiDashboard "Selects workbench type" "HTTPS/443"
        dataScientist -> notebooksDownstream "Uses workbench" "HTTPS/443 via HTTPRoute"
        developer -> github "Opens pull request" "HTTPS/443"

        # Platform interactions
        rhodsOperator -> kustomizeManifests "Applies to cluster" "HTTPS/6443"
        rhoaiDashboard -> notebooksDownstream "Reads ImageStream annotations" "HTTPS/6443"
        notebookController -> jupyterImages "Launches as StatefulSet" "Image reference"
        notebookController -> codeServerImage "Launches as StatefulSet" "Image reference"
        notebookController -> rstudioImages "Launches as StatefulSet" "Image reference"
        dsPipelines -> runtimeImages "Executes pipeline steps" "Image reference"

        # Build interactions
        github -> buildSystem "Webhook triggers Konflux build" "HTTPS/443"
        buildSystem -> quayRegistry "Pushes multi-arch images" "HTTPS/443"
        buildSystem -> pypi "Installs Python dependencies" "HTTPS/443"
        buildSystem -> nvidiaRepo "Installs CUDA packages" "HTTPS/443"
        buildSystem -> amdRepo "Installs ROCm packages" "HTTPS/443"

        # Runtime interactions
        jupyterImages -> openshiftAPI "oc CLI commands" "HTTPS/6443"
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

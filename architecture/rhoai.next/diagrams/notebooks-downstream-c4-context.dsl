workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML/data science work"
        developer = person "Developer" "Submits PRs to build new workbench image versions"

        notebooksDownstream = softwareSystem "Notebooks-Downstream" "Builds and publishes ~35 container images for interactive data science workbenches and pipeline runtimes" {
            jupyterImages = container "Jupyter Notebook Images" "JupyterLab workbenches: Minimal, Data Science, PyTorch, TensorFlow, TrustYAI (CPU/CUDA/ROCm)" "Container Images"
            codeServerImage = container "Code Server Image" "VS Code (code-server v4.98.0) in browser with NGINX proxy and supervisord" "Container Image"
            rstudioImages = container "RStudio Server Images" "RStudio Server 2024.12.1 with R 4.4.3 (C9S and RHEL9 variants)" "Container Images"
            runtimeImages = container "Pipeline Runtime Images" "Headless Python environments for Elyra/DSP pipeline step execution" "Container Images"
            buildSystem = container "Build System" "Makefile + Tekton/Konflux pipelines for multi-arch image builds" "Build Tooling"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions with versioned image digest references (N through N-5)" "Kubernetes Manifests"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Launches workbench images as StatefulSets, injects auth sidecars, manages pod lifecycle" "Internal ODH"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Reads ImageStream annotations to display available workbench types to users" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Applies kustomize manifests to create/update ImageStreams on cluster" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines / Elyra" "Executes notebook-based pipeline steps using runtime images" "Internal ODH"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Distributed training job submission (SDK bundled in images)" "Internal ODH"

        quayRegistry = softwareSystem "quay.io/modh" "Container image registry for built workbench and runtime images" "External"
        openShiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster operations" "External"
        nvidiaRuntime = softwareSystem "NVIDIA Container Runtime" "GPU passthrough for CUDA workbenches" "External"
        amdROCm = softwareSystem "AMD ROCm Runtime" "GPU passthrough for AMD GPU workbenches" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD platform running multi-arch image builds on PRs" "External"
        pypi = softwareSystem "PyPI" "Python Package Index for dependency installation" "External"
        ubi9 = softwareSystem "Red Hat UBI 9" "Base operating system image for all UBI9-based workbenches" "External"

        # User interactions
        dataScientist -> rhoaiDashboard "Selects workbench type" "HTTPS/443"
        dataScientist -> notebooksDownstream "Uses workbench (via ingress)" "HTTPS/443 → HTTP/8888"
        developer -> konflux "Submits PR triggering build" "HTTPS/443"

        # Platform interactions
        notebookController -> notebooksDownstream "Launches images as StatefulSets" "K8s API/6443"
        rhoaiDashboard -> notebooksDownstream "Reads ImageStream annotations" "K8s API/6443"
        rhodsOperator -> notebooksDownstream "Applies kustomize manifests" "K8s API/6443"
        dsPipelines -> notebooksDownstream "Runs pipeline steps with runtime images"
        kubeflowTraining -> notebooksDownstream "Training SDK bundled in images"

        # Build and registry
        konflux -> notebooksDownstream "Builds multi-arch images" "Tekton PipelineRun"
        notebooksDownstream -> quayRegistry "Pushes built images" "HTTPS/443"
        notebookController -> quayRegistry "Pulls workbench images" "HTTPS/443"

        # External dependencies
        notebooksDownstream -> ubi9 "Base OS layer"
        notebooksDownstream -> pypi "Python package installation (build-time)" "HTTPS/443"
        notebooksDownstream -> nvidiaRuntime "GPU passthrough (CUDA images)"
        notebooksDownstream -> amdROCm "GPU passthrough (ROCm images)"
        notebooksDownstream -> openShiftAPI "oc CLI commands from workbenches" "HTTPS/6443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                background #d5e8d4
                color #333333
            }
            element "Container Images" {
                background #d5e8d4
                color #333333
            }
            element "Build Tooling" {
                background #f8cecc
                color #333333
            }
            element "Kubernetes Manifests" {
                background #dae8fc
                color #333333
            }
        }
    }
}

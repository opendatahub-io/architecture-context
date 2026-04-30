workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models using interactive workbench environments"
        mlEngineer = person "ML Engineer" "Builds and executes ML pipelines using Elyra and runtime images"

        notebooksDownstream = softwareSystem "Notebooks (Workbench Images)" "Container images for interactive data science environments (Jupyter, Code Server, RStudio) and pipeline runtime images" {
            jupyterMinimal = container "Jupyter Minimal" "Minimal JupyterLab environment with base Python libraries" "Container Image (UBI9 + Python)" "notebook"
            jupyterDataScience = container "Jupyter Data Science" "Full-featured data science notebook with pandas, sklearn, Elyra, DB clients" "Container Image (UBI9 + Python)" "notebook"
            jupyterPyTorch = container "Jupyter PyTorch" "GPU-accelerated notebook with CUDA 12.6.3 + PyTorch" "Container Image (UBI9 + CUDA + Python)" "notebook"
            jupyterTensorFlow = container "Jupyter TensorFlow" "GPU-accelerated notebook with CUDA 12.6.3 + TensorFlow" "Container Image (UBI9 + CUDA + Python)" "notebook"
            jupyterTrustyAI = container "Jupyter TrustyAI" "AI fairness and explainability with TrustyAI + Java 17" "Container Image (UBI9 + Python + Java)" "notebook"
            codeServer = container "Code Server" "VS Code in-browser IDE (v4.98) with NGINX reverse proxy" "Container Image (UBI9 + Node.js)" "notebook"
            rstudio = container "RStudio Server" "R IDE (2024.12) with R 4.4.3, NGINX proxy, supervisord" "Container Image (CentOS Stream 9 + R)" "notebook"
            runtimeMinimal = container "Runtime Minimal" "Lightweight headless Python runtime for pipeline execution" "Container Image (UBI9 + Python)" "runtime"
            runtimePyTorch = container "Runtime PyTorch" "GPU-accelerated headless runtime with CUDA + PyTorch" "Container Image (UBI9 + CUDA + Python)" "runtime"
            runtimeTF = container "Runtime TensorFlow" "GPU-accelerated headless runtime with CUDA + TensorFlow" "Container Image (UBI9 + CUDA + Python)" "runtime"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions for all workbench and runtime images" "YAML/Kustomize" "config"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Creates workbench pods, injects auth sidecars" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and launching workbenches" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys ImageStream manifests" "Internal RHOAI"
        elyra = softwareSystem "Elyra Pipeline Editor" "Visual pipeline editor embedded in data science notebooks" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestrator that launches runtime image pods" "Internal RHOAI"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD system that builds container images" "Internal Build"

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/modh/)" "External"
        pypi = softwareSystem "PyPI" "Python package index" "External"
        cran = softwareSystem "CRAN" "R package repository" "External"
        nvidiaRepo = softwareSystem "NVIDIA CUDA" "CUDA toolkit, cuDNN, NCCL libraries" "External"
        amdROCm = softwareSystem "AMD ROCm" "AMD GPU compute libraries" "External"

        # User interactions
        dataScientist -> notebooksDownstream "Uses workbench images via RHOAI Dashboard"
        mlEngineer -> notebooksDownstream "Executes pipelines using runtime images"

        # Internal platform interactions
        notebookController -> notebooksDownstream "Launches pods + injects kube-rbac-proxy sidecar"
        rhoaiDashboard -> kustomizeManifests "Reads ImageStream annotations for workbench selection UI"
        rhodsOperator -> kustomizeManifests "Deploys ImageStream resources to cluster"
        elyra -> runtimeMinimal "Submits pipeline nodes for execution"
        kfp -> runtimeMinimal "Orchestrates runtime image pods" "Kubernetes API"
        kfp -> runtimePyTorch "Orchestrates GPU runtime pods" "Kubernetes API"
        konflux -> quayRegistry "Publishes built images" "HTTPS/443"

        # Egress from workbenches
        jupyterDataScience -> kubernetesAPI "oc CLI commands" "HTTPS/443"
        jupyterDataScience -> pypi "pip install" "HTTPS/443"
        rstudio -> cran "R package install" "HTTPS/443"

        # Build dependencies
        jupyterPyTorch -> nvidiaRepo "CUDA 12.6.3 + cuDNN 9.5" "Build dependency"
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
            element "Internal Build" {
                background #50e3c2
                color #333333
            }
            element "notebook" {
                background #f5a623
                color #333333
            }
            element "runtime" {
                background #9b59b6
                color #ffffff
            }
            element "config" {
                background #50e3c2
                color #333333
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

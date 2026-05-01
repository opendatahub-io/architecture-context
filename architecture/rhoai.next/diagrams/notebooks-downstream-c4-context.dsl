workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages interactive workbench environments for ML/data science workflows"

        notebooksDownstream = softwareSystem "Notebooks-Downstream" "Container images for interactive data science workbench environments (Jupyter, Code Server, RStudio) and pipeline runtime images" {
            jupyterMinimal = container "Jupyter Minimal" "Minimal JupyterLab environment with base Python libraries" "UBI9 + Python 3.11/3.12"
            jupyterDS = container "Jupyter Data Science" "Full-featured JupyterLab with data science libraries, Elyra, DB clients" "UBI9 + Python 3.11/3.12"
            jupyterPyTorch = container "Jupyter PyTorch" "GPU-accelerated JupyterLab with CUDA + PyTorch" "UBI9 + CUDA 12.6.3"
            jupyterTF = container "Jupyter TensorFlow" "GPU-accelerated JupyterLab with CUDA + TensorFlow" "UBI9 + CUDA 12.6.3"
            jupyterTrustyAI = container "Jupyter TrustyAI" "JupyterLab with TrustyAI library and Java 17" "UBI9 + Python + Java 17"
            codeServer = container "Code Server" "VS Code in-browser IDE with NGINX reverse proxy" "code-server v4.98 + NGINX"
            rstudio = container "RStudio Server" "RStudio IDE with R 4.4.3 and NGINX reverse proxy" "RStudio 2024.12 + NGINX"
            runtimeMinimal = container "Runtime Minimal" "Lightweight Python runtime for pipeline node execution" "UBI9 + Python (headless)"
            runtimePyTorch = container "Runtime PyTorch" "GPU pipeline runtime with CUDA + PyTorch" "UBI9 + CUDA 12.6.3 (headless)"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions for all workbench and runtime images" "Kustomize YAML"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Creates workbench pods and injects authentication sidecars" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "UI for selecting and launching workbench environments" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests to the cluster" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Pipeline orchestrator for ML workflow execution" "Internal RHOAI"
        elyra = softwareSystem "Elyra Pipeline Editor" "Visual pipeline editor embedded in Data Science notebook" "Internal RHOAI"

        k8sAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes cluster API server" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/modh)" "External"
        pypi = softwareSystem "PyPI" "Python package repository" "External"
        cran = softwareSystem "CRAN" "R package repository" "External"
        userDatabases = softwareSystem "User Databases" "MongoDB, MSSQL, PostgreSQL instances" "External"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD pipeline for building container images" "External"

        # Relationships
        dataScientist -> rhoaiDashboard "Selects workbench type via UI"
        rhoaiDashboard -> notebooksDownstream "Reads ImageStream annotations" "Kubernetes API"
        notebookController -> notebooksDownstream "Creates pods using these images" "Kubernetes API"
        rhodsOperator -> kustomizeManifests "Deploys ImageStream resources" "Kubernetes API"

        dataScientist -> notebooksDownstream "Uses workbench IDE" "HTTPS/443 via Gateway"

        jupyterDS -> elyra "Embeds pipeline editor" "in-process"
        elyra -> kubeflowPipelines "Submits pipeline runs" "HTTPS/443"
        kubeflowPipelines -> runtimeMinimal "Launches runtime pods" "Kubernetes API"
        kubeflowPipelines -> runtimePyTorch "Launches GPU runtime pods" "Kubernetes API"

        notebooksDownstream -> k8sAPI "oc CLI commands" "HTTPS/443"
        notebooksDownstream -> pypi "pip install packages" "HTTPS/443"
        notebooksDownstream -> cran "R package installation" "HTTPS/443"
        notebooksDownstream -> userDatabases "Database queries" "Various protocols"

        konflux -> notebooksDownstream "Builds container images" "Tekton Pipeline"
        notebooksDownstream -> quayRegistry "Published images" "HTTPS/443"
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

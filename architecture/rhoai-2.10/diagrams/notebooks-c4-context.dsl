workspace {
    model {
        user = person "Data Scientist" "Develops and trains ML models using interactive notebooks and code environments"

        notebooks = softwareSystem "Notebook Workbench Images" "Pre-built container images for Jupyter notebooks, RStudio, and VS Code workbenches with ML frameworks" {
            baseImages = container "Base Images" "UBI9/UBI8 Python base with oc CLI and core packages" "Container Images"
            jupyterImages = container "Jupyter Images" "JupyterLab 3.x with data science libraries and ML frameworks" "Container Images"
            specializedImages = container "Specialized Images" "GPU-accelerated (CUDA, Intel GPU, Habana) notebook images" "Container Images"
            alternativeIDEs = container "Alternative IDEs" "Code Server (VS Code) and RStudio Server" "Container Images"
            runtimeImages = container "Runtime Images" "Lightweight images for Elyra pipeline execution" "Container Images"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Creates and manages notebook workbench pods using StatefulSets" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for users to select and launch notebook workbenches" "Internal ODH"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration and execution platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" "Internal ODH"

        k8s = softwareSystem "Kubernetes API" "OpenShift/Kubernetes cluster API server" "External"
        s3 = softwareSystem "S3 Object Storage" "Dataset and model artifact storage (AWS S3 or Minio)" "External"
        quay = softwareSystem "Quay.io Registry" "Container image registry for storing and distributing notebook images" "External"
        pypi = softwareSystem "PyPI/Conda" "Python package repositories for runtime package installation" "External"
        git = softwareSystem "Git Repositories" "Source code repositories (GitHub, GitLab)" "External"

        # User interactions
        user -> dashboard "Selects notebook image and launches workbench" "HTTPS/443"
        user -> jupyterImages "Develops and trains models via web browser" "HTTPS/443"
        user -> alternativeIDEs "Codes in VS Code or R via web browser" "HTTPS/443"

        # ODH Component interactions
        notebookController -> jupyterImages "Creates StatefulSets using images" "Kubernetes API"
        notebookController -> alternativeIDEs "Creates StatefulSets using images" "Kubernetes API"
        dashboard -> notebookController "Queries ImageStreams for available images" "Kubernetes API"
        kfp -> runtimeImages "Executes pipeline steps in runtime containers" "Kubernetes API"

        # Notebook to external services
        jupyterImages -> k8s "Executes oc CLI commands" "HTTPS/6443"
        jupyterImages -> s3 "Reads/writes datasets and model artifacts" "HTTPS/443, AWS SigV4"
        jupyterImages -> pypi "Installs additional Python packages at runtime" "HTTPS/443"
        jupyterImages -> git "Clones repositories into workspace" "HTTPS/443, SSH"
        jupyterImages -> modelRegistry "Registers trained models" "gRPC/9090 (via SDK)"

        # Runtime to external services
        runtimeImages -> s3 "Reads input data and writes pipeline artifacts" "HTTPS/443, AWS SigV4"
        runtimeImages -> k8s "Accesses cluster resources" "HTTPS/6443"

        # Image registry
        quay -> baseImages "Provides UBI base images" "HTTPS/443"
        quay -> jupyterImages "Stores built images for deployment" "HTTPS/443"
        quay -> specializedImages "Stores GPU-accelerated images" "HTTPS/443"
        quay -> alternativeIDEs "Stores Code Server and RStudio images" "HTTPS/443"
        quay -> runtimeImages "Stores runtime images" "HTTPS/443"

        # Build chain relationships
        baseImages -> jupyterImages "Base layer for Jupyter images" "Build dependency"
        jupyterImages -> specializedImages "Base layer for specialized images" "Build dependency"
        baseImages -> alternativeIDEs "Base layer for IDEs" "Build dependency"
        baseImages -> runtimeImages "Base layer for runtime images" "Build dependency"
    }

    views {
        systemContext notebooks "NotebooksSystemContext" {
            include *
            autoLayout
        }

        container notebooks "NotebooksContainers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container Images" {
                background #4a90e2
                color #ffffff
            }
        }

        themes default
    }

    configuration {
        scope softwaresystem
    }
}

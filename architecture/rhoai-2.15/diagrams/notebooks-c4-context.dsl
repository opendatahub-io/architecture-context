workspace {
    model {
        # People
        dataScientist = person "Data Scientist" "Creates and trains ML models using interactive notebooks"
        mlEngineer = person "ML Engineer" "Develops and runs ML pipelines using runtime images"

        # Main System
        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides pre-built container images for data science workbenches including Jupyter notebooks, RStudio, and VS Code Server" {
            # Containers
            baseImages = container "Base Images" "Foundation images with Python runtime and OS packages" "UBI9/RHEL9/C9S"
            jupyterImages = container "Jupyter Notebooks" "Full-featured JupyterLab environments" "JupyterLab 3.x/4.2"
            runtimeImages = container "Runtime Images" "Lightweight images for Elyra pipeline execution" "Python + Elyra"
            codeServerImages = container "Code Server" "VS Code web-based IDE environment" "Code Server 4.x"
            rstudioImages = container "RStudio Server" "R-based IDE for statistical computing" "RStudio"
            gpuImages = container "GPU-Accelerated Images" "CUDA/ROCm/Intel/Habana-optimized images" "CUDA/ROCm"
            buildSystem = container "Build System" "Multi-stage build pipeline with dependency management" "Makefile/Podman"
        }

        # Internal ODH/RHOAI Systems
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Notebook CR lifecycle and creates StatefulSet/Pods" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for discovering and launching notebook workbenches" "Internal ODH"
        oauthProxy = softwareSystem "OAuth Proxy" "Provides authentication and authorization for notebook access" "Internal ODH"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Caches and serves container images within the cluster" "Internal ODH"
        elyraService = softwareSystem "Elyra Pipeline Service" "Executes runtime images as pipeline tasks" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores and versions ML models trained in notebooks" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Orchestrates automated ML workflows using runtime images" "Internal ODH"

        # External Systems
        ubi9 = softwareSystem "Red Hat UBI9" "Universal Base Image providing security-hardened container foundation" "External"
        python = softwareSystem "Python" "Python runtime and package ecosystem" "External"
        jupyterLab = softwareSystem "JupyterLab" "Web-based interactive development environment" "External"
        pyTorch = softwareSystem "PyTorch" "Deep learning framework" "External"
        tensorFlow = softwareSystem "TensorFlow" "Deep learning framework" "External"
        cuda = softwareSystem "NVIDIA CUDA" "GPU acceleration libraries for NVIDIA GPUs" "External"
        rocm = softwareSystem "AMD ROCm" "GPU acceleration libraries for AMD GPUs" "External"
        pypi = softwareSystem "PyPI" "Python Package Index for installing packages" "External Service"
        quayIO = softwareSystem "Quay.io" "Container image registry hosting notebook images" "External Service"
        s3Storage = softwareSystem "S3 Storage" "Object storage for data and model artifacts" "External Service"
        gitServers = softwareSystem "GitHub/GitLab" "Version control for notebooks and code" "External Service"
        k8sAPI = softwareSystem "OpenShift API" "Kubernetes API for cluster operations" "Cluster Service"

        # Relationships - Users to Systems
        dataScientist -> dashboard "Selects and launches notebook workbenches"
        dataScientist -> notebooks "Develops ML models using JupyterLab/RStudio/Code Server"
        mlEngineer -> dsPipelines "Creates ML pipelines using Elyra"

        # Relationships - Notebooks Internal
        buildSystem -> baseImages "Builds foundation images"
        baseImages -> jupyterImages "Extends to create Jupyter environments"
        baseImages -> runtimeImages "Extends to create pipeline runtimes"
        baseImages -> codeServerImages "Extends to create Code Server IDE"
        baseImages -> rstudioImages "Extends to create RStudio IDE"
        baseImages -> gpuImages "Extends with GPU acceleration"

        # Relationships - External Dependencies
        baseImages -> ubi9 "Based on Red Hat UBI9" "Container inheritance"
        jupyterImages -> python "Includes Python runtime" "Package"
        jupyterImages -> jupyterLab "Includes JupyterLab UI" "Package"
        jupyterImages -> pyTorch "Includes PyTorch framework (optional)" "Package"
        jupyterImages -> tensorFlow "Includes TensorFlow framework (optional)" "Package"
        gpuImages -> cuda "Includes NVIDIA CUDA libraries" "Package"
        gpuImages -> rocm "Includes AMD ROCm libraries" "Package"

        # Relationships - ODH Integration
        buildSystem -> quayIO "Publishes images to registry" "HTTPS/443"
        imageRegistry -> quayIO "Pulls images from Quay.io" "HTTPS/443"
        dashboard -> imageRegistry "Discovers available notebook images via ImageStream annotations" "Kubernetes API"
        notebookController -> imageRegistry "Pulls images to create notebook pods" "HTTP/5000"
        notebookController -> notebooks "Creates StatefulSet/Pod with workbench images" "Kubernetes API"
        notebookController -> oauthProxy "Injects OAuth proxy sidecar for authentication" "Pod injection"
        elyraService -> runtimeImages "Executes pipeline tasks using runtime images" "Pod execution"
        dsPipelines -> runtimeImages "Runs ML workflow steps using runtime images" "Pod execution"

        # Relationships - Notebook Runtime
        jupyterImages -> pypi "Installs Python packages at runtime" "HTTPS/443"
        jupyterImages -> s3Storage "Loads training data and stores model artifacts" "HTTPS/443 S3 API"
        jupyterImages -> gitServers "Clones repositories and commits notebooks" "HTTPS/443, SSH/22"
        jupyterImages -> modelRegistry "Registers trained models" "HTTP/8080 mTLS"
        jupyterImages -> k8sAPI "Executes cluster operations via oc/kubectl" "HTTPS/6443"
        runtimeImages -> s3Storage "Reads/writes data during pipeline execution" "HTTPS/443 S3 API"
        runtimeImages -> k8sAPI "Reports pipeline task status" "HTTPS/6443"

        # User access flow
        dataScientist -> oauthProxy "Authenticates via OpenShift OAuth" "HTTPS/443"
        oauthProxy -> jupyterImages "Proxies authenticated requests to JupyterLab" "HTTP/8888"
    }

    views {
        systemContext notebooks "NotebooksSystemContext" {
            include *
            autoLayout lr
        }

        container notebooks "NotebooksContainers" {
            include *
            autoLayout lr
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #abd9e9
                color #000000
            }
            element "Cluster Service" {
                background #e0e0e0
                color #000000
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

        theme default
    }
}

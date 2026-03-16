workspace {
    model {
        dataScientist = person "Data Scientist" "Develops ML models and analyzes data using interactive workbenches"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines using runtime images"

        notebooksSystem = softwareSystem "Notebooks (Workbench Images)" "Provides pre-built container images for data science workbenches including Jupyter, code-server, and RStudio environments" {
            jupyterImages = container "Jupyter Workbenches" "JupyterLab-based interactive notebooks" "Container Images" {
                jupyterMinimal = component "Jupyter Minimal" "Basic notebook environment" "Python 3.9/3.11"
                jupyterDataScience = component "Jupyter Data Science" "Pandas, NumPy, scikit-learn" "Python 3.9/3.11"
                jupyterPyTorch = component "Jupyter PyTorch" "Deep learning with PyTorch" "Python 3.9/3.11"
                jupyterTensorFlow = component "Jupyter TensorFlow" "Deep learning with TensorFlow" "Python 3.9/3.11"
                jupyterTrustyAI = component "Jupyter TrustyAI" "Explainable AI and model monitoring" "Python 3.9/3.11"
            }

            acceleratorImages = container "Hardware Accelerator Images" "Specialized images with GPU support" "Container Images" {
                jupyterIntel = component "Intel GPU Jupyter" "Intel oneAPI optimized" "Python 3.9/3.11"
                jupyterROCm = component "ROCm Jupyter" "AMD GPU optimized" "Python 3.9/3.11"
                jupyterHabana = component "Habana Jupyter" "Habana Gaudi accelerator" "Python 3.9/3.11"
            }

            alternativeWorkbenches = container "Alternative Workbenches" "VS Code and RStudio environments" "Container Images" {
                codeServer = component "code-server" "VS Code in browser" "Node.js"
                rstudio = component "RStudio Server" "R development environment" "R"
            }

            runtimeImages = container "Runtime Images" "Lightweight images for pipeline execution" "Container Images" {
                runtimeMinimal = component "Runtime Minimal" "Basic Python execution" "Python 3.9/3.11"
                runtimeDataScience = component "Runtime Data Science" "Data science libraries" "Python 3.9/3.11"
                runtimePyTorch = component "Runtime PyTorch" "PyTorch for pipelines" "Python 3.9/3.11"
            }

            baseImages = container "Base Images" "Foundation images with Python" "Container Images"
            imageStreamManifests = container "ImageStream Manifests" "Kubernetes resource definitions" "YAML"
            elyraBootstrapper = container "Elyra Bootstrapper" "Pipeline execution runtime" "Python Script"
        }

        odhController = softwareSystem "ODH Notebook Controller" "Manages workbench lifecycle and pod creation" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Provides UI for users to select and launch workbenches" "Internal ODH"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Distributes and versions workbench images" "Internal ODH"
        kfp = softwareSystem "Kubeflow Pipelines" "Orchestrates ML pipeline execution using runtime images" "Internal ODH"
        objectStorage = softwareSystem "Object Storage" "Stores pipeline artifacts and dependencies" "Internal ODH"

        jupyterLab = softwareSystem "JupyterLab" "Interactive notebook environment" "External"
        codeServerExternal = softwareSystem "code-server" "VS Code web interface" "External"
        rstudioExternal = softwareSystem "RStudio Server" "R development environment" "External"
        python = softwareSystem "Python" "Runtime environment and kernel" "External"
        nginx = softwareSystem "NGINX" "Reverse proxy for code-server" "External"
        elyra = softwareSystem "Elyra" "Pipeline execution support" "External"
        papermill = softwareSystem "Papermill" "Notebook parameterization and execution" "External"
        minioClient = softwareSystem "Minio Client" "Object storage integration" "External"

        cuda = softwareSystem "CUDA Toolkit" "NVIDIA GPU support" "External"
        rocm = softwareSystem "ROCm" "AMD GPU support" "External"
        intelAPI = softwareSystem "Intel oneAPI" "Intel GPU support" "External"
        habana = softwareSystem "Habana SDK" "Habana Gaudi accelerator support" "External"

        containerRegistry = softwareSystem "Container Registry" "Stores and distributes container images" "External"
        packageRepos = softwareSystem "PyPI/Conda" "Python and R package repositories" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster orchestration and management" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress routing and TLS termination" "External"

        // User interactions
        dataScientist -> odhDashboard "Selects and launches workbench via UI"
        dataScientist -> jupyterImages "Develops models in Jupyter notebooks" "HTTPS/443"
        dataScientist -> alternativeWorkbenches "Develops code in VS Code/RStudio" "HTTPS/443"
        mlEngineer -> kfp "Creates and executes ML pipelines"

        // Platform interactions
        odhDashboard -> imageStreams "Reads ImageStream metadata to display available workbenches"
        odhController -> notebooksSystem "Creates pods using workbench images via StatefulSet" "Kubernetes API"
        odhController -> jupyterImages "Launches Jupyter pods"
        odhController -> alternativeWorkbenches "Launches code-server/RStudio pods"
        imageStreams -> containerRegistry "Pulls images from registry" "HTTPS/443"

        // Pipeline execution
        kfp -> runtimeImages "Executes runtime images as pipeline nodes" "Container execution"
        runtimeImages -> objectStorage "Uploads/downloads pipeline artifacts" "S3 API HTTPS/443 or HTTP/9000"
        elyraBootstrapper -> objectStorage "Manages pipeline dependencies and outputs" "S3 API HTTPS/443 or HTTP/9000"

        // External dependencies
        jupyterImages -> jupyterLab "Uses JupyterLab 4.2/3.6"
        alternativeWorkbenches -> codeServerExternal "Uses code-server 4.92.2"
        alternativeWorkbenches -> rstudioExternal "Uses RStudio Server"
        notebooksSystem -> python "Runtime environment Python 3.9/3.11"
        alternativeWorkbenches -> nginx "Reverse proxy NGINX 1.24"
        runtimeImages -> elyra "Pipeline execution with Elyra bootstrapper"
        runtimeImages -> papermill "Notebook execution with Papermill"
        runtimeImages -> minioClient "Object storage client"

        // Hardware accelerators
        acceleratorImages -> cuda "NVIDIA GPU support"
        acceleratorImages -> rocm "AMD GPU support"
        acceleratorImages -> intelAPI "Intel GPU support"
        acceleratorImages -> habana "Habana Gaudi support"

        // Infrastructure
        notebooksSystem -> containerRegistry "Pulls dependent images during build" "HTTPS/443"
        jupyterImages -> packageRepos "Installs Python packages at runtime" "HTTPS/443"
        runtimeImages -> packageRepos "Installs pipeline dependencies" "HTTPS/443"
        odhController -> k8sAPI "Manages workbench pods and resources"
        dataScientist -> openShiftRouter "Accesses workbenches via HTTPS" "HTTPS/443"
        openShiftRouter -> jupyterImages "Routes traffic to Jupyter pods" "HTTP/8888"
        openShiftRouter -> alternativeWorkbenches "Routes traffic to code-server/RStudio" "HTTP/8080"
    }

    views {
        systemContext notebooksSystem "SystemContext" {
            include *
            autoLayout lr
        }

        container notebooksSystem "Containers" {
            include *
            autoLayout tb
        }

        component jupyterImages "JupyterWorkbenches" {
            include *
            autoLayout lr
        }

        component runtimeImages "RuntimeImages" {
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
            element "Container Images" {
                background #4a90e2
                color #ffffff
            }
            element "Python 3.9/3.11" {
                background #4a90e2
                color #ffffff
            }
            element "Node.js" {
                background #4a90e2
                color #ffffff
            }
            element "R" {
                background #4a90e2
                color #ffffff
            }
            element "YAML" {
                background #f5a623
                color #000000
            }
            element "Python Script" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}

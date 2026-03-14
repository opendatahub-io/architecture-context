workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML experiments in workbench environments"
        mlEngineer = person "ML Engineer" "Builds and executes ML pipelines using runtime images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Container image repository providing JupyterLab, VS Code, and RStudio workbench environments for data science workflows" {
            jupyterImages = container "Jupyter Workbench Images" "Interactive notebook environments with JupyterLab 4.4" "Container Images" {
                tags "Workbench"
            }
            codeserverImages = container "Code Server Images" "VS Code-based development environments" "Container Images" {
                tags "Workbench"
            }
            rstudioImages = container "RStudio Images" "RStudio Server environments for R development" "Container Images" {
                tags "Workbench"
            }
            runtimeImages = container "Runtime Images" "Lightweight images for Kubeflow Pipelines tasks" "Container Images" {
                tags "Runtime"
            }
            buildPipelines = container "Konflux Build Pipelines" "Multi-arch container image builds" "Tekton/Konflux" {
                tags "Build"
            }
        }

        # External dependencies
        ubi9 = softwareSystem "UBI9 Python Base Image" "Universal Base Image 9 with Python 3.11/3.12 runtime" "External"
        cudaBase = softwareSystem "CUDA Base Image" "NVIDIA CUDA 12.6/12.8 GPU support" "External"
        rocmBase = softwareSystem "ROCm Base Image" "AMD ROCm 6.2/6.4 GPU support" "External"
        jupyterlab = softwareSystem "JupyterLab" "Interactive notebook interface (4.4)" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework (2.x)" "External"
        tensorflow = softwareSystem "TensorFlow" "Deep learning framework (2.x)" "External"

        # Internal ODH dependencies
        notebookController = softwareSystem "ODH Notebook Controller" "Launches and manages workbench pods" "Internal ODH" {
            tags "ODH"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal ODH" {
            tags "ODH"
        }
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration" "Internal ODH" {
            tags "ODH"
        }
        imageStreams = softwareSystem "OpenShift ImageStreams" "Container image registry and references" "Internal ODH" {
            tags "ODH"
        }

        # External services
        s3Storage = softwareSystem "S3 Storage" "Object storage for data and model artifacts" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image storage and distribution" "External"
        github = softwareSystem "GitHub" "Source code repository" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Selects workbench image and launches notebook"
        dataScientist -> jupyterImages "Runs Jupyter notebooks and ML experiments" "HTTPS/8888 (via OAuth proxy)"
        dataScientist -> codeserverImages "Develops Python code in VS Code" "HTTPS/8080 (via OAuth proxy)"
        dataScientist -> rstudioImages "Develops R code in RStudio" "HTTPS/8787 (via OAuth proxy)"
        mlEngineer -> kubeflowPipelines "Creates and executes ML pipelines"

        # Relationships - Notebook Controller
        notebookController -> jupyterImages "Launches workbench pods using images" "ImageStream reference"
        notebookController -> codeserverImages "Launches workbench pods using images" "ImageStream reference"
        notebookController -> rstudioImages "Launches workbench pods using images" "ImageStream reference"

        # Relationships - Dashboard
        odhDashboard -> imageStreams "Queries available workbench images" "Kubernetes API/6443 HTTPS"

        # Relationships - Pipelines
        kubeflowPipelines -> runtimeImages "Executes pipeline tasks in containers" "Container execution"

        # Relationships - ImageStreams
        imageStreams -> quayRegistry "Pulls container images" "HTTPS/443"

        # Relationships - Build
        buildPipelines -> github "Clones source code" "HTTPS/443, Git token"
        buildPipelines -> ubi9 "Pulls base images" "HTTPS/443, Pull secret"
        buildPipelines -> cudaBase "Pulls CUDA base images" "HTTPS/443, Pull secret"
        buildPipelines -> rocmBase "Pulls ROCm base images" "HTTPS/443, Pull secret"
        buildPipelines -> quayRegistry "Pushes built images" "HTTPS/443, Push secret"

        # Relationships - Framework dependencies
        jupyterImages -> jupyterlab "Includes JupyterLab interface"
        jupyterImages -> pytorch "Includes PyTorch framework (CUDA/ROCm variants)"
        jupyterImages -> tensorflow "Includes TensorFlow framework (CUDA/ROCm variants)"
        runtimeImages -> pytorch "Includes PyTorch (runtime variants)"
        runtimeImages -> tensorflow "Includes TensorFlow (runtime variants)"

        # Relationships - Data access
        jupyterImages -> s3Storage "Reads/writes data and model artifacts" "HTTPS/443, S3 credentials"
        codeserverImages -> s3Storage "Reads/writes data" "HTTPS/443, S3 credentials"
        rstudioImages -> s3Storage "Reads/writes data" "HTTPS/443, S3 credentials"
        runtimeImages -> s3Storage "Reads/writes pipeline artifacts" "HTTPS/443, AWS SigV4"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Notebooks (Workbench Images)"
        }

        container notebooks "Containers" {
            include *
            autoLayout tb
            description "Container diagram showing workbench and runtime images"
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
            element "ODH" {
                background #7ed321
                color #000000
            }
            element "Workbench" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #000000
            }
            element "Build" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

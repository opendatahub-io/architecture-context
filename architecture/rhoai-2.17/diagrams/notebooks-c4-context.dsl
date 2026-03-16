workspace {
    model {
        user = person "Data Scientist" "Develops and executes ML/data science workflows"
        admin = person "Platform Administrator" "Deploys and configures workbench images"

        notebooks = softwareSystem "Workbench Images (Notebooks)" "Pre-configured container images for data science development" {
            baseImages = container "Base Images" "Foundation images with Python on UBI9/RHEL9" "Container Images"
            jupyterImages = container "Jupyter Workbenches" "JupyterLab-based development environments" "Container Images"
            gpuImages = container "GPU Workbenches" "GPU-accelerated workbench variants (CUDA/ROCm/Intel)" "Container Images"
            ideImages = container "IDE Workbenches" "Code Server and RStudio environments" "Container Images"
            runtimeImages = container "Runtime Images" "Headless execution images for pipelines" "Container Images"
            imageStreams = container "ImageStreams" "Kubernetes ImageStream resources referencing images" "OpenShift Resources"
            buildConfigs = container "BuildConfigs" "RStudio build definitions" "OpenShift Resources"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Spawns and manages workbench pods" "Internal ODH"
        dashboard = softwareSystem "odh-dashboard" "Displays available workbench options to users" "Internal ODH"
        quayRegistry = softwareSystem "Quay.io" "Container image registry for pre-built images" "External"
        internalRegistry = softwareSystem "OpenShift Internal Registry" "Cluster-internal image storage" "External"
        pypi = softwareSystem "PyPI/Conda" "Python package repositories" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for data and models" "External"
        git = softwareSystem "Git Repositories" "Source code management" "External"

        user -> dashboard "Selects workbench image and spawns environment"
        dashboard -> imageStreams "Reads annotations to display options"
        user -> notebookController "Creates workbench via UI"
        notebookController -> imageStreams "Pulls images to spawn pods"
        admin -> buildConfigs "Configures RStudio builds"

        baseImages -> jupyterImages "Base for Jupyter variants"
        baseImages -> gpuImages "Base for GPU variants"
        baseImages -> ideImages "Base for IDE variants"
        baseImages -> runtimeImages "Base for runtime variants"

        jupyterImages -> imageStreams "Referenced by ImageStreams"
        gpuImages -> imageStreams "Referenced by ImageStreams"
        ideImages -> imageStreams "Referenced by ImageStreams"
        runtimeImages -> imageStreams "Referenced by ImageStreams"

        buildConfigs -> internalRegistry "Pushes built RStudio images" "HTTPS/5000"
        imageStreams -> quayRegistry "Pulls pre-built images" "HTTPS/443"
        imageStreams -> internalRegistry "Pulls built images" "HTTPS/5000"

        jupyterImages -> pypi "Installs Python packages" "HTTPS/443"
        jupyterImages -> s3 "Accesses data and models" "HTTPS/443"
        jupyterImages -> git "Clones repositories" "HTTPS/443"
        ideImages -> git "Manages source code" "HTTPS/443"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout
        }

        container notebooks "Containers" {
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
                color #000000
            }
            element "Container Images" {
                background #4a90e2
                color #ffffff
            }
            element "OpenShift Resources" {
                background #e8e8e8
                color #000000
            }
        }
    }
}

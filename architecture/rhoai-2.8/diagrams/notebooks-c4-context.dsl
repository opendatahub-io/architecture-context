workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs data science notebooks, develops ML models, and executes pipelines"
        developer = person "Developer" "Uses Code Server or RStudio for interactive development"

        notebooks = softwareSystem "Notebook Workbench Images" "Provides container image build definitions for Jupyter notebook and IDE workbench images used in Red Hat OpenShift AI" {
            baseImages = container "Base Images" "Minimal Python environments with OpenShift client (oc) and pip" "UBI8/UBI9/RHEL9/CentOS Stream 9"
            jupyterNotebooks = container "Jupyter Notebooks" "JupyterLab-based workbench images with data science libraries" "Python + JupyterLab 3.6"
            cudaNotebooks = container "CUDA Notebooks" "GPU-accelerated notebook variants with NVIDIA CUDA runtime" "CUDA + Python"
            runtimeImages = container "Runtime Images" "Lightweight Elyra-compatible pipeline execution containers" "Python + Elyra"
            ideImages = container "IDE Images" "Alternative IDE workbenches (VS Code, RStudio)" "Code Server 4.x, RStudio Server"
            imageStreams = container "ImageStream Manifests" "OpenShift ImageStream definitions for notebook image deployment" "Kubernetes YAML"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages notebook pod lifecycle and resource provisioning" "External ODH Component"
        dashboard = softwareSystem "ODH Dashboard" "Provides notebook image selection and spawning UI" "Internal ODH"
        oauthProxy = softwareSystem "OAuth Proxy" "Authenticates notebook access via OpenShift OAuth" "Internal ODH"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines integration for ML workflows" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and versioning information" "Internal ODH"

        ubi = softwareSystem "UBI/RHEL Base Images" "Red Hat Universal Base Images and RHEL container images" "External - Red Hat"
        nvidia = softwareSystem "NVIDIA CUDA" "GPU acceleration runtime and libraries" "External - NVIDIA"
        jupyterProject = softwareSystem "Jupyter Project" "JupyterLab and Jupyter Server components" "External - PyPI"
        elyraProject = softwareSystem "Elyra" "Visual pipeline editor and code snippet extensions" "External - PyPI"
        codeServerProject = softwareSystem "Code Server" "VS Code browser implementation" "External - GitHub"
        rstudioProject = softwareSystem "RStudio" "R IDE server component" "External - RStudio"

        s3Storage = softwareSystem "S3 Storage" "Object storage for data and model artifacts" "External - AWS/MinIO"
        gitRepos = softwareSystem "Git Repositories" "Source code version control (GitHub, GitLab)" "External"
        containerRegistry = softwareSystem "Container Registry" "Quay.io for publishing notebook images" "External - Quay.io"
        pypi = softwareSystem "PyPI" "Python package repository" "External"
        databases = softwareSystem "Databases" "PostgreSQL, MySQL, MongoDB, MS SQL" "External"
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server" "External - OpenShift"

        # User interactions
        dataScientist -> notebooks "Selects and uses Jupyter notebook images for ML development"
        developer -> notebooks "Uses Code Server or RStudio images for interactive development"

        # Notebook component relationships
        baseImages -> jupyterNotebooks "Base layer for Jupyter images"
        baseImages -> cudaNotebooks "Base layer for CUDA images"
        baseImages -> runtimeImages "Base layer for runtime images"
        baseImages -> ideImages "Base layer for IDE images"
        cudaNotebooks -> jupyterNotebooks "GPU-accelerated variants"
        imageStreams -> notebookController "Deployed via ImageStream selections"

        # ODH integration
        notebooks -> notebookController "Launched as notebook pods by controller"
        notebooks -> dashboard "Image selection interface"
        notebooks -> oauthProxy "Authentication sidecar integration"
        notebooks -> dataSciencePipelines "Integrates via kfp-tekton SDK and runtime images"
        notebooks -> modelRegistry "Connects via boto3 S3 client"

        # External dependencies
        notebooks -> ubi "Uses as base OS images" "Container build"
        notebooks -> nvidia "Uses for GPU acceleration" "Container build"
        notebooks -> jupyterProject "Installs JupyterLab and Jupyter Server" "pip/PyPI"
        notebooks -> elyraProject "Installs Elyra extensions" "pip/PyPI"
        notebooks -> codeServerProject "Embeds Code Server" "Binary download"
        notebooks -> rstudioProject "Embeds RStudio Server" "Package install"

        # Runtime interactions
        notebooks -> s3Storage "Accesses data and model artifacts" "HTTPS/443 - boto3"
        notebooks -> gitRepos "Clones and pushes code repositories" "HTTPS/443 or SSH/22"
        notebooks -> containerRegistry "Publishes built images" "Docker Registry API v2"
        notebooks -> pypi "Installs user Python packages" "HTTPS/443 - pip"
        notebooks -> databases "Connects from notebooks" "PostgreSQL/MySQL/MongoDB protocols"
        notebooks -> k8sAPI "Manages resources via oc CLI" "HTTPS/6443"

        # Dashboard integration
        dashboard -> notebookController "Triggers notebook pod creation"
        oauthProxy -> k8sAPI "Validates user permissions"
        dataSciencePipelines -> runtimeImages "Executes runtime images in pipelines"
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
            element "External ODH Component" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External - Red Hat" {
                background #ee0000
                color #ffffff
            }
            element "External - NVIDIA" {
                background #76b900
                color #ffffff
            }
            element "External - PyPI" {
                background #3775a9
                color #ffffff
            }
            element "External - GitHub" {
                background #333333
                color #ffffff
            }
            element "External - RStudio" {
                background #75aadb
                color #ffffff
            }
            element "External - AWS/MinIO" {
                background #ff9900
                color #000000
            }
            element "External - Quay.io" {
                background #40b4e5
                color #ffffff
            }
            element "External - OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "External" {
                background #cccccc
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

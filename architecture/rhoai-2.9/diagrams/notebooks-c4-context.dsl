workspace {
    model {
        user = person "Data Scientist" "Creates and trains ML models using interactive notebooks and IDEs"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Pre-configured notebook and IDE workbench container images for data science and ML workflows" {
            jupyterImages = container "Jupyter Images" "Interactive JupyterLab environments" "Python, JupyterLab" {
                minimal = component "Jupyter Minimal" "Lightweight Python 3.8/3.9 environment" "Container Image"
                datascience = component "Jupyter Data Science" "ML libraries + database clients" "Container Image"
                tensorflow = component "Jupyter TensorFlow" "Deep learning with TensorFlow" "Container Image"
                pytorch = component "Jupyter PyTorch" "Deep learning with PyTorch" "Container Image"
                trustyai = component "Jupyter TrustyAI" "Model explainability tools" "Container Image"
            }

            acceleratedImages = container "Hardware-Accelerated Images" "GPU and accelerator-optimized images" "CUDA, Habana SDK, Intel GPU" {
                cuda = component "CUDA Images" "NVIDIA GPU acceleration" "Container Image"
                habana = component "Habana AI Images" "Habana Gaudi accelerators" "Container Image"
                intelgpu = component "Intel GPU Images" "Intel GPU acceleration" "Container Image"
            }

            ideImages = container "Alternative IDE Images" "Non-Jupyter development environments" "VS Code, RStudio" {
                codeserver = component "Code Server" "Browser-based VS Code" "Container Image"
                rstudio = component "RStudio Server" "R IDE" "Container Image"
            }

            runtimeImages = container "Runtime Images" "Headless pipeline execution environments" "Python, Elyra"

            imageManagement = container "Image Management" "Version control and distribution" "OpenShift ImageStreams" {
                imagestreams = component "ImageStreams" "N/N-1/N-2 version management" "OpenShift CR"
                configmaps = component "ConfigMaps" "Image digest tracking" "Kubernetes CR"
            }

            oauthProxy = container "OAuth Proxy" "Authentication sidecar" "Go Service"
        }

        # ODH Platform Components
        dashboard = softwareSystem "ODH Dashboard" "Web UI for workbench selection and management" "Internal ODH"
        notebookController = softwareSystem "Notebook Controller" "Manages notebook StatefulSet lifecycle" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores trained model metadata and versions" "Internal ODH"
        kfp = softwareSystem "Kubeflow Pipelines" "Executes data science pipelines" "Internal ODH"

        # External Systems
        openshift = softwareSystem "OpenShift Platform" "Container orchestration and authentication" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"
        quay = softwareSystem "Quay.io Registry" "Container image distribution (quay.io/modh/*)" "External"
        pypi = softwareSystem "PyPI" "Python package repository" "External"
        github = softwareSystem "GitHub" "Source code version control" "External"

        # User interactions
        user -> dashboard "Selects workbench image and launches notebook" "HTTPS/443"
        user -> notebooks "Accesses notebook via browser" "HTTPS/443 (OAuth2)"

        # Dashboard and Controller orchestration
        dashboard -> imageManagement "References available images" "Kubernetes API"
        notebookController -> imageManagement "Reads ImageStream definitions" "Kubernetes API"
        notebookController -> jupyterImages "Creates StatefulSets for notebook pods" "Kubernetes API"
        notebookController -> ideImages "Creates StatefulSets for IDE pods" "Kubernetes API"

        # OAuth authentication
        oauthProxy -> openshift "Validates OAuth2 tokens" "HTTPS/443"
        user -> oauthProxy "Authenticated via OAuth2 Bearer Token" "HTTPS/443"

        # Notebook workloads
        jupyterImages -> s3 "Reads/writes datasets and model artifacts" "HTTPS/443 (AWS SigV4)"
        jupyterImages -> modelRegistry "Registers trained models" "HTTP/8080 (mTLS)"
        jupyterImages -> kfp "Submits and monitors pipeline runs" "HTTP/8888 (mTLS)"
        jupyterImages -> pypi "Installs Python packages at runtime" "HTTPS/443"
        jupyterImages -> github "Clones repositories" "HTTPS/443 (Git credentials)"
        jupyterImages -> openshift "Accesses Kubernetes API" "HTTPS/6443 (ServiceAccount)"

        # Runtime pipeline execution
        kfp -> runtimeImages "Executes headless pipeline steps" "Kubernetes API"
        runtimeImages -> s3 "Reads/writes pipeline artifacts" "HTTPS/443 (AWS SigV4)"

        # Image distribution
        imageManagement -> quay "Pulls workbench images" "HTTPS/443 (Image Pull Secret)"
        openshift -> quay "Pulls container images via kubelet" "HTTPS/443 (Image Pull Secret)"
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

        component jupyterImages "JupyterImagesComponent" {
            include *
            autoLayout
        }

        component imageManagement "ImageManagementComponent" {
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
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "OpenShift CR" {
                background #f5a623
                color #000000
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

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs data science notebooks and experiments"
        admin = person "Platform Administrator" "Manages workbench images and cluster configuration"

        notebooks = softwareSystem "Notebook Workbench Images" "Container images providing browser-based IDEs (JupyterLab, RStudio, Code Server) with ML frameworks" {
            baseImages = container "Base Images" "Foundation container images with Python runtime and OpenShift CLI" "UBI9/UBI8 Python 3.9/3.8"
            jupyterWorkbenches = container "Jupyter Workbenches" "JupyterLab-based environments with ML frameworks" "JupyterLab 3.6.x, TensorFlow, PyTorch"
            gpuWorkbenches = container "GPU-Accelerated Workbenches" "Workbenches with GPU support" "CUDA, Habana, Intel XPU, AMD ROCm"
            otherWorkbenches = container "Other IDE Workbenches" "RStudio and Code Server environments" "RStudio Server 4.3, VS Code Server"
            runtimeImages = container "Runtime Images" "Lightweight images for pipeline execution without UI" "Python runtime only"
            imageStreams = container "ImageStream Manifests" "OpenShift ImageStream definitions with metadata" "OpenShift Resources"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages workbench pod lifecycle, creates StatefulSets, Services, and Routes" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing data science workbenches" "Internal ODH"
        oauthProxy = softwareSystem "OAuth Proxy" "Sidecar container providing authentication and authorization" "OpenShift Component"

        k8sAPI = softwareSystem "Kubernetes API Server" "Manages cluster resources and workload orchestration" "OpenShift Platform"
        imageRegistry = softwareSystem "Quay.io Registry" "Container image registry storing workbench images" "External"

        pypi = softwareSystem "PyPI Repository" "Python package repository for runtime installations" "External"
        conda = softwareSystem "Conda Repositories" "Conda package repositories" "External"
        github = softwareSystem "GitHub" "Source code repository for Git operations" "External"
        s3 = softwareSystem "S3 / Object Storage" "Object storage for datasets and model artifacts" "External"

        certManager = softwareSystem "cert-manager" "Certificate management for TLS" "External Dependency"
        redhatRegistry = softwareSystem "Red Hat Container Registries" "Base image source for UBI images" "External"

        # User Interactions
        user -> dashboard "Creates workbench via web UI" "HTTPS/443, OAuth2"
        user -> notebooks "Accesses JupyterLab/RStudio/Code Server" "HTTPS/443 via Route, OAuth2"

        # Admin Interactions
        admin -> imageStreams "Deploys ImageStream manifests to cluster" "kubectl apply"
        admin -> k8sAPI "Manages cluster resources" "kubectl/oc CLI"

        # Notebook Image Interactions
        imageStreams -> imageRegistry "References images stored in registry" "Image pull"
        dashboard -> imageStreams "Queries for available workbench options" "Kubernetes API read"
        notebookController -> imageStreams "Reads image metadata for pod creation" "Kubernetes API watch"

        # Workbench Lifecycle
        dashboard -> k8sAPI "Creates Notebook custom resource" "HTTPS/6443, mTLS, SA Token"
        notebookController -> k8sAPI "Watches Notebook CR, creates pods/services/routes" "HTTPS/6443, mTLS, SA Token"
        k8sAPI -> imageRegistry "Pulls workbench images for pod startup" "HTTPS/443, TLS 1.2+, registry auth"
        notebookController -> oauthProxy "Injects OAuth proxy sidecar into notebook pods" "Pod spec modification"

        # Authentication Flow
        oauthProxy -> k8sAPI "Validates OAuth2 tokens" "OpenShift OAuth"
        oauthProxy -> notebooks "Proxies authenticated requests to notebook container" "HTTP/8888"

        # Runtime Dependencies (from running notebooks)
        notebooks -> pypi "Installs Python packages at runtime" "HTTPS/443, pip install"
        notebooks -> conda "Installs Conda packages" "HTTPS/443, conda install"
        notebooks -> github "Git clone/push operations" "HTTPS/443, SSH key/PAT auth"
        notebooks -> s3 "Reads/writes datasets and models" "HTTPS/443, AWS IAM credentials"

        # Build-time Dependencies
        baseImages -> redhatRegistry "Pulls UBI base images during build" "HTTPS/443, subscription auth"
        jupyterWorkbenches -> baseImages "Extends base images with JupyterLab" "Dockerfile FROM"
        gpuWorkbenches -> baseImages "Extends base images with GPU libraries" "Dockerfile FROM"
        otherWorkbenches -> baseImages "Extends base images with RStudio/Code Server" "Dockerfile FROM"
        runtimeImages -> baseImages "Extends base images without UI components" "Dockerfile FROM"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
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
            element "External Dependency" {
                background #cccccc
                color #000000
            }
            element "OpenShift Component" {
                background #ee0000
                color #ffffff
            }
            element "OpenShift Platform" {
                background #cc0000
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

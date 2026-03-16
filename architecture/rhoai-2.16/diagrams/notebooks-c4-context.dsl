workspace {
    model {
        user = person "Data Scientist" "Creates and runs interactive notebooks for data science and ML development"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Pre-built container images for interactive data science development environments" {
            baseImages = container "Base Images" "Foundation layers with Python, pip, oc CLI, and utilities" "UBI9/RHEL9/CentOS"
            jupyterImages = container "Jupyter Images" "JupyterLab environments with data science libraries" "Python/JupyterLab"
            ideImages = container "Alternative IDE Images" "Code Server (VS Code) and RStudio environments" "VS Code/R"
            runtimeImages = container "Runtime Images" "Lightweight images for pipeline execution (no IDE)" "Python"
            imageStreams = container "ImageStream Manifests" "OpenShift ImageStreams with N to N-4 version tags" "Kubernetes Manifests"
            buildConfigs = container "BuildConfig Manifests" "In-cluster builds for RStudio images" "Kubernetes Manifests"
        }

        workbenchInstance = softwareSystem "Deployed Workbench Instance" "Running notebook environment for a user" {
            statefulSet = container "StatefulSet" "Manages workbench pod lifecycle" "Kubernetes"
            oauthProxy = container "OAuth Proxy Sidecar" "Provides TLS termination and authentication" "Go Service"
            jupyterContainer = container "JupyterLab Container" "Interactive development environment" "Python/JupyterLab"
            service = container "Service" "Exposes workbench on port 8888" "Kubernetes Service"
            route = container "OpenShift Route" "External HTTPS access" "OpenShift Route"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Creates and manages workbench StatefulSets" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "User interface for creating workbenches" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline orchestration with Argo Workflows" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores and retrieves ML model metadata" "Internal ODH"
        kserve = softwareSystem "KServe" "Model serving and inference platform" "Internal ODH"

        s3 = softwareSystem "S3 Storage" "Object storage for notebooks, datasets, and models" "External AWS"
        pypi = softwareSystem "PyPI" "Python package repository" "External"
        git = softwareSystem "Git Repositories" "Source code and notebook repositories" "External"
        databases = softwareSystem "External Databases" "PostgreSQL, MySQL, MongoDB data sources" "External"
        k8sAPI = softwareSystem "OpenShift API Server" "Kubernetes cluster management API" "OpenShift Platform"
        oauth = softwareSystem "OpenShift OAuth" "User authentication service" "OpenShift Platform"
        registries = softwareSystem "Container Registries" "Image storage (Quay, Red Hat Registry)" "External"

        # User interactions
        user -> dashboard "Selects workbench image and configuration"
        user -> workbenchInstance "Accesses JupyterLab via browser" "HTTPS/443"

        # Dashboard interactions
        dashboard -> imageStreams "Reads ImageStream metadata and annotations"
        dashboard -> notebookController "Requests workbench creation"

        # Notebook Controller interactions
        notebookController -> imageStreams "References image digests from ImageStreams"
        notebookController -> workbenchInstance "Creates StatefulSet, Service, Route"

        # Workbench instance internal
        route -> oauthProxy "Terminates TLS and forwards traffic" "HTTPS/8443"
        oauthProxy -> jupyterContainer "Forwards authenticated requests" "HTTP/8888"
        oauthProxy -> oauth "Validates OAuth2 tokens" "HTTPS/6443"

        # Workbench integrations
        jupyterContainer -> dsp "Submits pipeline runs via Elyra extension" "HTTP/8888 mTLS"
        jupyterContainer -> modelRegistry "Registers and queries ML models" "HTTP/8080 mTLS"
        jupyterContainer -> kserve "Deploys and invokes inference services" "HTTP/HTTPS 8080/8443"
        jupyterContainer -> s3 "Reads/writes datasets and model artifacts" "HTTPS/443"
        jupyterContainer -> pypi "Installs Python packages at runtime" "HTTPS/443"
        jupyterContainer -> git "Clones notebooks and code" "HTTPS/443"
        jupyterContainer -> databases "Queries external data sources" "TCP 5432/3306/27017"
        jupyterContainer -> k8sAPI "Manages cluster resources via oc CLI" "HTTPS/6443"

        # Build-time dependencies
        buildConfigs -> registries "Pulls base images for RStudio builds" "HTTPS/443"

        # Pipeline runtime dependency
        dsp -> runtimeImages "Executes pipeline steps using lightweight runtime images" "Kubernetes pod execution"
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

        container workbenchInstance "WorkbenchInstanceContainers" {
            include *
            autoLayout
        }

        systemContext workbenchInstance "WorkbenchInstanceContext" {
            include *
            autoLayout
        }

        dynamic workbenchInstance "UserAccessFlow" "User accesses JupyterLab workbench" {
            user -> route "1. HTTPS request to workbench URL"
            route -> oauthProxy "2. Forward to OAuth proxy"
            oauthProxy -> oauth "3. Validate OAuth2 token"
            oauthProxy -> jupyterContainer "4. Forward authenticated request"
            jupyterContainer -> oauthProxy "5. Return JupyterLab UI"
            oauthProxy -> route "6. HTTPS response"
            route -> user "7. Display JupyterLab interface"
            autoLayout
        }

        dynamic workbenchInstance "PipelineSubmissionFlow" "Data scientist submits pipeline from notebook" {
            user -> jupyterContainer "1. Run notebook cell with Elyra"
            jupyterContainer -> dsp "2. Submit pipeline run via API"
            dsp -> runtimeImages "3. Execute pipeline with runtime image"
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
            element "OpenShift Platform" {
                background #ff9800
                color #ffffff
            }
            element "External AWS" {
                background #ff9900
                color #ffffff
            }
            element "Person" {
                shape person
                background #bd10e0
                color #ffffff
            }
        }
    }
}

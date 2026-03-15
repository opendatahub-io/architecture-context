workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and executes ML workloads in Jupyter, RStudio, or VS Code environments"
        pipelineUser = person "Pipeline User" "Executes automated ML pipelines and workflows"
        admin = person "Platform Admin" "Manages notebook images and platform configuration"

        notebooks = softwareSystem "Notebooks Component" "Pre-built container images for data science workbenches (Jupyter, RStudio, CodeServer) and pipeline runtimes" {
            workbenchImages = container "Workbench Images" "Interactive development environments with JupyterLab, RStudio, CodeServer" "Container Images" {
                tags "Workbench"
            }
            runtimeImages = container "Runtime Images" "Lightweight pipeline execution environments" "Container Images" {
                tags "Runtime"
            }
            baseImages = container "Base Images" "Foundation images with CPU/CUDA/ROCm support" "Container Images" {
                tags "Base"
            }
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages lifecycle of data scientist workspaces in OpenShift" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing ML workloads and notebooks" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Orchestrates ML pipeline execution" "Internal ODH"
        elyra = softwareSystem "Elyra" "Notebook-based pipeline authoring and execution" "Internal ODH"
        oauthProxy = softwareSystem "OAuth Proxy" "Authentication and TLS termination for workbench access" "Internal ODH"
        imageStream = softwareSystem "OpenShift ImageStream" "Manages image versions and distribution" "OpenShift Platform"

        konflux = softwareSystem "Konflux CI/CD" "Builds, scans, signs, and publishes container images" "External Build System"
        quayRegistry = softwareSystem "quay.io Registry" "Stores and distributes container images" "External Registry"
        ubi = softwareSystem "Red Hat UBI/RHEL" "Base operating system images (UBI9, RHEL9)" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for data and model artifacts" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code version control (GitHub, GitLab)" "External"
        pypi = softwareSystem "PyPI" "Python package index for installing libraries" "External"
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server" "Platform"

        # User interactions
        dataScientist -> dashboard "Creates notebook via UI"
        pipelineUser -> kubeflowPipelines "Submits ML pipelines"
        admin -> imageStream "Deploys image updates"

        # Notebook component relationships
        dashboard -> notebooks "Lists available workbench images"
        notebookController -> workbenchImages "Launches workbench pods from images" "HTTPS/6443"
        kubeflowPipelines -> runtimeImages "Executes pipeline tasks using runtime images" "HTTPS/6443"
        elyra -> runtimeImages "Submits notebook-based pipelines" "HTTPS/6443"
        imageStream -> notebooks "References and pulls images from quay.io"

        # OAuth and access
        dataScientist -> oauthProxy "Accesses workbench via HTTPS" "HTTPS/443"
        oauthProxy -> workbenchImages "Proxies to Jupyter/RStudio/CodeServer" "HTTP/8888"

        # Build and distribution
        konflux -> ubi "Pulls base images" "HTTPS/443"
        konflux -> notebooks "Builds container images"
        konflux -> quayRegistry "Pushes signed images" "HTTPS/443"
        quayRegistry -> imageStream "Provides image registry"

        # Workbench egress
        workbenchImages -> k8sAPI "Creates jobs, accesses resources" "HTTPS/6443"
        workbenchImages -> s3Storage "Reads/writes data and models" "HTTPS/443"
        workbenchImages -> gitRepos "Clones repos, pushes changes" "HTTPS/443"
        workbenchImages -> pypi "Installs Python packages" "HTTPS/443"

        # Base image dependencies
        baseImages -> workbenchImages "Provides foundation layers"
        baseImages -> runtimeImages "Provides foundation layers"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "External Build System" {
                background #999999
                color #ffffff
            }
            element "External Registry" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #cccccc
                color #000000
            }
            element "Platform" {
                background #f5a623
                color #000000
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Workbench" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50c878
                color #000000
            }
            element "Base" {
                background #9b59b6
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

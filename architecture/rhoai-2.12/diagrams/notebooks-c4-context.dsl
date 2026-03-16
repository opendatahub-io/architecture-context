workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML/AI experiments, develops models, analyzes data"
        developer = person "Developer" "Maintains and builds notebook container images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Builds and maintains Jupyter notebook and IDE workbench container images for data science and machine learning workflows in RHOAI/ODH" {
            buildSystem = container "Build System" "Orchestrates multi-stage container builds with dependency resolution" "Makefile + Podman/Docker" {
                makefile = component "Makefile" "Build orchestration and dependency management" "GNU Make"
                ciScripts = component "CI/CD Scripts" "Validation, security scanning, params.env checks" "Shell Scripts + Python"
            }

            manifests = container "Kustomize Manifests" "OpenShift ImageStream and BuildConfig definitions" "Kustomize YAML" {
                imageStreams = component "ImageStreams" "Versioned image references with N/N-1/N-2/N-3 strategy" "OpenShift ImageStream"
                buildConfigs = component "BuildConfigs" "On-cluster RHEL image builds" "OpenShift BuildConfig"
                configMaps = component "ConfigMaps" "params.env and commit.env data" "Kustomize ConfigMap"
            }

            images = container "Container Images" "Pre-configured workbench environments with data science libraries" "Container Images" {
                jupyterImages = component "Jupyter Images" "JupyterLab-based notebooks (Minimal, DataScience, PyTorch, TensorFlow, TrustyAI)" "Container Image"
                gpuImages = component "GPU Images" "CUDA, ROCm, Habana, Intel accelerated images" "Container Image"
                ideImages = component "IDE Images" "RStudio Server, VS Code Server" "Container Image"
                runtimeImages = component "Runtime Images" "Lightweight Elyra pipeline execution images" "Container Image"
            }
        }

        # External Systems
        github = softwareSystem "GitHub" "Source code repository and CI/CD platform" "External"
        githubActions = softwareSystem "GitHub Actions / Konflux" "Build automation and CI/CD pipeline" "External"
        redHatRegistry = softwareSystem "Red Hat Registry" "UBI and RHEL base images" "External"
        quay = softwareSystem "Quay.io" "Container image registry for workbench images" "External"
        pypi = softwareSystem "PyPI" "Python package index for runtime package installation" "External"

        # Internal RHOAI/ODH Systems
        notebookController = softwareSystem "ODH Notebook Controller" "Launches and manages notebook pod lifecycle" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for selecting and launching notebooks" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal ODH"
        openShiftImageRegistry = softwareSystem "OpenShift Image Registry" "Internal registry for BuildConfig outputs" "Internal ODH"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "Authentication provider for notebook access" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster orchestration and resource management" "Internal ODH"

        # Data Sources
        s3Storage = softwareSystem "S3-compatible Storage" "Training data and model artifact storage" "External"
        databases = softwareSystem "Databases" "PostgreSQL, MySQL, MongoDB data sources" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code version control" "External"

        # GPU/Accelerator Support
        nvidiaGPU = softwareSystem "NVIDIA GPU Operator" "GPU device plugin and drivers for CUDA workloads" "External"
        nfd = softwareSystem "Node Feature Discovery" "Hardware detection for GPU/accelerator scheduling" "External"

        # Relationships - Developer Workflow
        developer -> github "Commits code changes to" "HTTPS/443 TLS1.3"
        github -> githubActions "Triggers build on push" "Webhook"
        githubActions -> redHatRegistry "Pulls UBI base images from" "HTTPS/443 TLS1.2+"
        githubActions -> buildSystem "Executes builds using" "podman/docker"
        buildSystem -> quay "Pushes built images to" "HTTPS/443 TLS1.2+"
        quay -> imageStreams "Image available via" "HTTPS/443 TLS1.2+"
        buildConfigs -> openShiftImageRegistry "Builds RHEL images to" "HTTPS/443 TLS1.2+"

        # Relationships - Data Scientist Workflow
        dataScientist -> odhDashboard "Selects notebook image from" "HTTPS/443 TLS1.2+"
        odhDashboard -> imageStreams "Reads image metadata from" "Kubernetes API"
        dataScientist -> k8sAPI "Creates Notebook CR via" "kubectl/HTTPS"
        k8sAPI -> notebookController "Notifies of new Notebook CR" "Watch"
        notebookController -> jupyterImages "Launches pods using" "Pod spec"
        notebookController -> gpuImages "Launches GPU pods using" "Pod spec"
        notebookController -> ideImages "Launches IDE pods using" "Pod spec"
        notebookController -> openShiftOAuth "Configures OAuth proxy for" "ServiceAccount"

        dataScientist -> jupyterImages "Accesses notebook via" "HTTPS/443 OAuth"

        # Relationships - Runtime Dependencies
        jupyterImages -> pypi "Installs packages from" "HTTPS/443 TLS1.2+"
        jupyterImages -> s3Storage "Reads/writes data to" "HTTPS/443 AWS IAM"
        jupyterImages -> databases "Queries data from" "PostgreSQL/MySQL/MongoDB"
        jupyterImages -> k8sAPI "Submits pipelines to" "HTTPS/6443 ServiceAccount"
        jupyterImages -> kubeflowPipelines "Submits via Elyra to" "HTTPS/8888 Bearer Token"
        jupyterImages -> gitRepos "Version controls notebooks in" "HTTPS/SSH"
        runtimeImages -> kubeflowPipelines "Executes pipeline steps in" "Container runtime"

        # GPU/Accelerator Dependencies
        gpuImages -> nvidiaGPU "Requests GPU devices from" "Device Plugin API"
        gpuImages -> nfd "Scheduled based on labels from" "Node labels"

        # Manifest and Build Dependencies
        ciScripts -> manifests "Validates consistency of" "Shell scripts"
        configMaps -> imageStreams "Provides image digests to" "Kustomize vars"
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

        component buildSystem "BuildSystemComponents" {
            include *
            autoLayout
        }

        component manifests "ManifestsComponents" {
            include *
            autoLayout
        }

        component images "ImagesComponents" {
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs interactive notebooks and ML pipelines on OpenShift AI"
        platformAdmin = person "Platform Admin" "Deploys and manages the OpenShift AI platform"

        notebooks = softwareSystem "Notebooks Image Factory" "Builds and publishes container images for interactive data science workbenches (Jupyter, Code-Server) and Elyra pipeline runtime images" {
            jupyterImages = container "Jupyter Workbench Images" "11 variants: minimal, datascience, pytorch, tensorflow, trustyai, llmcompressor, rocm-pytorch, rocm-tensorflow across CPU/CUDA/ROCm" "Container Image"
            codeServerImage = container "Code-Server Workbench Image" "VS Code in the browser with nginx reverse proxy and Jupyter-compatible activity API" "Container Image"
            runtimeImages = container "Pipeline Runtime Images" "7 headless Python environments for Elyra pipeline node execution on Kubeflow Pipelines" "Container Image"
            kustomizeManifests = container "Kustomize Manifests" "OpenShift ImageStream definitions and overlays for ODH (18) and RHOAI (25) distributions" "Kubernetes Config"
            buildToolchain = container "Build Toolchain" "Dependency lockfile generation, Dockerfile fragment injection, build-args sync, CI validation" "Python / Bash"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Creates workbench pods from Notebook CRs, injects kube-rbac-proxy sidecar" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Discovers workbench images via ImageStream annotations for user selection UI" "Internal ODH"
        operator = softwareSystem "ODH/RHOAI Operator" "Deploys ImageStream manifests to cluster via operator reconcile loop" "Internal ODH"
        elyraEngine = softwareSystem "Elyra Pipeline Engine" "Executes notebook pipeline nodes using runtime images on Kubeflow Pipelines" "Internal ODH"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline orchestration and execution" "Internal ODH"

        aipcc = softwareSystem "AIPCC Base Images" "RHEL 9.6 EUS base images with accelerator-specific libraries (CPU, CUDA, ROCm)" "External"
        konflux = softwareSystem "Konflux / Tekton" "Hermetic build pipeline with Cachi2 prefetch and check-payload FIPS validation" "External"
        s3 = softwareSystem "S3 Object Storage" "Data artifact storage for notebooks and pipeline runtimes" "External"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline execution backend for Elyra" "External"
        git = softwareSystem "Git Repositories" "Source code management for jupyterlab-git and nbgitpuller" "External"
        databases = softwareSystem "Databases" "MongoDB, PostgreSQL, MySQL for data access from datascience workbenches" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking server" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io/rhoai/ and quay.io/opendatahub/" "External"

        # Relationships - User interactions
        dataScientist -> dashboard "Selects workbench image" "HTTPS/443"
        dataScientist -> notebooks "Uses workbench via browser" "HTTPS/8443 (kube-rbac-proxy)"
        platformAdmin -> operator "Deploys platform" "Kubernetes API"

        # Relationships - Platform orchestration
        dashboard -> notebookController "Creates Notebook CR" "Kubernetes API/6443"
        notebookController -> containerRegistry "Pulls workbench/runtime images" "HTTPS/443"
        notebookController -> notebooks "Creates pods, injects sidecars" "Kubernetes API"
        operator -> kustomizeManifests "Deploys ImageStream manifests" "Kubernetes API"
        dashboard -> kustomizeManifests "Discovers images via annotations" "Kubernetes API"
        elyraEngine -> runtimeImages "Pulls runtime images for pipeline nodes" "HTTPS/443"

        # Relationships - Build-time
        aipcc -> notebooks "Provides ${BASE_IMAGE} for RHOAI builds" "Container Registry"
        konflux -> notebooks "Builds and validates images hermetically" "Build Pipeline"

        # Relationships - Runtime egress
        notebooks -> kfp "Submits Elyra pipelines" "HTTPS/443"
        notebooks -> s3 "Reads/writes data artifacts" "HTTPS/443"
        notebooks -> git "Git operations from jupyterlab-git" "HTTPS/443"
        notebooks -> databases "Data access from datascience images" "TCP/27017,5432,3306"
        notebooks -> mlflow "Experiment tracking" "HTTP/5000"
        notebooks -> dspa "Pipeline execution endpoint" "HTTPS/443"
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
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                shape Hexagon
                background #4a90e2
                color #ffffff
            }
            element "Kubernetes Config" {
                shape Folder
                background #f5a623
                color #ffffff
            }
            element "Python / Bash" {
                shape Component
                background #9b59b6
                color #ffffff
            }
        }
    }
}

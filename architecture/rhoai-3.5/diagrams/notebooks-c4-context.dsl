workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs interactive workbenches for ML/data science work"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and workbench image deployments"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "18 container images for interactive data science workbenches (JupyterLab, Code-Server) and Elyra pipeline runtimes across CPU, NVIDIA CUDA, and AMD ROCm variants" {
            jupyterMinimal = container "Jupyter Minimal" "Foundation JupyterLab workbench with Python 3.12" "Container Image" "CPU, CUDA 13.0, ROCm 7.14 variants"
            jupyterDataScience = container "Jupyter Data Science" "JupyterLab with NumPy, Pandas, scikit-learn, MLflow, Elyra, database connectors" "Container Image" "CPU variant"
            jupyterPyTorch = container "Jupyter PyTorch" "JupyterLab with PyTorch on NVIDIA CUDA 13.0" "Container Image" "CUDA variant"
            jupyterPyTorchLLM = container "Jupyter PyTorch+LLMCompressor" "JupyterLab with PyTorch and LLM compression toolkit" "Container Image" "CUDA variant"
            jupyterTensorFlow = container "Jupyter TensorFlow" "JupyterLab with TensorFlow on NVIDIA CUDA 12.9" "Container Image" "CUDA variant"
            jupyterTrustyAI = container "Jupyter TrustyAI" "JupyterLab with AI fairness/explainability tools and Java 17" "Container Image" "CPU variant"
            jupyterROCm = container "Jupyter ROCm" "JupyterLab with PyTorch or TensorFlow on AMD ROCm 7.14" "Container Image" "ROCm variant"
            codeServer = container "Code-Server" "VS Code in the browser (code-server v4.112.0) with nginx proxy and idle culling" "Container Image" "CPU variant"
            runtimeImages = container "Pipeline Runtime Images" "7 Elyra pipeline runtime images for batch notebook execution" "Container Images" "CPU, CUDA, ROCm variants"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions, params.env, commit.env for platform deployment" "Kustomize"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Launches workbench pods, injects kube-rbac-proxy sidecar, mounts CA bundles and Elyra configs" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for selecting and launching workbenches via ImageStream annotations" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests via kustomize" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline execution endpoint for Elyra pipeline submission" "Internal RHOAI"
        aipccBaseImages = softwareSystem "AIPCC Base Images" "Base container images (cpu, cuda-13.0, cuda-12.9, rocm-7.14) from quay.io/aipcc/base-images/" "External"
        konflux = softwareSystem "Konflux / Tekton" "Hermetic build system with Cachi2 dependency prefetching" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for job submission and pipeline operations" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for MLflow artifacts and pipeline data" "External"
        mlflow = softwareSystem "MLflow Tracking Server" "Experiment tracking for data science workbenches" "External"
        mongoDB = softwareSystem "MongoDB" "Database connectivity from datascience workbenches" "External"
        postgreSQL = softwareSystem "PostgreSQL" "Database connectivity from datascience workbenches" "External"
        containerRegistry = softwareSystem "Container Registry" "quay.io and registry.redhat.io for image storage and distribution" "External"

        # User interactions
        dataScientist -> notebooks "Selects workbench type, runs notebooks and pipelines"
        dataScientist -> dashboard "Launches workbenches via UI"
        platformAdmin -> rhodsOperator "Manages platform deployment"

        # Internal platform interactions
        dashboard -> kustomizeManifests "Reads ImageStream annotations (opendatahub.io/*)" "Kubernetes API"
        notebookController -> notebooks "Launches pods, injects kube-rbac-proxy sidecar" "Mutating Webhook"
        rhodsOperator -> kustomizeManifests "Deploys ImageStream manifests" "Kustomize"
        dspa -> runtimeImages "Launches pipeline runtime pods" "Kubernetes API"

        # Workbench outbound
        notebooks -> kubernetesAPI "Kubeflow Training jobs, KFP operations" "HTTPS/443"
        notebooks -> dspa "Elyra pipeline submission" "HTTPS/443"
        notebooks -> s3Storage "MLflow artifacts, pipeline data" "HTTPS/443"
        notebooks -> mlflow "Experiment tracking" "HTTPS/443"
        notebooks -> mongoDB "Database access (datascience variants)" "TCP/27017"
        notebooks -> postgreSQL "Database access (datascience variants)" "TCP/5432"

        # Build-time
        notebooks -> aipccBaseImages "Built FROM AIPCC base images (digest-pinned)" "Container Build"
        konflux -> notebooks "Hermetic image builds with Cachi2 prefetching" "Tekton Pipeline"
        notebooks -> containerRegistry "Image push/pull" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs data science workbenches and pipelines in RHOAI"
        mlEngineer = person "ML Engineer" "Trains and deploys ML models using GPU-accelerated workbenches"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image library providing interactive JupyterLab/Code-Server workbenches and Elyra pipeline runtimes for RHOAI" {
            jupyterMinimal = container "jupyter-minimal" "Foundation JupyterLab workbench with minimal Python dependencies" "Container Image (Python, UBI9)" "cpu,cuda,rocm"
            jupyterDS = container "jupyter-datascience" "Full data science stack: NumPy, Pandas, scikit-learn, Elyra, MLflow, CodeFlare SDK" "Container Image (Python, UBI9)"
            jupyterPyTorch = container "jupyter-pytorch" "GPU-accelerated PyTorch deep learning workbench" "Container Image (Python, UBI9)" "cuda,rocm"
            jupyterTF = container "jupyter-tensorflow" "GPU-accelerated TensorFlow deep learning workbench" "Container Image (Python, UBI9)" "cuda,rocm"
            jupyterLLM = container "jupyter-pytorch-llmcompressor" "LLM optimization workbench with sparsification and quantization" "Container Image (Python, UBI9)" "cuda"
            jupyterTrustyAI = container "jupyter-trustyai" "AI fairness and explainability workbench with TrustyAI + Java 17" "Container Image (Python, Java, UBI9)" "cpu"
            codeserver = container "codeserver-datascience" "VS Code in browser via code-server with data science Python stack" "Container Image (Python, JavaScript, UBI9)"
            runtimeImages = container "Runtime Images" "Headless Python runtimes for Elyra pipeline node execution (7 variants)" "Container Images (Python, UBI9)"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize-based OpenShift ImageStream definitions with parameterized image references" "Kustomize YAML"
            buildSystem = container "Build System" "Makefile, lockfile generators, Dockerfile alignment checks, CI tooling" "Makefile, Python, Go, Bash"
        }

        # Internal Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests to cluster via kustomize" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Reads ImageStream annotations to display workbench options to users" "Internal RHOAI"
        notebookController = softwareSystem "Notebook Controller (kubeflow)" "Manages Notebook CR lifecycle, injects kube-rbac-proxy sidecar, mounts secrets" "Internal RHOAI"
        notebookCuller = softwareSystem "Notebook Controller Culler" "Polls /api/kernels/ to detect and cull idle workbenches" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Pipeline execution backend for Elyra-submitted pipelines" "Internal RHOAI"

        # External Dependencies
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for datasets and model artifacts" "External"
        mlflowServer = softwareSystem "MLflow Tracking Server" "Experiment tracking and model registry" "External"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Event streaming platform" "External"
        mongoDB = softwareSystem "MongoDB" "Database for data science operations" "External"
        containerRegistry = softwareSystem "Container Image Registry" "registry.redhat.io and quay.io for image distribution" "External"
        konfluxCI = softwareSystem "Konflux CI" "Hermetic container build system with cachi2 prefetch" "External"
        aipccPipeline = softwareSystem "AIPCC Pipeline" "Provides RHEL-based base images for downstream RHOAI builds" "External"

        # User relationships
        dataScientist -> notebooks "Launches workbenches and submits pipelines"
        mlEngineer -> notebooks "Uses GPU-accelerated workbenches for model training"

        # Internal platform relationships
        rhodsOperator -> imageStreamManifests "Deploys to cluster" "Kustomize / 6443 HTTPS"
        odhDashboard -> imageStreamManifests "Reads annotations for workbench UI" "K8s API / 6443 HTTPS"
        notebookController -> jupyterMinimal "Creates pods, injects kube-rbac-proxy sidecar" "K8s API / 6443 HTTPS"
        notebookController -> codeserver "Creates pods, injects kube-rbac-proxy sidecar" "K8s API / 6443 HTTPS"
        notebookCuller -> jupyterMinimal "Polls /api/kernels/ for idle detection" "HTTPS / 8443"
        notebookCuller -> codeserver "Polls /api/kernels/ for idle detection" "HTTPS / 8443"
        dspa -> runtimeImages "Launches pipeline batch pods" "K8s API"

        # Image hierarchy
        jupyterMinimal -> jupyterDS "FROM base" "Docker layer"
        jupyterDS -> jupyterPyTorch "FROM base" "Docker layer"
        jupyterDS -> jupyterTF "FROM base" "Docker layer"
        jupyterDS -> jupyterTrustyAI "FROM base" "Docker layer"
        jupyterPyTorch -> jupyterLLM "FROM base" "Docker layer"

        # Egress from workbenches
        jupyterDS -> s3Storage "Object storage access" "HTTPS / 443"
        jupyterDS -> mlflowServer "Experiment tracking" "HTTP(S) / 5000"
        jupyterDS -> kafkaBrokers "Event streaming" "TCP / 9092 SASL"
        jupyterDS -> mongoDB "Database operations" "TCP / 27017"
        jupyterDS -> dspa "Elyra pipeline submission" "HTTP(S) / 8888"
        runtimeImages -> s3Storage "Download notebooks/data" "HTTPS / 443"

        # Build pipeline
        konfluxCI -> containerRegistry "Push built images" "HTTPS / 443"
        aipccPipeline -> containerRegistry "Push base images" "HTTPS / 443"
        buildSystem -> konfluxCI "Dockerfile.konflux.* with hermetic prefetch" "HTTPS / 443"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

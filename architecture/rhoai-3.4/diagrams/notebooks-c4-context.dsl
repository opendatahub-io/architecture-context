workspace {
    model {
        user = person "Data Scientist" "Creates and uses interactive workbenches for ML development"
        clusterAdmin = person "Cluster Admin" "Manages RHOAI platform deployment and RHEL subscriptions"
        developer = person "Developer" "Builds and maintains workbench container images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Container image factory producing 20+ workbench and runtime images for interactive data science environments" {
            jupyterMinimal = container "JupyterLab Minimal" "Lightest notebook environment — base for all Jupyter variants" "Python, JupyterLab" "CPU/CUDA/ROCm"
            jupyterDS = container "JupyterLab Data Science" "Full data science workbench with Elyra, DB connectors, CodeFlare" "Python, Go (mongocli)"
            jupyterPyTorch = container "JupyterLab PyTorch" "GPU-accelerated workbench with PyTorch 2.10" "Python, CUDA 12.9"
            jupyterLLM = container "JupyterLab LLMCompressor" "LLM compression and quantization workbench" "Python, LLMCompressor 0.10"
            jupyterTF = container "JupyterLab TensorFlow" "GPU-accelerated workbench with TensorFlow 2.21" "Python, CUDA 12.9"
            jupyterTrust = container "JupyterLab TrustAI" "AI fairness and explainability workbench" "Python, Java 17"
            codeServer = container "Code Server" "VS Code-based workbench with nginx proxy" "TypeScript, Python" "CPU only"
            rstudio = container "RStudio Server" "R + Python dual-language workbench" "R 4.5, Python 3.12" "CPU/CUDA"
            runtimeImages = container "Runtime Images" "Lightweight pipeline execution environments (7 variants)" "Python" "No IDE"
            imageStreams = container "ImageStream Manifests" "Kustomize manifests registering images on cluster" "YAML, Kustomize"
            buildSystem = container "Build Infrastructure" "Lock files, Dockerfile sync, CVE management" "Makefile, Python"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Creates workbench pods, injects kube-rbac-proxy sidecar" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Applies ImageStream manifests to cluster" "Internal ODH"
        dashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and launching workbenches" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Executes pipeline steps in runtime images via Elyra" "Internal ODH"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OAuth/OIDC auth proxy sidecar for workbench pods" "Internal ODH"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Envoy-based ingress gateway with TLS termination" "Internal ODH"

        konfluxCI = softwareSystem "Konflux CI" "Hermetic container build pipeline with Cachi2 prefetch" "External"
        registryRedHat = softwareSystem "registry.redhat.io" "Red Hat container image registry" "External"
        kubeAPI = softwareSystem "Kubernetes API" "OpenShift cluster API server" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for notebooks and model artifacts" "External"
        pypi = softwareSystem "PyPI / RH Python Index" "Python package repositories" "External"
        mlflow = softwareSystem "MLflow Tracking" "Experiment tracking and model registry" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code and notebook version control" "External"

        // Relationships
        developer -> notebooks "Builds and maintains container images"
        user -> rhoaiGateway "Accesses workbench via browser" "HTTPS/443"
        rhoaiGateway -> kubeRBACProxy "Forwards requests" "HTTPS/8443, mTLS"
        kubeRBACProxy -> notebooks "Proxies to workbench" "HTTP/8888 or 8787"
        user -> dashboard "Selects workbench image" "HTTPS/443"
        dashboard -> kubeAPI "Creates Notebook CR" "HTTPS/6443"
        clusterAdmin -> rhodsOperator "Manages platform deployment"

        notebookController -> notebooks "Creates workbench pods from images"
        rhodsOperator -> imageStreams "Applies ImageStream manifests" "HTTPS/6443"
        dashboard -> imageStreams "Reads image annotations" "HTTPS/6443"
        dsPipelines -> runtimeImages "Executes pipeline steps"
        kubeRBACProxy -> notebooks "Auth enforcement sidecar"

        notebooks -> s3Storage "Notebook/data storage" "HTTPS/443"
        notebooks -> kubeAPI "oc CLI, pipeline submission" "HTTPS/6443"
        notebooks -> pypi "Runtime pip install" "HTTPS/443"
        notebooks -> mlflow "Experiment tracking" "HTTPS/443"
        notebooks -> gitRepos "Version control" "HTTPS/443"

        developer -> konfluxCI "Triggers hermetic builds"
        konfluxCI -> registryRedHat "Pushes built images" "HTTPS/443"
        notebookController -> registryRedHat "Pulls workbench images" "HTTPS/443"
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
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

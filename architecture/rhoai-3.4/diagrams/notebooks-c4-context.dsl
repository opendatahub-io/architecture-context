workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML/AI development"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines using workbench environments"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, deploys workbench images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Image factory producing ~25 container images for interactive data science workbenches (Jupyter, RStudio, Code-Server) and pipeline runtimes" {
            jupyterImages = container "Jupyter Workbench Images" "JupyterLab-based interactive notebooks with ML framework stacks (minimal, datascience, PyTorch, TensorFlow, TrustyAI, LLM Compressor)" "Container Images (UBI9 + Python 3.12)"
            codeserverImage = container "Code-Server Image" "VS Code in the browser with data science packages, nginx proxy for idle culling" "Container Image (Node.js + Python)"
            rstudioImages = container "RStudio Images" "RStudio Server with R and Python, nginx proxy for idle culling" "Container Image (R + Python)"
            runtimeImages = container "Pipeline Runtime Images" "Lightweight execution environments for Elyra pipeline nodes" "Container Images (Python)"
            baseImages = container "Base Images" "GPU-accelerated foundations with CUDA/ROCm drivers" "Container Images (UBI9)"
            manifests = container "ImageStream Manifests" "Kustomize overlays defining OpenShift ImageStreams with version tags and dashboard annotations" "Kubernetes Manifests"
            buildSystem = container "Build System" "Makefile-driven build orchestration with hermetic Konflux support" "Makefile + Scripts"
        }

        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys ImageStreams from manifests to cluster" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI - discovers workbench images via ImageStream annotations" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Kubeflow-based controller that injects kube-rbac-proxy sidecar, mounts CA certs, manages routes" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Argo/Tekton) that executes pipeline runtime images" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "JupyterLab extension for visual pipeline composition, reads runtime image metadata" "Internal RHOAI"

        konflux = softwareSystem "Konflux CI/CD" "Hermetic build pipeline using Tekton, cachi2/Hermeto for air-gapped image builds" "External"
        registryRedHat = softwareSystem "registry.redhat.io" "Red Hat container image registry hosting published workbench images" "External"
        openshiftRegistry = softwareSystem "OpenShift Image Registry" "Cluster-internal registry importing images via ImageStreams" "External"
        cudaToolkit = softwareSystem "CUDA Toolkit" "NVIDIA GPU compute libraries (12.6-13.0)" "External"
        rocm = softwareSystem "ROCm" "AMD GPU compute libraries (6.2-6.4)" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for ML data and model artifacts" "External"
        pypi = softwareSystem "PyPI" "Python package index for runtime user installs" "External"
        kubeAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes API server" "External"

        # Relationships - Users
        dataScientist -> notebooks "Runs workbenches built from these images"
        mlEngineer -> notebooks "Uses pipeline runtimes for Elyra pipelines"
        platformAdmin -> notebooks "Configures which workbench images are available"

        # Relationships - Build
        buildSystem -> konflux "Triggers hermetic image builds" "Tekton pipelines"
        konflux -> registryRedHat "Publishes built images" "HTTPS/443"
        baseImages -> jupyterImages "Provides GPU-accelerated base layer" "FROM directive"
        baseImages -> codeserverImage "Provides base layer" "FROM directive"
        baseImages -> rstudioImages "Provides base layer" "FROM directive"
        cudaToolkit -> baseImages "Provides NVIDIA GPU drivers" "Build-time inclusion"
        rocm -> baseImages "Provides AMD GPU drivers" "Build-time inclusion"

        # Relationships - Deployment
        rhodsOperator -> manifests "Reads Kustomize manifests to deploy ImageStreams" "Kustomize"
        odhDashboard -> kubeAPI "Reads ImageStream annotations for image discovery" "HTTPS/6443 mTLS"
        openshiftRegistry -> registryRedHat "Imports images via ImageStreams" "HTTPS/443"

        # Relationships - Runtime
        notebookController -> jupyterImages "Injects sidecar, mounts secrets into workbench pods" "Mutating webhook"
        notebookController -> codeserverImage "Injects sidecar, mounts secrets into workbench pods" "Mutating webhook"
        notebookController -> rstudioImages "Injects sidecar, mounts secrets into workbench pods" "Mutating webhook"
        dsPipelines -> runtimeImages "Executes as Argo/Tekton task containers" "Container runtime"
        elyra -> runtimeImages "Reads runtime image metadata annotations" "ImageStream annotations"
        jupyterImages -> s3Storage "User data access from notebooks" "HTTPS/443"
        jupyterImages -> pypi "User pip install at runtime" "HTTPS/443"
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

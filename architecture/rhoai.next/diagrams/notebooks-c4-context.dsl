workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, runs experiments, builds ML pipelines"
        mlEngineer = person "ML Engineer" "Deploys models, manages pipeline runtimes"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Builds container images for interactive data science workbenches (JupyterLab, Code-Server) and pipeline runtime images" {
            jupyterMinimal = container "Jupyter Minimal" "Lightweight JupyterLab with base Python packages" "Container Image (CPU/CUDA/ROCm)"
            jupyterDataScience = container "Jupyter DataScience" "JupyterLab with NumPy, Pandas, SciPy, scikit-learn, Elyra, Kale" "Container Image (CPU)"
            jupyterPyTorch = container "Jupyter PyTorch" "JupyterLab with PyTorch 2.11 + CUDA 13.0" "Container Image (CUDA)"
            jupyterPyTorchLLM = container "Jupyter PyTorch+LLMCompressor" "JupyterLab with PyTorch + LLM Compressor for model quantization" "Container Image (CUDA)"
            jupyterTensorFlow = container "Jupyter TensorFlow" "JupyterLab with TensorFlow + CUDA 12.9" "Container Image (CUDA)"
            jupyterTrustyAI = container "Jupyter TrustyAI" "JupyterLab with TrustyAI explainability (Java 17)" "Container Image (CPU)"
            codeServer = container "Code-Server" "VS Code in the browser (v4.106.3) with nginx idle culling proxy" "Container Image (CPU)"
            runtimeImages = container "Pipeline Runtime Images" "Elyra pipeline execution environments (Minimal, DataScience, PyTorch, TF, ROCm)" "Container Images"
            kubeRbacProxy = container "kube-rbac-proxy" "OAuth/RBAC sidecar injected by notebook controller" "Sidecar Container"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStreams to cluster via kustomize manifests" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Discovers workbench images via ImageStream annotations, presents UI" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Manages pod lifecycle: sidecar injection, CA bundle, Elyra config, DSPA secrets" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines Application" "Pipeline orchestration — provides endpoint config consumed by Elyra" "Internal RHOAI"
        notebookCuller = softwareSystem "Notebook Controller Culler" "Monitors workbench idle state via /api/kernels/ polling" "Internal RHOAI"

        aipccBaseImages = softwareSystem "AIPCC Ecosystems Base Images" "RHEL 9.6 + Python 3.12 + accelerator runtimes (CPU/CUDA/ROCm)" "External"
        konflux = softwareSystem "Konflux / Tekton" "Hermetic CI/CD build pipeline with Cachi2 dependency prefetch" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/modh/)" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for pipeline submission and cluster operations" "External"
        s3Storage = softwareSystem "Container Image Registries" "Image pulls for pipeline runtime images" "External"
        pypiServers = softwareSystem "External Python Package Servers" "User-initiated pip install from running workbenches" "External"

        # Relationships - Build time
        aipccBaseImages -> notebooks "Provides base images (RHEL 9.6, Python 3.12, accelerator libs)" "Container FROM"
        konflux -> notebooks "Builds images hermetically" "Tekton Pipeline"
        notebooks -> quayRegistry "Pushes built images" "HTTPS/443"

        # Relationships - Deployment time
        rhodsOperator -> notebooks "Deploys ImageStreams from manifests/rhoai/ kustomize" "Kubernetes API"
        odhDashboard -> notebooks "Discovers workbench images via ImageStream annotations" "Kubernetes API"
        notebookController -> notebooks "Injects kube-rbac-proxy sidecar, CA bundle, Elyra config, DSPA secret" "Mutating Webhook"
        notebookCuller -> notebooks "Polls /api/kernels/ for idle timeout" "HTTP/8888"

        # Relationships - Runtime
        dataScientist -> notebooks "Uses JupyterLab or Code-Server via browser" "HTTPS/443 OAuth"
        mlEngineer -> notebooks "Configures pipeline runtimes" "HTTPS/443 OAuth"
        notebooks -> openshiftAPI "Elyra pipeline submission, kubectl/oc" "HTTPS/443 SA token"
        notebooks -> dspa "Submits pipelines via KFP SDK" "HTTPS/443 SA token"
        notebooks -> s3Storage "Pulls runtime images for pipelines" "HTTPS/443 TLS"
        notebooks -> pypiServers "User-initiated pip install" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Container Image (CPU)" {
                background #438dd5
                color #ffffff
            }
            element "Container Image (CUDA)" {
                background #e85d04
                color #ffffff
            }
            element "Sidecar Container" {
                background #d62828
                color #ffffff
            }
        }
    }
}

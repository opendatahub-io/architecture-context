workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses notebook workbenches for ML development"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines using runtime images"

        notebooksDownstream = softwareSystem "notebooks-downstream" "Container image repository producing ~32 workbench and pipeline runtime images for RHOAI" {
            jupyterWorkbenches = container "Jupyter Workbenches" "Interactive JupyterLab environments (Minimal, Data Science, PyTorch, TensorFlow, TrustyAI)" "Container Image, Python, UBI9" "workbench"
            codeServerWorkbench = container "Code Server Workbench" "VS Code in browser via code-server v4.98.0, nginx proxy, supervisord" "Container Image, TypeScript/Python, UBI9" "workbench"
            rstudioWorkbench = container "RStudio Workbench" "RStudio Server 2024.12.1 with R 4.4.3, nginx proxy, supervisord" "Container Image, R/Python, C9S/RHEL9" "workbench"
            pipelineRuntimes = container "Pipeline Runtime Images" "Headless Python environments for Elyra pipeline step execution" "Container Image, Python, UBI9" "runtime"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize manifests defining OpenShift ImageStream resources with version windowing (N through N-5)" "Kustomize YAML" "manifest"
        }

        rhoaiOperator = softwareSystem "rhods-operator" "Platform operator that deploys and manages RHOAI components" "Internal RHOAI"
        notebookController = softwareSystem "odh-notebook-controller" "Creates StatefulSet pods from workbench images, injects auth sidecars" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and launching notebook workbenches" "Internal RHOAI"
        elyraController = softwareSystem "Elyra Pipeline Controller" "Orchestrates ML pipeline execution using runtime container images" "Internal RHOAI"

        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Auth sidecar injected into notebook pods (RHOAI 3.x)" "Internal Platform"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster operations" "External Platform"
        containerRegistry = softwareSystem "Container Registry (quay.io/modh)" "Stores and serves built container images" "External"
        objectStorage = softwareSystem "Object Storage (S3)" "Model and pipeline artifact storage" "External"

        nvidiaRepo = softwareSystem "NVIDIA CUDA Repository" "CUDA toolkit RPMs and GPU libraries" "External"
        amdROCmRepo = softwareSystem "AMD ROCm Repository" "ROCm platform RPMs for AMD GPUs" "External"
        pypi = softwareSystem "PyPI" "Python package index" "External"

        # Relationships
        dataScientist -> rhoaiDashboard "Selects workbench image via UI"
        dataScientist -> kubeRBACProxy "Accesses notebook via HTTPS/8443"
        mlEngineer -> elyraController "Configures pipeline with runtime images"

        kubeRBACProxy -> jupyterWorkbenches "Proxies to HTTP/8888 (pod-local, no TLS)"
        kubeRBACProxy -> codeServerWorkbench "Proxies to HTTP/8787 (pod-local, no TLS)"
        kubeRBACProxy -> rstudioWorkbench "Proxies to HTTP/8787 (pod-local, no TLS)"

        rhoaiOperator -> imageStreamManifests "Deploys kustomize manifests to create ImageStreams"
        rhoaiOperator -> containerRegistry "Pulls images by SHA256 digest" "HTTPS/443"
        notebookController -> jupyterWorkbenches "Creates StatefulSet pods, injects sidecar"
        notebookController -> codeServerWorkbench "Creates StatefulSet pods, injects sidecar"
        notebookController -> rstudioWorkbench "Creates StatefulSet pods, injects sidecar"
        rhoaiDashboard -> imageStreamManifests "Reads ImageStream annotations for image catalog"

        elyraController -> pipelineRuntimes "Uses as container image for pipeline steps"
        pipelineRuntimes -> objectStorage "Reads/writes pipeline artifacts" "HTTPS/443"

        jupyterWorkbenches -> openshiftAPI "oc CLI commands from within notebooks" "HTTPS/6443"
        jupyterWorkbenches -> containerRegistry "skopeo image inspection" "HTTPS/443"

        # Build-time dependencies
        jupyterWorkbenches -> nvidiaRepo "CUDA RPMs (GPU images only)" "HTTPS/443"
        jupyterWorkbenches -> amdROCmRepo "ROCm RPMs (ROCm images only)" "HTTPS/443"
        jupyterWorkbenches -> pypi "Python packages via micropipenv" "HTTPS/443"
    }

    views {
        systemContext notebooksDownstream "SystemContext" {
            include *
            autoLayout
        }

        container notebooksDownstream "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #f5a623
                color #ffffff
            }
            element "workbench" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "runtime" {
                background #78909c
                color #ffffff
                shape Hexagon
            }
            element "manifest" {
                background #f5a623
                color #ffffff
                shape Folder
            }
        }
    }
}

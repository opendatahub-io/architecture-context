workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs interactive data science workbenches and ML pipelines"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform deployment and workbench image lifecycle"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Container image factory producing Jupyter, Code-Server, and pipeline runtime images for OpenDataHub and RHOAI" {
            jupyterMinimal = container "Jupyter Minimal" "Base Jupyter workbench with JupyterLab, PDF export" "Python 3.12, JupyterLab 4.5" "Container Image"
            jupyterDataScience = container "Jupyter DataScience" "Extended workbench with NumPy, Pandas, SciPy, scikit-learn, Elyra" "Python 3.12" "Container Image"
            jupyterPyTorch = container "Jupyter PyTorch" "GPU-accelerated workbench with PyTorch" "Python 3.12, CUDA/ROCm" "Container Image"
            jupyterTensorFlow = container "Jupyter TensorFlow" "GPU-accelerated workbench with TensorFlow" "Python 3.12, CUDA/ROCm" "Container Image"
            jupyterTrustyAI = container "Jupyter TrustyAI" "AI fairness and explainability workbench" "Python 3.12, Java 17" "Container Image"
            codeServer = container "Code-Server" "VS Code in the browser with nginx proxy and idle culling" "TypeScript, nginx, httpd" "Container Image"
            runtimeImages = container "Pipeline Runtime Images" "Lightweight images for Elyra pipeline node execution" "Python 3.12" "Container Image"
            baseImages = container "GPU Base Images" "CUDA and ROCm base images on CentOS Stream 9" "c9s, Python 3.12" "Container Image"
            imageStreams = container "ImageStream Manifests" "Kustomize manifests defining OpenShift ImageStreams" "Kustomize YAML"
            buildSystem = container "Build System" "Makefile orchestration with lockfile generation" "Make, Go, Python"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests to OpenShift clusters" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for launching and managing workbenches" "Internal ODH"
        notebookController = softwareSystem "Kubeflow Notebook Controller" "Manages Notebook CR lifecycle, injects kube-rbac-proxy sidecars" "Internal ODH"
        dspa = softwareSystem "Data Science Pipelines Application" "KFP-compatible pipeline orchestration" "Internal ODH"
        elyra = softwareSystem "Elyra" "JupyterLab extension for visual pipeline editing" "Internal ODH"
        konflux = softwareSystem "Konflux Build System" "Hermetic CI/CD build system using Tekton and cachi2" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io and quay.io image storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "External"
        gpuRuntime = softwareSystem "GPU Runtime" "NVIDIA CUDA or AMD ROCm GPU compute stack" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Selects workbench flavor" "HTTPS/443"
        dataScientist -> notebooks "Uses workbench for interactive data science" "HTTPS/443 via kube-rbac-proxy"
        platformAdmin -> konflux "Triggers image builds" "HTTPS"

        # Relationships - Build
        konflux -> notebooks "Builds images hermetically" "Tekton + cachi2"
        notebooks -> containerRegistry "Pushes built images" "HTTPS/443 TLS 1.2+"

        # Relationships - Deployment
        imageStreams -> rhodsOperator "Consumed by operator for cluster deployment" "Kustomize"
        rhodsOperator -> odhDashboard "Makes workbenches available in UI" "Kubernetes API"
        notebookController -> notebooks "Injects kube-rbac-proxy sidecar, mounts CA certs" "Webhook"

        # Relationships - Runtime
        notebooks -> dspa "Submits Elyra pipeline runs" "HTTPS/443 SA Token"
        notebooks -> kubernetesAPI "kubectl/oc commands from workbench" "HTTPS/6443 SA Token"
        notebooks -> containerRegistry "Pulls images at pod startup" "HTTPS/443 Token"
        notebookController -> notebooks "Polls /api/kernels/ for idle culling" "HTTPS/8443"
        dspa -> runtimeImages "Launches pipeline pods with runtime images" "Kubernetes"

        # Relationships - Internal
        jupyterMinimal -> jupyterDataScience "Base for" "Dockerfile FROM"
        jupyterDataScience -> jupyterPyTorch "Base for" "Dockerfile FROM"
        jupyterDataScience -> jupyterTensorFlow "Base for" "Dockerfile FROM"
        jupyterDataScience -> jupyterTrustyAI "Base for" "Dockerfile FROM"
        baseImages -> jupyterPyTorch "GPU base" "Dockerfile FROM"
        baseImages -> jupyterTensorFlow "GPU base" "Dockerfile FROM"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Container Image" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
        }
    }
}

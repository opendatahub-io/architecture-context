workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML experiments in interactive workbenches"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and notebook image lifecycle"

        notebooks = softwareSystem "Notebooks" "Container image build system producing 18 workbench and pipeline runtime images for RHOAI" {
            jupyterMinimal = container "jupyter-minimal" "Minimal JupyterLab workbench with Python 3.12" "Container Image (CPU/CUDA/ROCm)"
            jupyterDatascience = container "jupyter-datascience" "Data science JupyterLab with ML/analytics packages" "Container Image (CPU)"
            jupyterPytorch = container "jupyter-pytorch" "JupyterLab with PyTorch deep learning framework" "Container Image (CUDA 13.0)"
            jupyterPytorchLLM = container "jupyter-pytorch+llmcompressor" "JupyterLab with PyTorch and LLM Compressor" "Container Image (CUDA 13.0)"
            jupyterTensorflow = container "jupyter-tensorflow" "JupyterLab with TensorFlow deep learning framework" "Container Image (CUDA 12.9)"
            jupyterTrustyai = container "jupyter-trustyai" "JupyterLab with TrustyAI explainability (Java 17)" "Container Image (CPU)"
            codeserver = container "codeserver" "VS Code Server IDE with nginx proxy" "Container Image (CPU)"
            runtimeMinimal = container "runtime-minimal" "Lightweight Elyra pipeline runtime" "Container Image (CPU)"
            runtimeDatascience = container "runtime-datascience" "Data science Elyra pipeline runtime" "Container Image (CPU)"
            runtimePytorch = container "runtime-pytorch" "PyTorch Elyra pipeline runtime" "Container Image (CUDA 13.0)"
            runtimeTensorflow = container "runtime-tensorflow" "TensorFlow Elyra pipeline runtime" "Container Image (CUDA 12.9)"
            runtimeROCm = container "runtime-rocm-*" "ROCm pipeline runtimes (PyTorch + TensorFlow)" "Container Image (ROCm 7.1)"
            imagestreams = container "ImageStream Manifests" "18 OpenShift ImageStream definitions in manifests/rhoai/" "Kustomize YAML"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys and manages RHOAI components" "Internal RHOAI"
        odhNotebookController = softwareSystem "odh-notebook-controller" "Creates workbench pods, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing workbenches and ML workflows" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration engine" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and serves ML model metadata" "Internal RHOAI"

        aipccBaseImages = softwareSystem "AIPCC Base Images" "CPU, CUDA, and ROCm base container images from quay.io/aipcc/base-images/*" "External AIPCC"
        konflux = softwareSystem "Konflux" "CI/CD build system with hermetic Cachi2 dependency prefetch" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/opendatahub/workbench-images)" "External"
        s3Storage = softwareSystem "S3 Object Storage" "User-configured data storage for notebooks and experiments" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Kubernetes API server for cluster operations" "External"
        aipccPyPI = softwareSystem "AIPCC PyPI Index" "Red Hat AI Python package index (packages.redhat.com)" "External AIPCC"

        # Relationships
        datascientist -> rhoaiDashboard "Selects workbench type" "HTTPS/443"
        datascientist -> notebooks "Uses workbench for ML experiments" "HTTPS/443 via Gateway"
        platformAdmin -> konflux "Triggers image builds" "HTTPS/443"

        notebooks -> s3Storage "Reads/writes experiment data" "HTTPS/443 AWS IAM"
        notebooks -> kubeflowPipelines "Submits pipeline runs (runtime images)" "HTTPS/443 Bearer"

        rhodsOperator -> imagestreams "Reads ImageStream manifests" "File (kustomize)"
        rhodsOperator -> openshiftAPI "Creates/updates ImageStream resources" "HTTPS/6443 SA token"
        odhNotebookController -> notebooks "Creates workbench pods from ImageStreams" "Kubernetes API"
        rhoaiDashboard -> openshiftAPI "Reads ImageStream annotations" "HTTPS/6443 User token"
        kubeflowPipelines -> notebooks "Executes pipeline steps using runtime images" "Container"

        aipccBaseImages -> notebooks "Provides base container images" "HTTPS/443 Registry"
        konflux -> notebooks "Builds all 16 Konflux Dockerfiles" "Hermetic build"
        konflux -> quayRegistry "Pushes built images" "HTTPS/443 Registry token"
        konflux -> aipccPyPI "Pre-fetches Python packages via Cachi2" "HTTPS/443"
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
            element "External AIPCC" {
                background #d4a017
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container Image (CPU)" {
                background #d5e8d4
            }
            element "Container Image (CUDA 13.0)" {
                background #dae8fc
            }
            element "Container Image (CUDA 12.9)" {
                background #dae8fc
            }
            element "Container Image (ROCm 7.1)" {
                background #e1d5e7
            }
            element "Container Image (CPU/CUDA/ROCm)" {
                background #fff2cc
            }
        }
    }
}

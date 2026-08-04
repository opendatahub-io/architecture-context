workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML workloads in notebook environments"

        notebooks = softwareSystem "Notebooks" "Container image factory producing JupyterLab, Code Server, and runtime workbench images for RHOAI with CPU, CUDA, and ROCm accelerator variants" {
            jupyterlabMinimal = container "JupyterLab Minimal" "Base notebook with Python 3.12 on UBI9" "Container Image"
            jupyterlabDatascience = container "JupyterLab DataScience" "Notebook with scikit-learn, pandas, numpy, matplotlib" "Container Image"
            jupyterlabPytorch = container "JupyterLab PyTorch" "Notebook with PyTorch, torchvision" "Container Image"
            jupyterlabTensorflow = container "JupyterLab TensorFlow" "Notebook with TensorFlow" "Container Image"
            jupyterlabTrustyai = container "JupyterLab TrustyAI" "Notebook with TrustyAI explainability toolkit" "Container Image"
            jupyterlabLlmcompressor = container "JupyterLab LLM Compressor" "Notebook with llmcompressor, auto-round for model quantization" "Container Image"
            codeServer = container "Code Server" "VS Code-based notebook environment" "Container Image"
            runtimeImages = container "Runtime Images" "Lightweight execution environments for pipeline steps" "Container Image"
            startNotebook = container "start-notebook.sh" "Entrypoint launching JupyterLab with env-var driven configuration" "Shell Script"
            imageStreams = container "ImageStream Manifests" "Kustomize-managed image metadata for platform discovery" "Kubernetes Resources"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Reconciles Notebook CRs into StatefulSet pods with oauth-proxy sidecar" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Discovers notebook images via ImageStreams, creates Notebook CRs" "Internal RHOAI"
        konflux = softwareSystem "Konflux Pipeline" "Builds container images with hermetic dependency prefetching (Cachi2)" "External Build"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Platform authentication for notebook access" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for resource management" "External"
        kubeflowPipelines = softwareSystem "KubeFlow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts and datasets" "External"
        mlflowTracking = softwareSystem "MLflow Tracking" "Experiment tracking and model registry" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed computing framework" "Internal RHOAI"

        # Build-time relationships
        konflux -> notebooks "Builds container images"

        # Platform relationships
        rhoaiDashboard -> notebooks "Discovers images via ImageStreams"
        rhoaiDashboard -> notebookController "Creates Notebook CRs"
        notebookController -> notebooks "Deploys as StatefulSet pods"
        notebookController -> openshiftOAuth "Injects oauth-proxy sidecar"

        # User relationships
        dataScientist -> rhoaiDashboard "Selects workbench image"
        dataScientist -> notebooks "Accesses via oauth-proxy"

        # User-initiated integrations (from notebook sessions)
        notebooks -> kubernetesAPI "kubernetes client" "HTTPS/443"
        notebooks -> kubeflowPipelines "kfp SDK" "HTTPS/443"
        notebooks -> s3Storage "boto3 client" "HTTPS/443"
        notebooks -> mlflowTracking "mlflow client" "HTTP/HTTPS"
        notebooks -> codeflare "codeflare-sdk" "HTTP/HTTPS"
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
            element "External Build" {
                background #d79b00
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
        }
    }
}

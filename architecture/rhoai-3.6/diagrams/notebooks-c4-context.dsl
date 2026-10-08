workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, trains models, runs experiments"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines"

        notebooks = softwareSystem "Notebooks" "Container image factory producing Jupyter, Code-Server, and Elyra runtime images for RHOAI workbenches" {
            jupyterMinimal = container "jupyter/minimal" "Minimal JupyterLab workbench with core Python and Jupyter packages" "Container Image (Python 3.12, UBI 9)"
            jupyterDatascience = container "jupyter/datascience" "Data science JupyterLab with pandas, scikit-learn, ONNX, Elyra, Kale" "Container Image (Python 3.12, UBI 9)"
            jupyterPytorch = container "jupyter/pytorch" "PyTorch CUDA JupyterLab for GPU-accelerated deep learning" "Container Image (Python 3.12, CUDA 13.0)"
            jupyterPytorchLLMC = container "jupyter/pytorch+llmcompressor" "PyTorch + LLM Compressor for model quantization" "Container Image (Python 3.12, CUDA 13.0)"
            jupyterTensorflow = container "jupyter/tensorflow" "TensorFlow CUDA JupyterLab" "Container Image (Python 3.12, CUDA 13.0)"
            jupyterTrustyai = container "jupyter/trustyai" "TrustyAI JupyterLab for AI explainability" "Container Image (Python 3.12, UBI 9)"
            codeserver = container "codeserver" "VS Code in the browser with data science tooling" "Container Image (Python 3.12, UBI 9)"
            runtimeMinimal = container "runtimes/minimal" "Headless Python runtime for Elyra pipeline execution" "Container Image (Python 3.12, UBI 9)"
            runtimePytorch = container "runtimes/pytorch" "PyTorch CUDA Elyra pipeline runtime" "Container Image (Python 3.12, CUDA 13.0)"
        }

        workbenchesOperator = softwareSystem "Workbenches Operator" "Launches notebook pods from container images via StatefulSets" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Displays available notebook images to users via ImageStream annotations" "Internal RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Executes Elyra pipeline runtimes for pipeline steps" "Internal RHOAI"
        aipccBaseImages = softwareSystem "AIPCC Base Images" "Provides Python runtime, package indexes, and accelerator drivers" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "Build system with Cachi2 hermetic prefetch" "Internal Red Hat"

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for datasets, models, pipeline artifacts" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External"
        mlflowServer = softwareSystem "MLflow" "Experiment tracking and model registry" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        gitRemotes = softwareSystem "Git Remotes" "Source control repositories" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io/rhoai/ - Published images" "External"

        // Build-time relationships
        aipccBaseImages -> notebooks "Provides base images (CPU, CUDA 13.0/12.9, ROCm 7.14)" "Container FROM"
        konflux -> notebooks "Builds images hermetically with Cachi2 prefetch" "CI/CD Pipeline"
        notebooks -> containerRegistry "Publishes digest-pinned images" "Container Push"

        // Consumer relationships
        workbenchesOperator -> containerRegistry "Pulls notebook images to create workbench pods" "HTTPS/443"
        odhDashboard -> containerRegistry "Reads ImageStream annotations for notebook catalog" "Kubernetes API"
        dataSciencePipelines -> containerRegistry "Pulls runtime images for pipeline steps" "HTTPS/443"

        // Runtime relationships (when notebook images are running)
        dataScientist -> workbenchesOperator "Requests notebook workbench" "HTTPS/443"
        mlEngineer -> dataSciencePipelines "Submits pipeline runs" "HTTPS/443"
        jupyterDatascience -> s3Storage "Reads/writes datasets and models" "HTTPS/443"
        jupyterDatascience -> huggingfaceHub "Downloads models" "HTTPS/443"
        jupyterDatascience -> mlflowServer "Logs experiments" "HTTP(S)"
        jupyterDatascience -> kubernetesAPI "KFP SDK, K8s client operations" "HTTPS/443"
        jupyterDatascience -> gitRemotes "Source control via jupyterlab-git" "HTTPS/443"
        runtimeMinimal -> s3Storage "Pipeline artifact storage" "HTTPS/443"
        runtimeMinimal -> kubernetesAPI "K8s client operations" "HTTPS/443"
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
            element "Internal Red Hat" {
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape Person
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

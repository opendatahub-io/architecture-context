workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML notebooks, submits pipelines, tracks experiments"

        notebooks = softwareSystem "RHOAI Notebooks" "Container image definitions for Jupyter Notebook and Workbench environments with ML frameworks and platform SDK integrations" {
            minimalNotebook = container "minimal-notebook" "Base JupyterLab environment on UBI9 with Python 3.12" "Python/JupyterLab"
            datascienceNotebook = container "datascience-notebook" "JupyterLab with scikit-learn, pandas, matplotlib, platform SDKs" "Python/JupyterLab"
            pytorchNotebook = container "pytorch-notebook" "JupyterLab with PyTorch and CUDA support" "Python/JupyterLab"
            pytorchLLMNotebook = container "pytorch-llmcompressor-notebook" "JupyterLab with PyTorch, LLMCompressor, and Transformers" "Python/JupyterLab"
            tensorflowNotebook = container "tensorflow-notebook" "JupyterLab with TensorFlow and CUDA support" "Python/JupyterLab"
            rocmPytorchNotebook = container "rocm-pytorch-notebook" "JupyterLab with PyTorch and AMD ROCm GPU support" "Python/JupyterLab"
            rocmTensorflowNotebook = container "rocm-tensorflow-notebook" "JupyterLab with TensorFlow and AMD ROCm GPU support" "Python/JupyterLab"
            buildInputs = container "buildinputs" "Build utility for Konflux CI pipeline" "Go Executable"
            checkPayload = container "check-payload" "Payload verification for Konflux CI pipeline" "Go Executable"
        }

        notebookController = softwareSystem "RHOAI Notebook Controller" "Manages notebook pod lifecycle, injects OAuth Proxy sidecar, creates Routes" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "User-facing web UI for managing notebooks, data science projects" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare / Ray" "Distributed computing framework for ML workloads" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking, model registry, and model serving" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "AI explainability and fairness toolkit" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes / OpenShift API" "Cluster API for resource management" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data and model artifacts" "External"
        konfluxCI = softwareSystem "Konflux CI/CD" "Build pipeline for container images" "External"
        oauthProxy = softwareSystem "OAuth Proxy" "OpenShift OAuth authentication sidecar" "External"

        # Relationships
        dataScientist -> dashboard "Manages notebooks via" "HTTPS/443"
        dataScientist -> notebooks "Accesses JupyterLab via" "HTTPS/443 (through OAuth Proxy)"
        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        notebookController -> notebooks "Manages pod lifecycle" "Kubernetes API"
        notebookController -> oauthProxy "Injects sidecar into notebook pods" "Pod spec"
        oauthProxy -> notebooks "Forwards authenticated requests" "HTTP/8888"
        notebooks -> kubeflowPipelines "Submits pipeline runs" "HTTPS (kfp SDK)"
        notebooks -> codeflare "Submits distributed jobs" "HTTPS/gRPC (codeflare-sdk)"
        notebooks -> mlflow "Logs experiments, tracks models" "HTTPS (mlflow SDK)"
        notebooks -> trustyai "Runs explainability analysis" "Python API (trustyai SDK)"
        notebooks -> kubernetesAPI "Manages cluster resources" "HTTPS/6443 (kubernetes SDK)"
        notebooks -> s3Storage "Reads/writes data and model artifacts" "HTTPS/443 (boto3)"
        konfluxCI -> buildInputs "Uses during image builds" "Build pipeline"
        konfluxCI -> checkPayload "Validates image payloads" "Build pipeline"
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

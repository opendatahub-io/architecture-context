workspace {
    model {
        user = person "Data Scientist" "Submits RAG evaluation jobs via Llama Stack API"

        llamaStackProvider = softwareSystem "llama-stack-provider-ragas" "Out-of-tree Llama Stack evaluation provider integrating Ragas for RAG pipeline quality assessment" {
            inlineProvider = container "Inline Provider" "Executes Ragas evaluations in-process using host server APIs (max_workers=1)" "Python Llama Stack Provider"
            remoteProvider = container "Remote Provider" "Offloads Ragas evaluations to Kubeflow Pipelines with S3 result storage" "Python Llama Stack Provider"
            compatLayer = container "Compatibility Layer" "Supports both llama_stack and llama_stack_api package layouts" "Python Module"
            kfpImage = container "KFP Component Image" "Container image for Kubeflow pipeline steps" "Container (UBI9 Python 3.12)"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "FastAPI/uvicorn server hosting provider plugins, inference, embeddings, and dataset APIs" "Internal"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines (Data Science Pipelines)" "Workflow orchestration for ML pipelines" "Internal Platform"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for evaluation results" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for ConfigMap reads and service account tokens" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides base image configuration via ConfigMap" "Internal Platform"
        ollama = softwareSystem "Ollama" "LLM inference backend (sample distribution)" "External"

        # User interactions
        user -> llamaStackServer "Submits eval jobs via" "HTTP/8321"
        llamaStackServer -> llamaStackProvider "Dispatches evaluations to" "In-process Python API"

        # Inline provider flows
        inlineProvider -> llamaStackServer "Uses inference and embedding APIs" "In-process"

        # Remote provider flows
        remoteProvider -> kubeflowPipelines "Submits and monitors pipelines" "HTTPS/443 Bearer token"
        remoteProvider -> s3Storage "Reads evaluation results" "HTTPS/443 AWS IAM"
        remoteProvider -> kubernetesAPI "Reads ConfigMaps for base image" "HTTPS/443"

        # KFP pod flows
        kfpImage -> llamaStackServer "Retrieves datasets and runs inference" "HTTP (configurable)"
        kfpImage -> s3Storage "Stores evaluation results" "HTTPS/443 AWS IAM"

        # Platform dependencies
        remoteProvider -> trustyaiOperator "Resolves base image from ConfigMap" "Kubernetes API"
        llamaStackServer -> ollama "LLM inference (sample distro)" "HTTP/11434"
    }

    views {
        systemContext llamaStackProvider "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackProvider "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

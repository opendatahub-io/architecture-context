workspace {
    model {
        dataScientist = person "Data Scientist" "Evaluates RAG pipeline quality using Ragas metrics via Llama Stack Eval API"

        llamaStackServer = softwareSystem "Llama Stack Server" "Hosts Llama Stack providers and exposes unified ML APIs on port 8321" {
            evalAPI = container "Eval API" "Handles benchmark registration and evaluation job lifecycle" "Python / Llama Stack Framework"
            inlineProvider = container "Ragas Inline Provider" "Runs Ragas evaluation in-process with LangChain adapters wrapping Inference API" "Python / ragas 0.3.0"
            remoteProvider = container "Ragas Remote Provider" "Submits evaluation jobs to Kubeflow Pipelines with async job tracking and S3 result storage" "Python / kfp SDK"
            inferenceAPI = container "Inference API" "Provides LLM completions and embeddings via pluggable backends" "Python / Llama Stack Framework"
            datasetIOAPI = container "DatasetIO API" "Manages evaluation datasets" "Python / Llama Stack Framework"
            benchmarksAPI = container "Benchmarks API" "Manages benchmark definitions with dataset and scoring function references" "Python / Llama Stack Framework"
            filesAPI = container "Files API" "File storage for datasets and results" "Python / Llama Stack Framework"
            compatLayer = container "Compatibility Layer" "Handles import compatibility between llama_stack and llama_stack_api module layouts" "Python"
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines (Data Science Pipelines)" "Orchestrates multi-step ML workflows in isolated containers" "External"
        ollama = softwareSystem "Ollama" "Local LLM inference server for completions and embeddings" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for evaluation result persistence" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with container image references for KFP components" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for ConfigMap reads and ServiceAccount token management" "External"

        # Person relationships
        dataScientist -> llamaStackServer "Submits evaluation jobs and retrieves results" "HTTP/8321"

        # Internal container relationships
        evalAPI -> inlineProvider "Dispatches inline evaluation requests"
        evalAPI -> remoteProvider "Dispatches remote evaluation requests"
        inlineProvider -> inferenceAPI "LLM completions and embeddings (in-process)"
        inlineProvider -> datasetIOAPI "Retrieves evaluation datasets (in-process)"
        remoteProvider -> kubeflowPipelines "Submits KFP pipelines, polls status" "HTTPS/443 Bearer Token"
        remoteProvider -> s3Storage "Fetches evaluation results" "HTTPS/443 AWS IAM"
        remoteProvider -> kubernetesAPI "Reads ConfigMap for base image" "HTTPS/443 SA Token"

        # External relationships
        inferenceAPI -> ollama "LLM completions and embeddings" "HTTP/11434"
        kubeflowPipelines -> llamaStackServer "KFP pods call back for inference and datasets" "HTTP/8321"
        kubeflowPipelines -> s3Storage "KFP Step 2 writes evaluation results" "HTTPS/443 AWS IAM"
        trustyaiOperator -> llamaStackServer "Provides ragas-provider-image via ConfigMap" "ConfigMap"
    }

    views {
        systemContext llamaStackServer "SystemContext" {
            include *
            autoLayout
            description "System context showing llama-stack-provider-ragas within the Llama Stack ecosystem"
        }

        container llamaStackServer "Containers" {
            include *
            autoLayout
            description "Container view showing Ragas provider internals and external integrations"
        }

        styles {
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
                background #5ba3f5
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
        }
    }
}

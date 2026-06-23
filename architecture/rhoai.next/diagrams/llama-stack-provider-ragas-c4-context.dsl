workspace {
    model {
        datascientist = person "Data Scientist" "Runs LLM evaluations using Ragas metrics via Llama Stack eval API"

        llamaStackProviderRagas = softwareSystem "llama-stack-provider-ragas" "Ragas evaluation provider for Llama Stack, supporting inline and remote (Kubeflow) execution modes" {
            inlineProvider = container "Inline Provider" "Runs Ragas evaluation in-process within Llama Stack server" "Python Llama Stack Provider"
            remoteProvider = container "Remote Provider" "Submits Ragas evaluation as Kubeflow Pipeline runs" "Python Llama Stack Provider"
            inlineWrappers = container "Inline LLM/Embedding Wrappers" "Adapts Llama Stack inference API to Ragas/LangChain interfaces" "Python Adapter Classes"
            remoteWrappers = container "Remote LLM/Embedding Wrappers" "Adapts llama-stack-client SDK to Ragas/LangChain interfaces" "Python Adapter Classes"
            kfpComponents = container "KFP Pipeline Components" "Two-step Kubeflow pipeline: data retrieval and Ragas evaluation" "Python KFP Components"
            compatLayer = container "Compatibility Layer" "Handles llama_stack vs llama_stack_api package migration" "Python Module"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Hosts providers and exposes eval/inference/datasetIO APIs" "Internal"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines (Data Science Pipelines)" "Kubernetes-native ML pipeline orchestration" "Internal Platform"
        ollama = softwareSystem "Inference Provider (Ollama/vLLM)" "LLM inference and embedding generation" "Internal"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap for base image resolution" "Internal Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "MinIO or AWS S3 for evaluation result persistence" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for ConfigMap/Secret access" "External"

        datascientist -> llamaStackServer "Submits eval requests via HTTP" "HTTP/8321"
        llamaStackServer -> llamaStackProviderRagas "Routes eval API calls to provider"

        inlineProvider -> inlineWrappers "Uses for LLM/embedding calls"
        inlineWrappers -> llamaStackServer "In-process inference API calls" "Python API"

        remoteProvider -> kubeflowPipelines "Submits pipeline runs" "HTTPS/443 Bearer Token"
        remoteProvider -> s3Storage "Fetches evaluation results" "HTTPS/443 AWS IAM"
        remoteProvider -> kubernetesAPI "Reads ConfigMaps for image resolution" "HTTPS/6443"

        kfpComponents -> llamaStackServer "Retrieves datasets and runs inference" "HTTP/8321"
        kfpComponents -> s3Storage "Persists evaluation results (JSONL)" "HTTPS/443 AWS IAM"
        kfpComponents -> remoteWrappers "Uses for LLM/embedding calls in KFP pods"

        llamaStackServer -> ollama "Delegates inference requests" "HTTP"
        trustyaiOperator -> llamaStackProviderRagas "Provides ragas-provider-image via ConfigMap" "Kubernetes API"
    }

    views {
        systemContext llamaStackProviderRagas "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackProviderRagas "Containers" {
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

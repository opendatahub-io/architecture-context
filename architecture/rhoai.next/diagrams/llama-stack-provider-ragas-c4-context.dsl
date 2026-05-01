workspace {
    model {
        dataScientist = person "Data Scientist" "Submits evaluation jobs against LLM benchmarks"

        llamaStackProviderRagas = softwareSystem "llama-stack-provider-ragas" "Out-of-tree Llama Stack evaluation provider implementing Ragas-based LLM evaluation with inline and remote execution modes" {
            inlineProvider = container "Inline Eval Provider" "Runs Ragas evaluation in-process within Llama Stack server" "Python Library"
            remoteProvider = container "Remote Eval Provider" "Submits Ragas evaluation as Kubeflow Pipeline runs" "Python Library"
            inlineWrappers = container "Inline Wrappers" "Adapts Llama Stack inference API to Ragas BaseRagasLLM/BaseRagasEmbeddings" "Python Adapter"
            remoteWrappers = container "Remote Wrappers" "Adapts Llama Stack HTTP client to Ragas interfaces for KFP execution" "Python Adapter"
            kfpPipeline = container "KFP Pipeline" "Two-step pipeline: retrieve dataset then run Ragas evaluation" "Kubeflow Pipeline"
            compatLayer = container "Compatibility Layer" "Backward compatibility between llama_stack and llama_stack_api packages" "Python Module"
        }

        llamaStack = softwareSystem "Llama Stack Server" "Meta's Llama Stack platform hosting eval, inference, datasetio APIs" "Internal"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines (DSP)" "Pipeline orchestration platform on OpenShift" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for evaluation results" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for ConfigMap reads and auth" "Infrastructure"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap for base image resolution" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "LLM inference and embedding backend" "External"

        // User interactions
        dataScientist -> llamaStack "Submits evaluation jobs" "HTTP/8321"
        llamaStack -> llamaStackProviderRagas "Routes eval requests to provider" "Python Plugin API"

        // Internal container relationships
        inlineProvider -> inlineWrappers "Uses for Ragas LLM/Embeddings adaptation"
        remoteProvider -> remoteWrappers "Uses in KFP pods"
        remoteProvider -> kfpPipeline "Constructs and submits"
        inlineProvider -> compatLayer "Imports compatibility shims"
        remoteProvider -> compatLayer "Imports compatibility shims"

        // External interactions
        inlineProvider -> llamaStack "Calls inference/datasetio APIs" "In-process Python"
        remoteProvider -> kubeflowPipelines "Submits pipeline runs, polls status" "HTTPS/443 Bearer Token"
        remoteProvider -> s3Storage "Fetches evaluation results" "HTTPS/443 AWS IAM"
        kfpPipeline -> llamaStack "Retrieves datasets, calls inference" "HTTP/8321"
        kfpPipeline -> s3Storage "Writes evaluation results (JSONL)" "HTTPS/443 AWS IAM"
        remoteProvider -> k8sAPI "Reads ConfigMaps, loads kubeconfig" "HTTPS/443 SA Token"
        remoteProvider -> trustyaiOperator "Reads base image config" "via ConfigMap"
        llamaStack -> ollama "Inference and embeddings" "HTTP/11434"
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
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

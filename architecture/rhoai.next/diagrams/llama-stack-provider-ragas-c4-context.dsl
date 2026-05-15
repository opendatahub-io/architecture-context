workspace {
    model {
        dataScientist = person "Data Scientist" "Submits evaluation benchmarks and retrieves Ragas metric scores via the Llama Stack Eval API"

        llamaStackWithRagas = softwareSystem "Llama Stack + Ragas Provider" "Llama Stack server with llama-stack-provider-ragas plugin providing Ragas evaluation over the Eval API" {
            llamaStackServer = container "Llama Stack Server" "Hosts the Eval API on port 8321/TCP, dispatches to registered providers" "Python / Llama Stack Framework"
            inlineProvider = container "Inline Provider" "Runs Ragas evaluation in-process using wrapped Llama Stack inference APIs" "Python Plugin (RagasEvaluatorInline)"
            remoteProvider = container "Remote Provider" "Submits Ragas evaluation as Kubeflow Pipelines jobs for distributed execution" "Python Plugin (RagasEvaluatorRemote)"
            llmWrappers = container "LLM/Embedding Wrappers" "Adapts Llama Stack inference API to LangChain/Ragas-compatible interfaces" "Python Adapters"
            kfpComponents = container "KFP Pipeline Components" "Two-step pipeline: data retrieval + Ragas evaluation" "Python / KFP DSL"
            compatLayer = container "Compatibility Layer" "Supports both llama_stack and llama_stack_api import paths" "Python Module"
        }

        ollama = softwareSystem "Ollama / vLLM" "LLM inference backend providing text completion and embedding generation" "External"
        kfp = softwareSystem "Kubeflow Pipelines (Data Science Pipelines)" "Orchestrates evaluation pipeline runs as Kubernetes pods" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Stores and retrieves evaluation results in JSONL format (AWS S3 or MinIO)" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Provides ConfigMap reads and kubeconfig for service discovery" "Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides trustyai-service-operator-config ConfigMap for image resolution" "Internal RHOAI"
        ragas = softwareSystem "Ragas Framework" "Core evaluation framework: answer_relevancy, context_precision, faithfulness, context_recall" "External Library"

        # External relationships
        dataScientist -> llamaStackWithRagas "Submits evaluations, checks status, retrieves results" "HTTP/8321"
        llamaStackWithRagas -> ollama "LLM completions and embedding generation" "HTTP/11434"
        llamaStackWithRagas -> kfp "Submits and monitors evaluation pipeline runs" "HTTPS/443"
        llamaStackWithRagas -> s3 "Stores and retrieves evaluation results" "HTTPS/443"
        llamaStackWithRagas -> k8sAPI "Reads ConfigMaps, loads kubeconfig" "HTTPS/6443"
        llamaStackWithRagas -> trustyaiOperator "Reads ragas-provider-image from ConfigMap" "Kubernetes API"

        # Internal container relationships
        llamaStackServer -> inlineProvider "Dispatches inline eval requests" "Python API"
        llamaStackServer -> remoteProvider "Dispatches remote eval requests" "Python API"
        inlineProvider -> llmWrappers "Uses inline wrappers for inference" "Python API"
        remoteProvider -> llmWrappers "Uses remote wrappers for inference" "Python API"
        remoteProvider -> kfpComponents "Submits pipeline definitions" "KFP SDK"
        inlineProvider -> compatLayer "Resolves Llama Stack imports" "Python import"
        remoteProvider -> compatLayer "Resolves Llama Stack imports" "Python import"
        inlineProvider -> ragas "Executes Ragas evaluate()" "Python API"
        kfpComponents -> ragas "Executes Ragas evaluate() in pipeline pods" "Python API"
    }

    views {
        systemContext llamaStackWithRagas "SystemContext" {
            include *
            autoLayout
            description "System context showing llama-stack-provider-ragas in the RHOAI ecosystem"
        }

        container llamaStackWithRagas "Containers" {
            include *
            autoLayout
            description "Internal container view showing provider components and their relationships"
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #d79b00
                color #ffffff
            }
            element "External Library" {
                background #b8860b
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

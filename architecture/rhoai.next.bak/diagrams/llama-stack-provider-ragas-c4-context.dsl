workspace {
    model {
        user = person "Data Scientist" "Runs LLM evaluation benchmarks via the Llama Stack eval API"

        llamaStackProviderRagas = softwareSystem "llama-stack-provider-ragas" "Out-of-tree Llama Stack eval provider implementing Ragas evaluation metrics in inline and remote (KFP) execution modes" {
            inlineProvider = container "RagasEvaluatorInline" "Runs Ragas evaluation in-process within the Llama Stack server" "Python"
            remoteProvider = container "RagasEvaluatorRemote" "Submits evaluation pipelines to Kubeflow Pipelines for distributed execution" "Python"
            config = container "RagasProviderConfig" "Configuration model with pydantic validation for inline/remote modes" "Python"
            wrapperInline = container "LlamaStackInlineLLM / Embeddings" "Adapts Llama Stack inference API to Ragas LangChain interfaces (in-process)" "Python"
            wrapperRemote = container "LlamaStackRemoteLLM / Embeddings" "Adapts Llama Stack inference API to Ragas LangChain interfaces (HTTP client)" "Python"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Host runtime providing eval, inference, dataset, benchmark, and files APIs" {
            tags "Internal RHOAI"
        }

        llamaStackOperator = softwareSystem "Llama Stack Operator" "Deploys Llama Stack distributions on OpenShift via LlamaStackDistribution CRD" {
            tags "Internal RHOAI"
        }

        kfp = softwareSystem "Kubeflow Pipelines (Data Science Pipelines)" "Pipeline orchestration platform for remote evaluation execution" {
            tags "Internal RHOAI"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with base image reference for KFP pipeline components" {
            tags "Internal RHOAI"
        }

        ollama = softwareSystem "Ollama" "LLM inference backend for development/demo" {
            tags "External"
        }

        vllm = softwareSystem "vLLM" "Production LLM inference backend on OpenShift AI" {
            tags "External"
        }

        s3 = softwareSystem "S3-compatible Object Storage" "Stores evaluation result JSONL files" {
            tags "External"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for ConfigMap reads and kubeconfig loading" {
            tags "External"
        }

        ragas = softwareSystem "Ragas Framework" "Core evaluation library providing faithfulness, answer_relevancy, context_precision, context_recall metrics" {
            tags "External Library"
        }

        user -> llamaStackServer "Submits evaluation jobs via" "HTTP/8321"
        llamaStackServer -> llamaStackProviderRagas "Loads as eval plugin"

        inlineProvider -> wrapperInline "Uses for LLM/embedding calls"
        remoteProvider -> wrapperRemote "Uses for LLM/embedding calls"
        inlineProvider -> ragas "Calls evaluate() with metrics"
        remoteProvider -> ragas "Calls evaluate() in KFP pod"

        llamaStackProviderRagas -> llamaStackServer "Uses inference, dataset, benchmark, files APIs" "In-process / HTTP/8321"
        llamaStackProviderRagas -> kfp "Submits and monitors pipeline runs" "HTTPS/443 + Bearer Token"
        llamaStackProviderRagas -> s3 "Stores/retrieves evaluation results" "HTTPS/443 + AWS IAM"
        llamaStackProviderRagas -> k8sApi "Reads ConfigMap, loads kubeconfig" "HTTPS/443 + SA Token"
        llamaStackProviderRagas -> trustyaiOperator "Reads trustyai-service-operator-config ConfigMap for base image"

        llamaStackServer -> ollama "LLM inference (dev/demo)" "HTTP/11434"
        llamaStackServer -> vllm "LLM inference (production)" "HTTPS/8443 + Bearer Token"

        llamaStackOperator -> llamaStackServer "Deploys via LlamaStackDistribution CRD"
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
            element "External Library" {
                background #b8860b
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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

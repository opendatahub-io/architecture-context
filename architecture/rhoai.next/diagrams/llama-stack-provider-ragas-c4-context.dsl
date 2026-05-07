workspace {
    model {
        datascientist = person "Data Scientist" "Runs RAG evaluation benchmarks against LLM applications"
        mlEngineer = person "ML Engineer" "Configures evaluation pipelines and reviews metrics"

        llamaStackServer = softwareSystem "Llama Stack Server" "Standardized LLM application framework hosting inference and evaluation APIs" {
            evalRouter = container "Eval API Router" "Routes /alpha/eval/* requests to registered provider" "Python / Llama Stack Framework"

            ragasInlineProvider = container "Ragas Inline Provider" "Runs Ragas evaluation in-process with LLM/Embedding wrappers" "Python Plugin" "inline::trustyai_ragas"
            ragasRemoteProvider = container "Ragas Remote Provider" "Submits evaluation as KFP pipeline and retrieves results from S3" "Python Plugin" "remote::trustyai_ragas"

            compatLayer = container "Compatibility Layer" "Bridges llama_stack and llama_stack_api import paths" "Python Module"

            inferenceAPI = container "Inference API" "Provides LLM completions and embedding generation" "Llama Stack Provider"
            datasetioAPI = container "DatasetIO API" "Manages evaluation datasets" "Llama Stack Provider"
        }

        kfp = softwareSystem "Kubeflow Pipelines (DSP)" "Orchestrates containerized ML pipeline runs on OpenShift" "External"
        s3 = softwareSystem "S3-compatible Object Storage" "Stores evaluation result JSONL files" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides ConfigMap and token access" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages trustyai-service-operator-config ConfigMap with base image reference" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "Local inference backend (development only)" "External Dev"

        # User interactions
        datascientist -> llamaStackServer "Submits evaluation jobs via Eval API" "HTTP/8321"
        mlEngineer -> llamaStackServer "Configures and monitors evaluation pipelines" "HTTP/8321"

        # Internal container relationships
        evalRouter -> ragasInlineProvider "Routes inline eval requests"
        evalRouter -> ragasRemoteProvider "Routes remote eval requests"
        ragasInlineProvider -> compatLayer "Uses"
        ragasRemoteProvider -> compatLayer "Uses"
        ragasInlineProvider -> inferenceAPI "LLM completions + embeddings (in-process)"
        ragasInlineProvider -> datasetioAPI "Loads evaluation dataset rows (in-process)"

        # External relationships
        ragasRemoteProvider -> kfp "Submits pipeline runs, checks status, cancels" "HTTPS/443 Bearer Token"
        ragasRemoteProvider -> s3 "Reads evaluation results" "HTTPS/443 AWS IAM"
        ragasRemoteProvider -> k8sAPI "Reads ConfigMap for base image, extracts kubeconfig token" "HTTPS/6443 Bearer Token"

        kfp -> llamaStackServer "KFP pods fetch data and run inference" "HTTP/8321"
        kfp -> s3 "KFP pods write evaluation results" "HTTPS/443 AWS IAM"

        trustyaiOperator -> k8sAPI "Manages trustyai-service-operator-config ConfigMap"
        llamaStackServer -> ollama "Inference requests (dev distribution)" "HTTP/11434"
    }

    views {
        systemContext llamaStackServer "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackServer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Dev" {
                background #cccccc
                color #333333
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

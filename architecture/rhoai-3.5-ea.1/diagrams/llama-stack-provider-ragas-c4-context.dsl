workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Evaluates RAG systems using Ragas metrics through Llama Stack eval API"

        llamaStackServer = softwareSystem "Llama Stack Server" "Meta's Llama Stack platform hosting inference, eval, and datasetio APIs" {
            ragasProvider = container "llama-stack-provider-ragas" "Ragas evaluation provider with inline and remote execution modes" "Python Library (Llama Stack Provider Plugin)"
            evalAPI = container "Eval API" "Exposes /alpha/eval/* endpoints for evaluation" "HTTP 8321/TCP"
            inferenceAPI = container "Inference API" "OpenAI-compatible completions and embeddings" "HTTP 8321/TCP"
            datasetioAPI = container "DatasetIO API" "Dataset registration and retrieval" "HTTP 8321/TCP"
        }

        containerImage = softwareSystem "odh-trustyai-ragas-lls-provider-dsp-rhel9" "KFP pipeline component base image for remote Ragas evaluation" "Container Image"

        kubeflowPipelines = softwareSystem "Data Science Pipelines (Kubeflow Pipelines)" "Pipeline orchestration for remote evaluation mode" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Object Storage" "Stores evaluation result JSONL files" "External"
        inferenceBackend = softwareSystem "Ollama / vLLM" "LLM completions and embedding generation" "Internal"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap for base image resolution" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "ConfigMap reads and kubeconfig token extraction" "Internal"

        # Relationships
        user -> llamaStackServer "Submits evaluation jobs via POST /alpha/eval/run_eval" "HTTP/8321"
        user -> llamaStackServer "Queries job status via GET /alpha/eval/job_status" "HTTP/8321"
        user -> llamaStackServer "Retrieves results via GET /alpha/eval/job_result" "HTTP/8321"

        evalAPI -> ragasProvider "Delegates evaluation calls" "In-process Python"
        ragasProvider -> inferenceAPI "LLM completions and embeddings (inline mode)" "In-process Python"
        ragasProvider -> datasetioAPI "Retrieve evaluation datasets" "In-process Python"

        ragasProvider -> kubeflowPipelines "Submits pipeline runs (remote mode)" "HTTPS/443 Bearer Token"
        ragasProvider -> s3Storage "Fetches evaluation results" "HTTPS/443 AWS IAM"
        ragasProvider -> k8sAPI "Reads ConfigMap for base image" "HTTPS/6443 SA Token"
        ragasProvider -> trustyaiOperator "Reads trustyai-service-operator-config ConfigMap" "Kubernetes API"

        kubeflowPipelines -> containerImage "Uses as pipeline step base image" "Container Runtime"
        containerImage -> llamaStackServer "HTTP calls for dataset retrieval and inference" "HTTP/8321"
        containerImage -> s3Storage "Writes evaluation results" "HTTPS/443 AWS IAM"

        llamaStackServer -> inferenceBackend "Forwards LLM/embedding requests" "HTTP/11434"
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
                background #438DD5
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #85bbf0
                color #ffffff
            }
            element "Container Image" {
                background #f5a623
                color #ffffff
            }
        }
    }
}

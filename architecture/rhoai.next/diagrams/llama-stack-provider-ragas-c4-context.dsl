workspace {
    model {
        user = person "Data Scientist" "Runs RAG evaluation jobs against LLM-generated outputs"

        llamaStackProviderRagas = softwareSystem "Llama Stack Provider Ragas" "Out-of-tree Llama Stack Eval provider implementing Ragas metrics for RAG evaluation via inline and remote execution modes" {
            inlineProvider = container "Ragas Inline Provider" "Runs Ragas evaluation in-process within the Llama Stack server using async wrappers" "Python Library (Llama Stack Plugin)"
            remoteProvider = container "Ragas Remote Provider" "Submits Ragas evaluations as Kubeflow Pipeline runs and retrieves results from S3" "Python Library (Llama Stack Plugin)"
            kfpComponents = container "KFP Pipeline Components" "Two-step pipeline: data retrieval from Llama Stack and Ragas evaluation execution" "Python (KFP DSL)"
            compatLayer = container "Compatibility Layer" "Bridges legacy llama_stack and newer llama_stack_api import paths" "Python Module"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Hosts provider plugins and exposes Eval API on 8321/TCP" "Internal"
        kfp = softwareSystem "Kubeflow Pipelines (DSP)" "Orchestrates containerized evaluation pipeline runs" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages trustyai-service-operator-config ConfigMap with base image references" "Internal RHOAI"
        s3 = softwareSystem "S3 Object Storage" "Stores evaluation result JSONL files" "External"
        k8sApi = softwareSystem "Kubernetes API" "Provides ConfigMap access and kubeconfig token extraction" "External"
        ollama = softwareSystem "Ollama" "Inference backend for sample/dev distribution" "External (dev only)"

        # User interactions
        user -> llamaStackServer "Submits evaluation jobs via Eval API" "HTTP/8321"

        # System relationships
        llamaStackServer -> llamaStackProviderRagas "Delegates eval requests to provider plugin" "In-process"
        inlineProvider -> llamaStackServer "Calls Inference API (LLM + Embeddings) and DatasetIO" "In-process"
        remoteProvider -> kfp "Submits pipeline runs, polls status, cancels runs" "HTTPS/443, Bearer Token"
        remoteProvider -> s3 "Reads evaluation results" "HTTPS/443, AWS IAM"
        remoteProvider -> k8sApi "Reads ConfigMap for base image, extracts kubeconfig token" "HTTPS/6443, Bearer Token"
        kfpComponents -> llamaStackServer "Retrieves datasets and runs inference" "HTTP/8321"
        kfpComponents -> s3 "Writes evaluation results (JSONL)" "HTTPS/443, AWS IAM"
        llamaStackProviderRagas -> trustyaiOperator "Reads ragas-provider-image from ConfigMap" "HTTPS/6443 via K8s API"
        llamaStackServer -> ollama "Inference backend (dev distribution)" "HTTP/11434"
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
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "External (dev only)" {
                background #cccccc
                color #333333
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape roundedbox
            }
            element "Container" {
                shape roundedbox
            }
        }
    }
}

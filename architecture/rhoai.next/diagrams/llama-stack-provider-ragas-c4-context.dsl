workspace {
    model {
        datascientist = person "Data Scientist" "Runs RAG evaluation benchmarks against LLM applications"
        mlops = person "MLOps Engineer" "Manages evaluation pipelines and infrastructure"

        llamaStackServer = softwareSystem "Llama Stack Server" "Host server for Llama Stack providers, exposes Eval/Inference/DatasetIO APIs on 8321/TCP" {
            ragasProvider = container "llama-stack-provider-ragas" "Out-of-tree Llama Stack Eval provider implementing Ragas metrics" "Python 3.12 Plugin" {
                inlineProvider = component "Ragas Inline Provider" "Runs Ragas evaluation in-process with max_workers=1" "Python / inline::trustyai_ragas"
                remoteProvider = component "Ragas Remote Provider" "Submits evaluations as KFP pipeline runs" "Python / remote::trustyai_ragas"
                compatLayer = component "Compatibility Layer" "Bridges llama_stack and llama_stack_api import paths" "Python / compat.py"
                llmWrapper = component "LlamaStackInlineLLM" "Adapts Llama Stack Inference API to BaseRagasLLM" "Python / LangChain adapter"
                embWrapper = component "LlamaStackInlineEmbeddings" "Adapts Llama Stack Inference API to BaseRagasEmbeddings" "Python / LangChain adapter"
                kfpComponents = component "KFP Pipeline Components" "Two-step pipeline: data retrieval + Ragas evaluation" "Python / KFP DSL"
            }
            inferenceAPI = container "Inference API" "LLM completions and embedding generation" "Llama Stack Provider"
            datasetIOAPI = container "DatasetIO API" "Dataset row retrieval" "Llama Stack Provider"
        }

        kfp = softwareSystem "Data Science Pipelines (Kubeflow)" "Pipeline orchestration for scalable evaluation jobs" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages TrustyAI components, provides ConfigMap with base image" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Object Storage" "Stores evaluation result JSONL files" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "ConfigMap access and kubeconfig token extraction" "Platform"
        ollama = softwareSystem "Ollama" "Local inference backend for development" "External Dev-Only"

        // User interactions
        datascientist -> llamaStackServer "POST /alpha/eval/run-eval (inline or remote)" "HTTP/8321"
        datascientist -> llamaStackServer "GET /alpha/eval/job-status, /alpha/eval/job-result" "HTTP/8321"
        mlops -> kfp "Monitors pipeline runs" "HTTPS/443"

        // Internal flows
        inlineProvider -> inferenceAPI "LLM completions + embeddings" "In-process"
        inlineProvider -> datasetIOAPI "get_rows_paginated()" "In-process"
        llmWrapper -> inferenceAPI "Adapts to BaseRagasLLM interface" "In-process"
        embWrapper -> inferenceAPI "Adapts to BaseRagasEmbeddings interface" "In-process"
        inlineProvider -> compatLayer "Import path resolution" "In-process"
        remoteProvider -> compatLayer "Import path resolution" "In-process"
        remoteProvider -> kfpComponents "Constructs pipeline" "In-process"

        // Egress flows
        remoteProvider -> kfp "Submit/monitor/cancel pipeline runs" "HTTPS/443 Bearer Token"
        remoteProvider -> s3 "Read evaluation results via s3fs/pandas" "HTTPS/443 AWS IAM"
        remoteProvider -> k8sAPI "Read trustyai-service-operator-config ConfigMap" "HTTPS/6443 Bearer Token"
        kfpComponents -> llamaStackServer "Retrieve datasets, run inference" "HTTP/8321"
        kfpComponents -> s3 "Write evaluation results JSONL" "HTTPS/443 AWS IAM"
        ragasProvider -> trustyaiOperator "Read ragas-provider-image from ConfigMap" "Via K8s API"

        // Dev only
        llamaStackServer -> ollama "Inference (dev distribution only)" "HTTP/11434"
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

        component ragasProvider "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Dev-Only" {
                background #f8cecc
                color #000000
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
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

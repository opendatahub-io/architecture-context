workspace {
    model {
        datascientist = person "Data Scientist" "Runs LLM evaluation benchmarks via Llama Stack"

        llamaStackServer = softwareSystem "Llama Stack Server" "LLM application framework with pluggable providers" {
            evalRouter = container "Eval Router" "Routes evaluation requests to registered providers" "Llama Stack Core"
            inferenceAPI = container "Inference API" "Provides LLM inference capabilities" "Llama Stack Core"
            datasetioAPI = container "DatasetIO API" "Provides dataset access (iterrows)" "Llama Stack Core"
            filesAPI = container "Files API" "Provides file management" "Llama Stack Core"
            benchmarksAPI = container "Benchmarks API" "Provides benchmark definitions" "Llama Stack Core"

            ragasProvider = container "llama-stack-provider-ragas" "Ragas evaluation as trustyai_ragas provider (inline + remote)" "Python Provider Plugin" {
                inlineEval = component "RagasEvaluatorInline" "Runs Ragas evaluation in-process with max_workers=1" "Python"
                remoteEval = component "RagasEvaluatorRemote" "Submits evaluation pipelines to Kubeflow Pipelines" "Python"
                inlineLLM = component "LlamaStackInlineLLM" "Wraps Llama Stack Inference API as Ragas-compatible LLM" "Python"
                inlineEmbeddings = component "LlamaStackInlineEmbeddings" "Wraps Llama Stack Inference API as Ragas-compatible embeddings" "Python"
                kfpPipeline = component "KFP Pipeline Definition" "Two-step DAG: retrieve_data + run_ragas_evaluation" "Python"
            }
        }

        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for evaluation results" "External"
        k8s = softwareSystem "Kubernetes API" "Container orchestration platform" "External"

        # User interactions
        datascientist -> llamaStackServer "Submits evaluation requests via Eval API"

        # Internal provider interactions
        evalRouter -> ragasProvider "Routes eval requests to trustyai_ragas provider"
        inlineEval -> inferenceAPI "LLM inference calls via Ragas wrappers" "In-process"
        inlineEval -> datasetioAPI "Retrieves datasets via iterrows" "In-process"
        inlineLLM -> inferenceAPI "Wraps as Ragas-compatible interface" "In-process"
        inlineEmbeddings -> inferenceAPI "Wraps as Ragas-compatible interface" "In-process"

        # External interactions (remote mode)
        remoteEval -> kfp "Submits pipeline DAG, polls run status" "HTTP/Bearer Token"
        remoteEval -> s3 "Fetches evaluation results" "HTTPS/AWS IAM"
        kfpPipeline -> s3 "Writes results.jsonl" "HTTPS/AWS IAM"
        kfp -> llamaStackServer "KFP pods retrieve datasets from Llama Stack API" "HTTP"
        kfpPipeline -> k8s "Mounts AWS credentials from Secret" "use_secret_as_env"
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
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Submits evaluation jobs using Ragas metrics against LLM benchmarks"

        llamaStackServer = softwareSystem "Llama Stack Server" "Meta's Llama Stack platform hosting inference, evaluation, and dataset APIs" {
            evalAPI = container "Eval API" "Handles /alpha/eval/* endpoints for evaluation lifecycle" "Python / Llama Stack"
            inferenceAPI = container "Inference API" "Provides LLM completions and embeddings" "Python / Llama Stack"
            datasetIOAPI = container "DatasetIO API" "Manages dataset storage and retrieval" "Python / Llama Stack"

            ragasProvider = container "llama-stack-provider-ragas" "Ragas evaluation provider plugin with inline and remote execution modes" "Python Library" {
                inlineProvider = component "RagasEvaluatorInline" "Runs Ragas evaluation in-process using Llama Stack inference API" "Python / inline::trustyai_ragas"
                remoteProvider = component "RagasEvaluatorRemote" "Submits Ragas evaluation as Kubeflow Pipeline runs" "Python / remote::trustyai_ragas"
                inlineLLM = component "LlamaStackInlineLLM" "Adapts Llama Stack inference to Ragas BaseRagasLLM interface" "Python Adapter"
                inlineEmbed = component "LlamaStackInlineEmbeddings" "Adapts Llama Stack inference to Ragas BaseRagasEmbeddings interface" "Python Adapter"
                remoteLLM = component "LlamaStackRemoteLLM" "HTTP-based adapter for remote Ragas LLM calls" "Python Adapter"
                remoteEmbed = component "LlamaStackRemoteEmbeddings" "HTTP-based adapter for remote Ragas embeddings calls" "Python Adapter"
                kfpPipeline = component "KFP Pipeline Builder" "Constructs two-step KFP pipeline: retrieve_data -> run_ragas" "Python / KFP SDK"
                compatLayer = component "Compatibility Layer" "Supports both llama_stack and llama_stack_api package layouts" "Python Module"
            }
        }

        kubeflowPipelines = softwareSystem "Kubeflow Pipelines (DSP)" "Orchestrates ML pipeline runs on OpenShift" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for evaluation results in JSONL format" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API for ConfigMap reads and service account tokens" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap for base image resolution" "Internal RHOAI"
        ollama = softwareSystem "Ollama" "Local LLM inference and embedding server (sample distribution)" "External"

        # User interactions
        dataScientist -> evalAPI "Submits evaluation jobs" "HTTP/8321"

        # Internal flows
        evalAPI -> ragasProvider "Routes eval requests to provider"
        inlineProvider -> inferenceAPI "LLM completions and embeddings" "Python in-process"
        inlineProvider -> datasetIOAPI "Retrieves dataset rows" "Python in-process"

        # Remote provider egress
        remoteProvider -> kubeflowPipelines "Submits and monitors KFP pipeline runs" "HTTPS/443 Bearer Token"
        remoteProvider -> s3Storage "Reads evaluation results" "HTTPS/443 AWS IAM"
        remoteProvider -> kubernetesAPI "Reads ConfigMaps for base image" "HTTPS/443 SA Token"

        # KFP pipeline pod flows
        kubeflowPipelines -> inferenceAPI "KFP pods call back for inference" "HTTP/8321 (no TLS)"
        kubeflowPipelines -> datasetIOAPI "KFP pods retrieve datasets" "HTTP/8321 (no TLS)"
        kubeflowPipelines -> s3Storage "KFP pods write results" "HTTPS/443 AWS IAM"

        # TrustyAI integration
        trustyaiOperator -> ragasProvider "Provides base image config via ConfigMap" "Kubernetes API"
    }

    views {
        systemContext llamaStackServer "SystemContext" {
            include *
            autoLayout
            description "System context showing llama-stack-provider-ragas within Llama Stack ecosystem"
        }

        container llamaStackServer "Containers" {
            include *
            autoLayout
            description "Container view showing provider plugin architecture within Llama Stack Server"
        }

        component ragasProvider "Components" {
            include *
            autoLayout
            description "Component view showing inline and remote evaluation providers with adapters"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
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
        }
    }
}

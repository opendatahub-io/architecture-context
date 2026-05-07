workspace {
    model {
        dataScientist = person "Data Scientist" "Submits LLM evaluation jobs via Llama Stack eval API"
        mlEngineer = person "ML Engineer" "Configures evaluation pipelines and deployment"

        llamaStackServer = softwareSystem "Llama Stack Server" "Meta's Llama Stack distribution server hosting inference, eval, and dataset APIs on 8321/TCP" {
            evalAPI = container "Eval API" "Routes evaluation requests to registered provider plugins" "Python / Llama Stack"
            ragasProvider = container "llama-stack-provider-ragas" "Ragas evaluation provider with inline and remote execution modes" "Python Plugin" {
                inlineProvider = component "RagasEvaluatorInline" "Executes Ragas metrics in-process within the Llama Stack server" "Python"
                remoteProvider = component "RagasEvaluatorRemote" "Submits evaluation jobs to Kubeflow Pipelines for distributed execution" "Python"
                compatLayer = component "compat.py" "Backward compatibility across Llama Stack API reorganization" "Python"
                configModule = component "config.py" "Pydantic configuration for inline/remote providers" "Python"
            end
            inferenceAPI = container "Inference API" "Provides LLM completions and embeddings via configured backend" "Python / Llama Stack"
            datasetIOAPI = container "DatasetIO API" "Manages evaluation datasets" "Python / Llama Stack"
        end

        kfpImage = softwareSystem "KFP Base Image" "odh-trustyai-ragas-lls-provider-dsp-rhel9 - UBI9 Python 3.12 container for KFP pipeline steps" "Container Image"

        kubeflowPipelines = softwareSystem "Data Science Pipelines (Kubeflow)" "Orchestrates distributed pipeline runs on OpenShift" "Internal RHOAI"
        s3Storage = softwareSystem "S3-compatible Storage" "Persists evaluation results as JSONL" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for ConfigMap reads and pod management" "Infrastructure"
        llamaStackOperator = softwareSystem "Llama Stack Operator" "Deploys Llama Stack server via LlamaStackDistribution CRD" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Manages trustyai-service-operator-config ConfigMap with base image config" "Internal RHOAI"
        inferenceBackend = softwareSystem "Ollama / vLLM" "Backend model serving for LLM inference and embeddings" "External / Internal"

        # Relationships
        dataScientist -> llamaStackServer "Submits evaluation jobs" "HTTP/8321"
        mlEngineer -> llamaStackOperator "Configures LlamaStackDistribution CR" "kubectl"

        evalAPI -> ragasProvider "Routes eval API calls"
        ragasProvider -> inferenceAPI "LLM completions and embeddings" "In-process Python API"
        ragasProvider -> datasetIOAPI "Retrieves evaluation datasets" "In-process Python API"

        inlineProvider -> inferenceAPI "In-process inference calls" "Python API"
        remoteProvider -> kubeflowPipelines "Submits and monitors pipeline runs" "HTTPS / Bearer Token"
        remoteProvider -> s3Storage "Reads evaluation results" "HTTPS/443 / AWS IAM"

        kubeflowPipelines -> llamaStackServer "KFP pods call for inference and datasets" "HTTP/8321"
        kubeflowPipelines -> s3Storage "KFP pods write evaluation results" "HTTPS/443 / AWS IAM"

        ragasProvider -> kubernetesAPI "Reads ConfigMap for base image" "HTTPS/6443 / SA Token"
        llamaStackOperator -> llamaStackServer "Deploys and manages" "Kubernetes CRD"
        trustyaiOperator -> kubernetesAPI "Manages ConfigMap" "Kubernetes API"
        inferenceAPI -> inferenceBackend "Model inference requests" "HTTP/11434 or HTTPS/8443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                background #f5a623
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

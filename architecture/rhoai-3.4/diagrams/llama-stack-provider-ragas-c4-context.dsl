workspace {
    model {
        user = person "Data Scientist" "Creates and runs LLM evaluation benchmarks via the Llama Stack Eval API"

        llamaStackProvider = softwareSystem "llama-stack-provider-ragas" "Ragas-based LLM evaluation provider for Llama Stack with inline and remote execution modes" {
            inlineEvaluator = container "Inline Evaluator" "Runs Ragas evaluation synchronously in-process using Llama Stack Inference API" "Python / Ragas"
            remoteEvaluator = container "Remote Evaluator" "Submits evaluation jobs to Kubeflow Pipelines for distributed async execution" "Python / KFP SDK"
            wrappers = container "LLM/Embedding Wrappers" "Adapts Llama Stack APIs to Ragas BaseRagasLLM/BaseRagasEmbeddings interfaces" "Python / LangChain-core"
            config = container "Configuration" "Pydantic models for RagasConfig and KubeflowConfig with env var and ConfigMap resolution" "Python / Pydantic"
            compat = container "Compatibility Layer" "Import-time abstraction over llama_stack vs llama_stack_api package structure" "Python"
        }

        llamaStackServer = softwareSystem "Llama Stack Distribution Server" "Hosts Eval, Inference, DatasetIO APIs on port 8321/TCP" "Internal Platform"
        llamaStackOperator = softwareSystem "Llama Stack Operator" "Manages LlamaStackDistribution CRs and deployment lifecycle" "Internal Platform"
        dsPipelines = softwareSystem "Data Science Pipelines (Kubeflow)" "Runs evaluation workloads as pipeline steps on Kubernetes" "Internal Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with ragas-provider-image for base image resolution" "Internal Platform"
        vllm = softwareSystem "vLLM / Model Serving" "Inference backend for LLM completions and embeddings" "Internal Platform"

        s3 = softwareSystem "S3-compatible Storage" "Stores and retrieves evaluation results as JSONL files" "External"
        k8sApi = softwareSystem "Kubernetes API" "Provides ConfigMap reads and kubeconfig loading" "External"

        // User interactions
        user -> llamaStackServer "Creates evaluation benchmarks via Eval API" "HTTP/8321"
        llamaStackServer -> llamaStackProvider "Delegates Eval API calls to provider" "In-process"

        // Internal provider interactions
        inlineEvaluator -> wrappers "Uses LLM/embedding wrappers"
        remoteEvaluator -> wrappers "Configures remote LLM/embedding wrappers"

        // Provider to external
        llamaStackProvider -> llamaStackServer "Calls Inference and DatasetIO APIs" "HTTP/8321 (in-process or remote)"
        llamaStackProvider -> dsPipelines "Submits and monitors pipeline runs" "HTTPS/443 Bearer Token"
        llamaStackProvider -> s3 "Reads evaluation results" "HTTPS/443 AWS IAM"
        llamaStackProvider -> k8sApi "Reads ConfigMaps, loads kubeconfig" "HTTPS/443 SA Token"

        // Platform relationships
        llamaStackOperator -> llamaStackServer "Manages deployment via LlamaStackDistribution CR"
        trustyaiOperator -> llamaStackProvider "Provides ragas-provider-image via ConfigMap"
        llamaStackServer -> vllm "Routes inference requests to backend" "HTTP(S)/8443"
        dsPipelines -> s3 "Writes evaluation results from pipeline pods" "HTTPS/443 AWS IAM"
        dsPipelines -> llamaStackServer "Pipeline pods call Llama Stack APIs" "HTTP/8321"
    }

    views {
        systemContext llamaStackProvider "SystemContext" {
            include *
            autoLayout
        }

        container llamaStackProvider "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Software System" {
                background #1168BD
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #000000
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        securityEngineer = person "Security Engineer" "Defines and triggers LLM red-teaming evaluations"

        garakAdapter = softwareSystem "llama-stack-provider-trustyai-garak" "Garak red-teaming evaluation adapter that runs AI safety benchmarks as Kubernetes Jobs" {
            adapter = container "Garak Adapter" "FrameworkAdapter implementation bridging Garak with eval-hub" "Python 3.12+"
            credentialResolver = container "Credential Resolver" "Multi-layer cascade for model API keys and AWS credentials" "Python"
            s3Uploader = container "S3 Results Uploader" "Uploads evaluation results and sanitized configs to S3" "Python / boto3"
        }

        evalHub = softwareSystem "Eval-Hub" "Evaluation orchestration platform that triggers and manages evaluations" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform for running Garak in separate pods" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for reading Secrets and ServiceAccount tokens" "Infrastructure"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for evaluation results and configurations" "External"
        llmEndpoint = softwareSystem "Target LLM Endpoint" "LLM API endpoint under evaluation (red-teaming target)" "External"

        # Relationships
        securityEngineer -> evalHub "Configures and triggers evaluations"
        evalHub -> garakAdapter "Provides evaluation configuration"

        garakAdapter -> llmEndpoint "Executes Garak red-teaming probes" "HTTPS / Model API Key"
        garakAdapter -> s3Storage "Uploads results and sanitized configs" "HTTPS/443 / AWS IAM"
        garakAdapter -> kfp "Submits pipeline runs (KFP mode)" "HTTPS / Bearer SA Token"
        garakAdapter -> k8sAPI "Reads Secrets for AWS credentials" "HTTPS/6443 / SA Token"

        # Container relationships
        adapter -> credentialResolver "Resolves model API keys"
        adapter -> s3Uploader "Sends results for upload"
        credentialResolver -> k8sAPI "Reads Secrets" "HTTPS/6443"
        s3Uploader -> s3Storage "Uploads via boto3" "HTTPS/443"
    }

    views {
        systemContext garakAdapter "SystemContext" {
            include *
            autoLayout
        }

        container garakAdapter "Containers" {
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

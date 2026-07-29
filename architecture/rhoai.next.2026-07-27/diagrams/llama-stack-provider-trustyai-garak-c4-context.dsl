workspace {
    model {
        datascientist = person "Data Scientist / AI Safety Engineer" "Configures and triggers red-teaming evaluations"

        evalhub = softwareSystem "eval-hub Platform" "Evaluation orchestration platform that manages K8s Jobs" {
            evalhubCore = container "eval-hub Core" "Manages evaluation lifecycle and job orchestration" "Kubernetes"
            sidecarProxy = container "Sidecar Proxy" "Injects auth and proxies result callbacks" "Container Sidecar"
        }

        garakAdapter = softwareSystem "llama-stack-provider-trustyai-garak" "Garak red-teaming evaluation adapter for eval-hub with dual execution modes" {
            adapter = container "GarakAdapter" "FrameworkAdapter implementation, orchestrates evaluation pipeline" "Python v0.5.1"
            credentialResolver = container "Credential Resolver" "Role-based API key resolution with 6 roles and 5-step priority chain" "Python Module"
            s3Utils = container "S3 Utilities" "Upload/download artifacts to S3-compatible storage" "Python Module (boto3)"
            pipelineSteps = container "Pipeline Steps" "Core evaluation logic, ART intents, report parsing" "Python Module"
        }

        garakEngine = softwareSystem "Garak" "NVIDIA red-teaming framework for LLM safety evaluation" "External"
        sdgHub = softwareSystem "sdg-hub" "Synthetic data generation for AI safety intents" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration for distributed execution" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for config, artifacts, and results" "External"
        targetModel = softwareSystem "Target Model" "LLM endpoint under evaluation (red-teaming target)" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for result persistence" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "Infrastructure"

        # User interactions
        datascientist -> evalhub "Configures evaluation benchmarks"
        evalhub -> garakAdapter "Launches K8s Job with ConfigMap"

        # Adapter internal flows
        adapter -> credentialResolver "Resolves API keys per role"
        adapter -> pipelineSteps "Orchestrates evaluation steps"
        pipelineSteps -> s3Utils "Uploads/downloads artifacts"

        # External interactions
        garakAdapter -> garakEngine "Executes subprocess (simple mode)"
        garakAdapter -> kfp "Submits pipeline (KFP mode)" "KFP SDK / KFP_AUTH_TOKEN"
        garakAdapter -> s3Storage "Uploads config, downloads results" "HTTPS / AWS Credentials"
        garakAdapter -> targetModel "Red-teaming inference probes" "HTTPS / API Key"
        garakAdapter -> ociRegistry "Persists scan artifacts" "HTTPS / Registry Credentials"
        garakAdapter -> k8sApi "K8s resource operations" "HTTPS/6443 / SA Token"
        garakAdapter -> sdgHub "Synthetic data generation for ART intents"
        garakAdapter -> sidecarProxy "Reports results via callback" "HTTP localhost"
        sidecarProxy -> evalhubCore "Forwards aggregated results"
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
            }
            element "Infrastructure" {
                background #d6b656
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

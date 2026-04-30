workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM security evaluations"
        securityEngineer = person "Security Engineer" "Reviews vulnerability scan results and red-teaming reports"

        garakProvider = softwareSystem "llama-stack-provider-trustyai-garak" "Garak-based LLM security evaluation provider for Llama Stack and eval-hub" {
            inlineProvider = container "Inline Provider" "Runs Garak scans as local subprocesses within Llama Stack server" "Python Library"
            remoteProvider = container "Remote Provider" "Submits Garak scans as Kubeflow Pipelines on Kubernetes" "Python Library"
            evalHubAdapter = container "Eval-Hub Adapter" "Runs Garak scans directly in eval-hub K8s job pods or via KFP" "Python Library"
            coreModule = container "Core Module" "Shared pipeline steps, Garak runner, config resolution, result parsing" "Python Library"
            kfpComponents = container "KFP Components" "Six @dsl.component steps for distributed pipeline execution" "KFP Pipeline"
            shieldOrchestrator = container "Shield Orchestrator" "Input/output guardrail scanning via Llama Stack Safety API" "Python Library"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Standardized LLM application framework providing Files, Safety, Inference APIs" {
            tags "Internal RHOAI"
        }

        kfp = softwareSystem "Data Science Pipelines (KFP)" "Kubeflow Pipelines for distributed ML workflow execution" {
            tags "Internal RHOAI"
        }

        evalHub = softwareSystem "Eval-Hub" "RHOAI evaluation platform for orchestrating benchmark jobs" {
            tags "Internal RHOAI"
        }

        vllm = softwareSystem "vLLM Model Serving" "OpenAI-compatible LLM inference endpoint (target model under test)" {
            tags "External"
        }

        s3 = softwareSystem "S3 / MinIO" "Object storage for evaluation artifacts and model data" {
            tags "External"
        }

        postgresql = softwareSystem "PostgreSQL" "Relational database for Llama Stack server persistence" {
            tags "External"
        }

        sdgModels = softwareSystem "SDG/Judge/Attacker Models" "OpenAI-compatible model endpoints for synthetic data generation, judging, and adversarial attacks" {
            tags "External"
        }

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides Garak container image configuration via ConfigMap" {
            tags "Internal RHOAI"
        }

        ociRegistry = softwareSystem "OCI Registry" "Container registry for persisting scan artifacts" {
            tags "External"
        }

        mlflow = softwareSystem "MLflow" "ML experiment tracking for evaluation metrics" {
            tags "External"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for ConfigMap/Secret reads and kubeconfig" {
            tags "Infrastructure"
        }

        # Relationships
        dataScientist -> llamaStackServer "Submits evaluation benchmarks via" "HTTP/8321"
        dataScientist -> evalHub "Triggers evaluation jobs via" "eval-hub SDK"
        securityEngineer -> garakProvider "Reviews vulnerability reports from"

        llamaStackServer -> garakProvider "Invokes Garak provider for evaluations" "in-process Python API"
        evalHub -> garakProvider "Runs GarakAdapter in K8s job pods" "Python API"

        inlineProvider -> coreModule "Uses shared pipeline logic"
        remoteProvider -> coreModule "Uses shared config resolution"
        evalHubAdapter -> coreModule "Uses shared pipeline steps"
        remoteProvider -> kfpComponents "Defines and submits KFP pipelines"
        evalHubAdapter -> kfpComponents "Defines and submits KFP pipelines"
        inlineProvider -> shieldOrchestrator "Scans inputs/outputs via shields"

        garakProvider -> llamaStackServer "Files API, Safety API, Shields API, Inference API" "HTTP/8321"
        garakProvider -> kfp "Pipeline submission and monitoring" "HTTPS/443"
        garakProvider -> vllm "LLM inference for vulnerability scans" "HTTP(S)/Configurable"
        garakProvider -> s3 "Artifact storage (eval-hub KFP mode)" "HTTPS/443"
        garakProvider -> sdgModels "Synthetic data generation, judging, adversarial attacks" "HTTP(S)/Configurable"
        garakProvider -> k8sAPI "ConfigMap reads, Secret reads" "HTTPS/443"
        garakProvider -> trustyaiOperator "Reads Garak container image config" "K8s API"
        garakProvider -> ociRegistry "Persist scan artifacts (eval-hub)" "HTTPS/443"
        garakProvider -> mlflow "Save evaluation metrics" "HTTP(S)/Configurable"
        llamaStackServer -> postgresql "Persistence backend" "PostgreSQL/5432"
    }

    views {
        systemContext garakProvider "SystemContext" {
            include *
            autoLayout
        }

        container garakProvider "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Submits LLM vulnerability scans and reviews red-teaming results"
        securityEngineer = person "Security Engineer" "Reviews OWASP/AVID/CWE compliance scan reports"

        garakProvider = softwareSystem "TrustyAI Garak LLS Provider" "Llama Stack Eval API provider for LLM red-teaming and vulnerability scanning using NVIDIA Garak" {
            provider = container "Garak Provider" "Core Eval API implementation with benchmark registration, scan orchestration, and result parsing" "Python 3.12 (Llama Stack Provider)"
            inlineAdapter = container "Inline Eval Adapter" "Executes Garak as local subprocess with semaphore concurrency control" "Python Module"
            remoteAdapter = container "Remote Eval Adapter" "Submits scans as Kubeflow Pipeline DAGs" "Python Module"
            evalHubAdapter = container "eval-hub Adapter" "FrameworkAdapter for K8s Job execution with sidecar pattern" "Python Module"
            shieldOrchestrator = container "Shield Scan Orchestrator" "Routes probes through Llama Stack Safety API shields before/after LLM inference" "Python Module"
            sdgEngine = container "SDG Engine" "Generates adversarial prompts from harm taxonomies using sdg-hub flows" "Python Module"
            intentsEngine = container "Intents/CAS Engine" "Parses policy taxonomies and generates CAS topology files for intent-based scanning" "Python Module"
            garakRunner = container "Garak Runner" "Subprocess runner with process group management, timeout handling, log streaming" "Python Module"
            resultParser = container "Result Parser" "Parses Garak reports into EvaluateResponse with TBSA scoring and ART HTML reports" "Python Module"
            kfpComponents = container "KFP Pipeline Components" "6-step pipeline DAG: validate, resolve_taxonomy, sdg_generate, prepare_prompts, scan, parse_results" "Python (KFP dsl.component)"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Hosts Eval, Files, Safety, Inference, and Shields APIs" "Internal RHOAI"
        vllm = softwareSystem "vLLM Inference" "OpenAI-compatible model serving for target LLM" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Kubeflow Pipelines for remote scan execution" "Internal RHOAI"
        s3 = softwareSystem "S3/MinIO" "Object storage for scan artifacts and KFP data transfer" "External"
        postgresql = softwareSystem "PostgreSQL" "Metadata storage backend for Llama Stack server" "External"
        evalHubSidecar = softwareSystem "eval-hub Sidecar" "K8s Job sidecar for lifecycle callbacks, OCI persistence, MLflow logging" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry (Quay.io)" "Container and artifact registry for scan bundle storage" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and metric logging" "External"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap for image resolution" "Internal RHOAI"

        # User interactions
        dataScientist -> garakProvider "Submits vulnerability scans via Eval API" "HTTP/8321"
        securityEngineer -> garakProvider "Reviews compliance scan results" "HTTP/8321"

        # Provider to Llama Stack
        garakProvider -> llamaStackServer "Hosted by; uses Files, Safety, Inference APIs" "HTTP/8321"

        # Provider internal
        provider -> inlineAdapter "Delegates inline scans"
        provider -> remoteAdapter "Delegates remote scans"
        provider -> evalHubAdapter "Delegates eval-hub scans"
        provider -> shieldOrchestrator "Orchestrates shield testing"
        provider -> sdgEngine "Generates adversarial prompts"
        sdgEngine -> intentsEngine "Creates CAS topology"
        inlineAdapter -> garakRunner "Runs Garak subprocess"
        remoteAdapter -> kfpComponents "Compiles pipeline DAG"
        garakRunner -> resultParser "Parses scan outputs"
        kfpComponents -> resultParser "Parses pipeline results"

        # External dependencies
        garakProvider -> vllm "Scans target model" "HTTPS/443"
        garakProvider -> dspa "Submits pipeline runs" "HTTPS/443"
        garakProvider -> s3 "Artifact storage/transfer" "HTTPS/443"
        garakProvider -> evalHubSidecar "Lifecycle callbacks, OCI push, MLflow" "gRPC"
        garakProvider -> ociRegistry "Stores scan artifact bundles" "HTTPS/443"
        garakProvider -> mlflow "Logs metrics and artifacts" "HTTPS/443"
        garakProvider -> trustyaiOperator "Reads ConfigMap for image resolution" "K8s API"
        llamaStackServer -> postgresql "Metadata storage" "TCP/5432"
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
                background #438dd5
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

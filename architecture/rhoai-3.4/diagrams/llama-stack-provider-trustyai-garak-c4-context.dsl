workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM security evaluations via Llama Stack or Eval-Hub"
        securityEngineer = person "Security Engineer" "Reviews vulnerability scan results and guardrail effectiveness"

        garakProvider = softwareSystem "TrustyAI Garak LLS Provider" "Out-of-tree Llama Stack evaluation provider and Eval-Hub adapter for automated LLM red-teaming using Garak" {
            coreLib = container "Core Library" "Shared framework-agnostic utilities: config resolution, command building, scan runner, pipeline steps, result parsing" "Python"
            inlineProvider = container "Inline Provider" "Local subprocess-based garak execution with async job management" "Python Llama Stack Provider"
            remoteProvider = container "Remote Provider" "KFP-based remote garak execution with pipeline submission, polling, and artifact retrieval" "Python Llama Stack Provider"
            evalHubSimple = container "Eval-Hub Simple Adapter" "In-pod garak execution within Eval-Hub K8s jobs" "Python Eval-Hub FrameworkAdapter"
            evalHubKFP = container "Eval-Hub KFP Adapter" "KFP-based execution with S3-mediated artifact transfer" "Python Eval-Hub FrameworkAdapter"
            resultUtils = container "Result Utilities" "Report parsing (JSONL, AVID), TBSA scoring, Vega visualization, Jinja2 HTML report generation" "Python"
            shieldScan = container "Shield Scan" "Guardrail orchestration: input shield → LLM → output shield" "Python"
            intents = container "Intents Module" "Policy taxonomy dataset loading, CAS file generation for TAPIntent probes" "Python"
            sdg = container "SDG Module" "Synthetic adversarial prompt generation via sdg-hub library" "Python"
            containerImage = container "Container Image" "UBI9-based image with provider + garak, used as KFP step base" "Konflux Container"
        }

        llamaStackServer = softwareSystem "Llama Stack Distribution Server" "Hosts providers and routes API calls to registered eval/benchmark providers" "Internal RHOAI"
        llamaStackFilesAPI = softwareSystem "Llama Stack Files API" "Upload/download scan artifacts (reports, configs, datasets)" "Internal RHOAI"
        llamaStackSafetyAPI = softwareSystem "Llama Stack Safety API" "Shield orchestration for guardrail effectiveness testing" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines (DSPA)" "Executes garak scan pipelines as KFP workflow runs" "Internal RHOAI"
        evalHub = softwareSystem "Eval-Hub Platform" "RHOAI evaluation platform that orchestrates framework adapters" "Internal RHOAI"
        vllm = softwareSystem "vLLM Inference Server" "Target LLM endpoint for vulnerability scanning (OpenAI-compatible API)" "External"
        s3 = softwareSystem "S3/MinIO Object Storage" "Stores scan reports, datasets, HTML reports between KFP steps" "External"
        postgres = softwareSystem "PostgreSQL" "Persistence backend for Llama Stack distribution (benchmarks, files)" "External"
        mlflow = softwareSystem "MLflow" "Artifact logging for Eval-Hub mode (HTML reports, CSV datasets)" "Internal RHOAI"
        ociRegistry = softwareSystem "OCI Registry" "Create OCI artifacts for scan results via Eval-Hub callbacks" "External"
        sdgHub = softwareSystem "SDG Hub" "Synthetic data generation API for adversarial prompt creation" "External"

        # Relationships - Users
        dataScientist -> llamaStackServer "Creates eval jobs via" "HTTP/8321 Bearer Token"
        dataScientist -> evalHub "Submits evaluations via" "UI/API"
        securityEngineer -> garakProvider "Reviews scan results"

        # Relationships - Provider registration
        llamaStackServer -> garakProvider "Routes eval/benchmark API calls to" "in-process Python API"

        # Relationships - Inline flow
        inlineProvider -> coreLib "Uses" "Python API"
        inlineProvider -> resultUtils "Parses results with" "Python API"
        inlineProvider -> vllm "Scans target model via garak subprocess" "HTTPS/443 API key"
        inlineProvider -> llamaStackFilesAPI "Uploads scan artifacts" "HTTP/8321 Bearer Token"

        # Relationships - Remote flow
        remoteProvider -> coreLib "Uses" "Python API"
        remoteProvider -> kfp "Submits 6-step pipeline" "HTTPS/443 Bearer Token"
        remoteProvider -> llamaStackFilesAPI "Retrieves results" "HTTP/8321 Bearer Token"

        # Relationships - Eval-Hub flows
        evalHub -> evalHubSimple "Creates K8s Job running" "Eval-Hub SDK"
        evalHub -> evalHubKFP "Creates K8s Job running" "Eval-Hub SDK"
        evalHubSimple -> coreLib "Uses" "Python API"
        evalHubKFP -> kfp "Submits S3-based pipeline" "HTTPS/443 Bearer Token"
        evalHubKFP -> s3 "Stores/retrieves artifacts" "HTTPS/443 AWS IAM"
        evalHubSimple -> mlflow "Logs artifacts" "HTTP/HTTPS Bearer Token"
        evalHubSimple -> ociRegistry "Creates OCI artifacts" "HTTPS/443"

        # Relationships - Shared
        coreLib -> sdg "Generates adversarial prompts" "Python API"
        sdg -> sdgHub "Calls SDG API" "HTTP/HTTPS API key"
        coreLib -> intents "Loads harm taxonomies" "Python API"
        shieldScan -> llamaStackSafetyAPI "Tests guardrails" "HTTP/8321 Bearer Token"
        garakProvider -> postgres "Persists benchmarks/files via LLS" "PostgreSQL/5432 Password"
        kfp -> vllm "KFP pods scan target model" "HTTPS/443 API key"
        kfp -> s3 "KFP pods store artifacts" "HTTPS/443 AWS IAM"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

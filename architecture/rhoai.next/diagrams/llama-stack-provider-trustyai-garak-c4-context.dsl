workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs LLM security evaluations via Llama Stack or eval-hub"
        securityEngineer = person "Security Engineer" "Reviews LLM vulnerability scan results and red-teaming reports"

        garakProvider = softwareSystem "llama-stack-provider-trustyai-garak" "Garak-based LLM security evaluation provider with dual integration: Llama Stack provider and eval-hub adapter" {
            inlineProvider = container "Inline Provider" "Runs Garak scans as local subprocesses within Llama Stack server" "Python Library"
            remoteProvider = container "Remote Provider" "Submits Garak scans as KFP pipeline runs on Kubernetes" "Python Library"
            evalHubAdapter = container "Eval-Hub Adapter" "Runs Garak scans as K8s jobs or KFP pipelines via eval-hub SDK" "Python Library"
            coreModule = container "Core Module" "Shared pipeline steps, Garak runner, config resolution, result parsing" "Python Library"
            kfpComponents = container "KFP Components" "Six @dsl.component pipeline steps for distributed scan execution" "KFP Pipeline"
            shieldOrchestrator = container "Shield Orchestrator" "Input/output guardrail scanning via Llama Stack Safety API" "Python Library"
            resultParser = container "Result Parser" "JSONL/AVID parsing, TBSA scoring, Vega charts, Jinja2 HTML reports" "Python Library"

            inlineProvider -> coreModule "Uses shared pipeline logic"
            remoteProvider -> kfpComponents "Defines and submits KFP pipelines"
            evalHubAdapter -> coreModule "Uses shared pipeline logic"
            evalHubAdapter -> kfpComponents "Defines and submits KFP pipelines"
            coreModule -> resultParser "Parses scan results"
            inlineProvider -> shieldOrchestrator "Runs guardrail scans"
        }

        llamaStackServer = softwareSystem "Llama Stack Server" "Llama Stack framework server with provider registration, benchmark/eval APIs, Files API, Safety API" "Internal Platform"
        kfpServer = softwareSystem "Data Science Pipelines (KFP)" "Kubeflow Pipelines v2 backend for distributed pipeline execution" "Internal Platform"
        vllm = softwareSystem "vLLM / Model Serving" "OpenAI-compatible model inference endpoint (target for vulnerability scans)" "Internal Platform"
        s3 = softwareSystem "S3 / MinIO" "Object storage for KFP pipeline artifacts (eval-hub mode)" "Internal Platform"
        postgresql = softwareSystem "PostgreSQL" "Llama Stack server persistence backend" "Internal Platform"
        evalHub = softwareSystem "Eval-Hub Platform" "RHOAI evaluation orchestration platform with job scheduling" "Internal Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides ConfigMap with Garak container image override" "Internal Platform"

        sdgEndpoint = softwareSystem "SDG Model Endpoint" "Synthetic data generation model for adversarial prompt creation" "External"
        judgeEndpoint = softwareSystem "Judge Model Endpoint" "MulticlassJudge evaluation of model responses" "External"
        attackerEndpoint = softwareSystem "Attacker Model Endpoint" "Tree-of-attacks adversarial prompt generation" "External"
        evaluatorEndpoint = softwareSystem "Evaluator Model Endpoint" "Intent classification evaluation" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container registry for persisting scan artifacts" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking for evaluation metrics" "External"

        dataScientist -> garakProvider "Runs LLM security evaluations" "HTTP/8321 via Llama Stack or eval-hub Job"
        securityEngineer -> garakProvider "Reviews vulnerability scan reports" "HTML reports, JSONL artifacts"

        garakProvider -> llamaStackServer "Provider registration, Files/Safety/Shields/Inference APIs" "HTTP/8321"
        garakProvider -> kfpServer "Pipeline submission, run monitoring" "HTTPS/443"
        garakProvider -> vllm "Target model inference during scans" "HTTP(S) / Bearer Token"
        garakProvider -> s3 "Artifact storage for eval-hub KFP mode" "HTTPS/443 / AWS IAM"
        garakProvider -> postgresql "Llama Stack persistence (indirect)" "PostgreSQL/5432"
        garakProvider -> trustyaiOperator "Read ConfigMap for image override" "K8s API/443"

        garakProvider -> sdgEndpoint "Synthetic data generation" "HTTP(S) / API Key"
        garakProvider -> judgeEndpoint "Response evaluation" "HTTP(S) / API Key"
        garakProvider -> attackerEndpoint "Adversarial prompt generation" "HTTP(S) / API Key"
        garakProvider -> evaluatorEndpoint "Intent classification" "HTTP(S) / API Key"
        garakProvider -> ociRegistry "Persist scan artifacts" "HTTPS/443"
        garakProvider -> mlflow "Save evaluation metrics" "HTTP(S)"

        evalHub -> garakProvider "Orchestrates Garak evaluations as K8s Jobs" "eval-hub SDK"
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
                background #1168bd
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
        }
    }
}

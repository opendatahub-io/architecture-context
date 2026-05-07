workspace {
    model {
        dataScientist = person "Data Scientist" "Creates benchmarks, runs LLM vulnerability scans, reviews security reports"
        securityEngineer = person "Security Engineer" "Reviews red-teaming results, configures compliance benchmarks (OWASP, AVID, CWE)"

        garakProvider = softwareSystem "TrustyAI Garak Provider" "Out-of-tree Llama Stack evaluation provider and eval-hub adapter for automated LLM red-teaming using NVIDIA Garak" {
            inlineProvider = container "Inline Provider" "Runs garak as subprocess within Llama Stack server; semaphore-based concurrency control" "Python Module"
            remoteProvider = container "Remote Provider" "Submits garak scans as KFP pipeline runs; polls for completion" "Python Module"
            evalHubAdapter = container "Eval-Hub Adapter" "FrameworkAdapter for RHOAI evaluation platform; supports simple and KFP execution modes" "Python Module"
            coreModule = container "Core Module" "Shared pipeline step logic: validation, taxonomy resolution, SDG, scan execution, result parsing" "Python Module"
            configModule = container "Config Module" "Benchmark profiles (OWASP, AVID, CWE, Intents), deep-merge customization, garak command building" "Python Module"
            containerImage = container "Container Image" "Production image for KFP step pods and eval-hub K8s Job pods" "Docker (UBI9, Python 3.12)" "odh-trustyai-garak-lls-provider-dsp-rhel9"
        }

        llamaStack = softwareSystem "Llama Stack Distribution" "Hosts eval providers, manages benchmarks, files, safety, and inference APIs" "Internal RHOAI"
        kfp = softwareSystem "Data Science Pipelines (KFP/DSPA)" "Kubeflow Pipelines for orchestrating multi-step scan workflows" "Internal RHOAI"
        evalHub = softwareSystem "Eval-Hub Service" "RHOAI evaluation platform that orchestrates framework adapter pods via K8s Jobs" "Internal RHOAI"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides garak-provider-image ConfigMap for KFP base image resolution" "Internal RHOAI"

        targetLLM = softwareSystem "Target LLM (vLLM)" "OpenAI-compatible inference endpoint being scanned for vulnerabilities" "External"
        shieldModels = softwareSystem "Shield Models" "Llama Guard and Prompt Guard for input/output guardrail testing" "External"
        sdgModel = softwareSystem "SDG Model Endpoint" "Model for synthetic data generation (intents benchmarks)" "External"
        judgeModels = softwareSystem "Judge/Attacker/Evaluator Models" "Models for TAP attack, classification, and evaluation in intents benchmarks" "External"
        s3 = softwareSystem "S3 Object Storage" "S3-compatible storage for scan artifacts, reports, taxonomy files" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting scan result bundles" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking server for metrics, artifacts, and run metadata" "External"
        postgres = softwareSystem "PostgreSQL" "State storage for Llama Stack distribution (indirect)" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for secrets, ConfigMaps, and RBAC" "External"
        garak = softwareSystem "NVIDIA Garak" "Red-teaming framework: vulnerability probes, detectors, reporters" "External"

        # User interactions
        dataScientist -> garakProvider "Runs benchmarks and eval scans via Llama Stack API or eval-hub"
        securityEngineer -> garakProvider "Configures OWASP/AVID/CWE profiles, reviews TBSA scores"

        # Internal container relationships
        inlineProvider -> coreModule "Uses shared pipeline logic"
        remoteProvider -> coreModule "Uses shared pipeline logic"
        evalHubAdapter -> coreModule "Uses shared pipeline logic"
        inlineProvider -> configModule "Deep-merge benchmark configs"
        remoteProvider -> configModule "Deep-merge benchmark configs"
        evalHubAdapter -> configModule "Resolve configs + legacy overrides"

        # Provider to Llama Stack
        garakProvider -> llamaStack "Registers as eval provider (inline + remote)" "Plugin API"
        llamaStack -> garakProvider "Dispatches benchmarks.register, eval.run_eval" "HTTP/8321"

        # Provider to KFP
        garakProvider -> kfp "Submits pipeline runs, polls status" "HTTPS/443, Bearer Token"

        # Provider to Eval-Hub
        evalHub -> garakProvider "Creates K8s Job pods with ConfigMap" "K8s Job API"
        garakProvider -> evalHub "Reports status via sidecar callbacks" "HTTP localhost"

        # Provider to models
        garakProvider -> targetLLM "Sends probe prompts for vulnerability scanning" "HTTPS/443, Bearer Token"
        garakProvider -> shieldModels "Shield scan orchestration (guardrail testing)" "HTTP/8321"
        garakProvider -> sdgModel "Synthetic data generation for intents benchmarks" "HTTPS/443, Bearer Token"
        garakProvider -> judgeModels "TAP attack, judge classification, evaluation" "HTTPS/443, Bearer Token"
        garakProvider -> garak "Spawns as subprocess for red-teaming execution" "Process spawn"

        # Provider to storage
        garakProvider -> s3 "Upload/download scan artifacts" "HTTPS/443, AWS IAM"
        garakProvider -> ociRegistry "Push artifact bundles" "HTTPS/443, Registry creds"
        garakProvider -> mlflow "Log metrics and artifacts" "HTTPS/443"
        garakProvider -> postgres "State storage (indirect via LSD)" "PostgreSQL/5432"
        garakProvider -> k8sAPI "Read Secrets, ConfigMaps" "HTTPS/443, SA Token"

        # Operator dependency
        trustyaiOperator -> garakProvider "Provides container image reference via ConfigMap" "K8s ConfigMap"
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
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

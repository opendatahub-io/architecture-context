workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs LLM security evaluations using predefined or custom benchmark profiles"
        securityengineer = person "Security Engineer" "Initiates red-teaming scans via eval-hub for compliance assessment"

        garakProvider = softwareSystem "TrustyAI Garak LLS Provider" "Out-of-tree Llama Stack evaluation provider and eval-hub adapter for automated LLM red-teaming using NVIDIA Garak" {
            coreLib = container "Core Library" "Shared config models, garak command builders, deep-merge configuration, result parsing" "Python 3.12"
            inlineProvider = container "Inline Provider" "Runs garak as a subprocess within the Llama Stack server process; semaphore-gated concurrency" "Python Module"
            remoteProvider = container "Remote Provider" "Submits garak scans as Kubeflow Pipeline runs; polls for completion" "Python Module"
            evalHubAdapter = container "Eval-Hub Adapter" "FrameworkAdapter for RHOAI evaluation platform; reads JobSpec from ConfigMap; simple or KFP mode" "Python Module"
            coreModule = container "Core Pipeline Steps" "Framework-agnostic pipeline logic: validate, taxonomy, SDG, prompts, scan, parse" "Python Module"
            garakRunner = container "Garak Runner" "Process management: os.setsid, daemon output threads, bounded deques, SIGTERM/SIGKILL" "Python Module"
            containerImage = container "DSP Container Image" "Production image for KFP pipeline step pods and eval-hub K8s Job pods" "Container (UBI9, Python 3.12)" "odh-trustyai-garak-lls-provider-dsp-rhel9"
        }

        llamaStack = softwareSystem "Llama Stack Distribution" "Hosts ML inference providers as plugins; serves Files, Benchmarks, Safety, Shields, Inference APIs" "Internal Platform"
        evalHub = softwareSystem "Eval-Hub Service" "RHOAI evaluation platform; orchestrates adapter pods as K8s Jobs" "Internal Platform"
        dspa = softwareSystem "Data Science Pipelines (DSPA)" "Kubeflow Pipelines-compatible pipeline orchestration on OpenShift" "Internal Platform"
        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Provides garak-provider-image ConfigMap key for KFP base image resolution" "Internal Platform"

        garak = softwareSystem "NVIDIA Garak" "Red-teaming framework: vulnerability probes, detectors, reporters" "External"
        targetLLM = softwareSystem "Target LLM (vLLM)" "Model server being scanned for vulnerabilities via OpenAI-compatible API" "External"
        sdgModel = softwareSystem "SDG Model Endpoint" "Model for synthetic data generation in intents benchmarks" "External"
        judgeModels = softwareSystem "Judge/Attacker/Evaluator Models" "Specialized models for TAP attack, judge classification, and evaluation in intents benchmarks" "External"
        s3 = softwareSystem "S3 Object Storage" "Stores scan artifacts, SDG outputs, taxonomy files, and pipeline data" "External"
        ociRegistry = softwareSystem "OCI Registry" "Persists scan artifact bundles" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking: metrics, artifacts (HTML reports, CSVs), and run metadata" "External"
        postgresql = softwareSystem "PostgreSQL" "Llama Stack distribution state storage" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Reads Secrets (S3 creds, model auth), ConfigMaps" "External"

        # User interactions
        datascientist -> llamaStack "Creates InferenceService, registers benchmarks, runs eval via Llama Stack API" "HTTP/8321"
        securityengineer -> evalHub "Initiates red-teaming evaluation via eval-hub platform"

        # Llama Stack integration
        llamaStack -> garakProvider "Loads inline and remote providers as plugins" "In-process"
        inlineProvider -> garak "Spawns garak subprocess" "Process spawn"
        remoteProvider -> dspa "Submits pipeline runs" "HTTPS/443"
        inlineProvider -> coreLib "Uses shared config and command builders"
        remoteProvider -> coreLib "Uses shared config and command builders"
        inlineProvider -> garakRunner "Subprocess management"
        coreModule -> garakRunner "Pipeline step execution"

        # Eval-Hub integration
        evalHub -> evalHubAdapter "Creates K8s Job with ConfigMap mount" "K8s Job"
        evalHubAdapter -> coreModule "Delegates to pipeline steps"
        evalHubAdapter -> dspa "Submits pipeline in KFP mode" "HTTPS/443"

        # Target model scanning
        garak -> targetLLM "Sends red-teaming probes" "HTTPS/443, Bearer Token"
        garak -> judgeModels "Intents benchmark models" "HTTPS/443, Bearer Token"
        coreModule -> sdgModel "SDG generation" "HTTPS/443, Bearer Token"

        # Storage and persistence
        garakProvider -> s3 "Uploads/downloads scan artifacts" "HTTPS/443, AWS IAM"
        evalHubAdapter -> ociRegistry "Pushes artifact bundles" "HTTPS/443, TLS"
        evalHubAdapter -> mlflow "Logs metrics and artifacts" "HTTPS/443"
        llamaStack -> postgresql "State storage" "PostgreSQL/5432"

        # Platform dependencies
        garakProvider -> k8sAPI "Reads Secrets and ConfigMaps" "HTTPS/443, mTLS"
        garakProvider -> trustyaiOperator "Reads garak-provider-image from ConfigMap" "K8s API"

        # Container image usage
        containerImage -> dspa "Base image for KFP step pods"
        containerImage -> evalHub "Base image for eval-hub K8s Job pods"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

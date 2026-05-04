workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML model evaluations, explainability, and guardrails"
        platformAdmin = person "Platform Admin" "Deploys and configures TrustyAI operator via RHOAI"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller Kubernetes operator managing AI trustworthiness, model evaluation, and guardrails infrastructure" {
            controllerManager = container "controller-manager" "Multi-controller operator hosting TAS, LMES, GORCH, NemoGuardrails, EvalHub, and JobMgr controllers" "Go Operator (controller-runtime)"
            tasController = container "TAS Controller" "Reconciles TrustyAIService CRs, deploys explainability/fairness service with KServe/ModelMesh integration" "Go Controller"
            lmesController = container "LMES Controller" "Orchestrates LMEvalJob lifecycle, manages evaluation pods with ta-lmes-driver" "Go Controller"
            gorchController = container "GORCH Controller" "Deploys FMS Guardrails orchestrator with auto-discovery of InferenceServices and detectors" "Go Controller"
            nemoController = container "NeMo Controller" "Deploys NVIDIA NeMo Guardrails instances with CA bundle management" "Go Controller"
            evalhubController = container "EvalHub Controller" "Deploys evaluation hub with multi-tenant RBAC, database, and MLFlow integration" "Go Controller"
            jobMgrController = container "JobMgr Controller" "Maps LMEvalJobs to Kueue Workloads for queue-based admission" "Go Controller"
            lmesDriver = container "ta-lmes-driver" "Sidecar/init container binary executing lm-evaluation-harness with progress monitoring" "Go CLI"
        }

        kserve = softwareSystem "KServe / ModelMesh" "Model serving platform for ML inference" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for traffic management and mTLS (conditional)" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via ServiceMonitors" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller with TLS termination via Routes" "External"
        openshiftServiceCA = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys and configures TrustyAI operator" "Internal RHOAI"

        s3Storage = softwareSystem "S3 Storage" "S3-compatible object storage for model artifacts and evaluation assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation result upload" "External"
        huggingFace = softwareSystem "Hugging Face Hub" "Model and dataset repository (when online mode enabled)" "External"
        mlflow = softwareSystem "MLFlow" "Experiment tracking server for EvalHub" "Internal RHOAI"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics collection" "External"
        database = softwareSystem "PostgreSQL" "Persistent storage for EvalHub and TrustyAI service data" "External"
        gitRepos = softwareSystem "Git Repositories" "Custom evaluation task repositories" "External"

        # Relationships - Users
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator, NemoGuardrails, EvalHub CRs" "kubectl / HTTPS"
        platformAdmin -> rhoaiOperator "Configures TrustyAI operator deployment" "RHOAI Dashboard"
        rhoaiOperator -> trustyaiOperator "Deploys operator, provides image configuration" "Kubernetes API"

        # Relationships - Internal containers
        controllerManager -> tasController "Hosts"
        controllerManager -> lmesController "Hosts"
        controllerManager -> gorchController "Hosts"
        controllerManager -> nemoController "Hosts"
        controllerManager -> evalhubController "Hosts"
        controllerManager -> jobMgrController "Hosts"
        lmesController -> lmesDriver "Deploys as sidecar in evaluation pods"

        # Relationships - Platform
        tasController -> kserve "Patches InferenceService specs for payload processing" "HTTPS/6443 (API)"
        gorchController -> kserve "Auto-discovers InferenceServices and ServingRuntimes" "HTTPS/6443 (API)"
        jobMgrController -> kueue "Creates Workload CRs for LMEvalJob scheduling" "HTTPS/6443 (API)"
        tasController -> istio "Creates DestinationRules and VirtualServices (conditional)" "HTTPS/6443 (API)"
        tasController -> prometheus "Creates ServiceMonitors for metrics scraping" "HTTPS/6443 (API)"
        trustyaiOperator -> openshiftRouter "Creates Routes for external access (TLS reencrypt)" "HTTPS/6443 (API)"
        trustyaiOperator -> openshiftServiceCA "Provisions TLS certificates via annotations" "Kubernetes API"

        # Relationships - External services
        lmesDriver -> s3Storage "Downloads offline evaluation assets" "HTTPS/443"
        lmesDriver -> ociRegistry "Uploads evaluation results" "HTTPS/443"
        lmesDriver -> huggingFace "Downloads models and datasets (when allowOnline=true)" "HTTPS/443"
        lmesDriver -> gitRepos "Clones custom evaluation tasks" "HTTPS/443"
        evalhubController -> mlflow "Sends experiment tracking data" "HTTPS (projected SA token)"
        evalhubController -> database "Stores evaluation data" "TCP/5432"
        gorchController -> otelCollector "Exports traces and metrics" "gRPC/HTTP"
        evalhubController -> otelCollector "Exports traces and metrics" "gRPC/HTTP"
    }

    views {
        systemContext trustyaiOperator "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiOperator "Containers" {
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

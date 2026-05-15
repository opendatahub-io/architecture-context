workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, configures guardrails"
        platformAdmin = person "Platform Admin" "Deploys and configures TrustyAI services on OpenShift"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI trustworthiness services for RHOAI" {
            manager = container "Operator Manager" "Multi-controller binary with plugin-based service registry" "Go 1.24 / controller-runtime"
            tasController = container "TAS Controller" "Manages TrustyAI explainability service deployments" "Go Controller"
            lmesController = container "LMES Controller" "Manages LMEvalJob pods for language model evaluation" "Go Controller"
            jobMgrController = container "Job Manager Controller" "Kueue framework adapter for LMEvalJob workload scheduling" "Go Controller"
            gorchController = container "GORCH Controller" "Manages guardrails orchestrator with auto-config from KServe" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NVIDIA NeMo Guardrails deployments" "Go Controller"
            evalhubController = container "EvalHub Controller" "Manages centralized evaluation hub with multi-tenant support" "Go Controller"
            lmesDriver = container "ta-lmes-driver" "Sidecar/init-container driver for LMEval job coordination" "Go CLI"
        }

        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService CRDs" "Internal RHOAI"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and mTLS" "External"
        kueue = softwareSystem "Kueue" "Job scheduling and workload management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor CRDs" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress via OpenShift Routes with TLS termination" "External"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar with FIPS 140-2 TLS and K8s TokenReview" "External"
        certManager = softwareSystem "OpenShift Service CA" "Automatic TLS certificate provisioning via annotations" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for LMEval datasets and model artifacts" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for LMEval result upload" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository (online mode)" "External"
        database = softwareSystem "Database (MariaDB/PostgreSQL)" "Persistent storage for TAS and EvalHub" "External"
        otelCollector = softwareSystem "OTEL Collector" "OpenTelemetry telemetry collection" "External"

        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, GuardrailsOrchestrator, EvalHub CRs" "kubectl / RHOAI Dashboard"
        platformAdmin -> trustyaiOperator "Deploys operator, configures --enable-services" "Kustomize / OLM"

        trustyaiOperator -> kserve "Watches/patches InferenceServices, reads ServingRuntimes" "HTTPS/443 (K8s API)"
        trustyaiOperator -> istio "Creates DestinationRules and VirtualServices (conditional)" "HTTPS/443 (K8s API)"
        trustyaiOperator -> kueue "Creates Workloads for LMEvalJob scheduling" "HTTPS/443 (K8s API)"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "HTTPS/443 (K8s API)"
        trustyaiOperator -> openshiftRouter "Creates Routes for external HTTPS access" "HTTPS/443 (K8s API)"
        trustyaiOperator -> kubeRbacProxy "Deploys as sidecar for Bearer Token auth" "HTTPS/8443"
        trustyaiOperator -> certManager "Annotates Services for auto TLS cert generation" "Annotation trigger"
        trustyaiOperator -> mlflow "EvalHub experiment tracking via projected SA token" "HTTPS"

        trustyaiOperator -> s3Storage "LMEval offline dataset download" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMEval result upload" "HTTPS/443"
        trustyaiOperator -> huggingFace "LMEval model/dataset download (online mode)" "HTTPS/443"
        trustyaiOperator -> database "TAS/EvalHub persistent storage" "TCP/TLS"
        trustyaiOperator -> otelCollector "GORCH/EvalHub telemetry export" "gRPC/HTTP"

        manager -> tasController "Registers and enables"
        manager -> lmesController "Registers and enables"
        manager -> jobMgrController "Registers and enables"
        manager -> gorchController "Registers and enables"
        manager -> nemoController "Registers and enables"
        manager -> evalhubController "Registers and enables"
        lmesController -> lmesDriver "Injects as init container + runs in main container"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

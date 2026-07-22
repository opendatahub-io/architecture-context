workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, configures guardrails"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, enables/disables TrustyAI sub-services"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-CRD Kubernetes operator managing AI/ML trustworthiness, evaluation, and guardrails services" {
            manager = container "Operator Manager" "Multi-controller binary with selectable activation via --enable-services flag" "Go Operator (controller-runtime)"
            tasController = container "TAS Controller" "Manages TrustyAI bias/fairness monitoring service instances" "Go Controller"
            lmesController = container "LMES Controller" "Manages LM evaluation jobs with offline mode and Kueue integration" "Go Controller"
            evalHubController = container "EvalHub Controller" "Manages multi-tenant evaluation platform with MCP server" "Go Controller"
            gorchController = container "GORCH Controller" "Manages composable guardrails pipeline with auto-discovery" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NVIDIA NeMo guardrails with MCP gateway integration" "Go Controller"
            moduleController = container "Module Controller" "Platform integration — responds to TrustyAI module CR" "Go Controller"
            jobMgrController = container "Job Manager Controller" "Kueue workload management for evaluation jobs" "Go Controller"
            webhookServer = container "Webhook Server" "CRD conversion webhook for EvalHub and TAS version migration" "HTTPS/9443"
            lmesDriver = container "ta-lmes-driver" "Execution engine for LM evaluation — progress monitoring, device detection, OCI upload" "Go CLI (init container + sidecar)"
        }

        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator (rhods-operator / opendatahub-operator) managing component lifecycle" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform — InferenceService CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing system" "External"
        istio = softwareSystem "Istio" "Service mesh for traffic management, mTLS, EnvoyFilters" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via ServiceMonitor CRDs" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller managing Routes for external access" "External"
        mcpGateway = softwareSystem "MCP Gateway (Kuadrant)" "Model Context Protocol gateway for NeMo guardrails integration" "Internal RHOAI"

        postgresql = softwareSystem "PostgreSQL" "Relational database for TAS and EvalHub persistent storage" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for model artifacts and offline evaluation data" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for LMEvalJob result uploads" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository for online evaluation" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry collector for EvalHub and GORCH observability" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, GuardrailsOrchestrator, NemoGuardrails CRs via kubectl/API"
        platformAdmin -> rhoaiOperator "Configures TrustyAI module CR to enable/disable sub-services"

        # Platform integration
        rhoaiOperator -> trustyaiOperator "Creates cluster-scoped TrustyAI module CR" "HTTPS/443"
        trustyaiOperator -> kserve "Watches/patches InferenceServices for TAS payload capture and GORCH auto-discovery" "HTTPS/443"
        trustyaiOperator -> kueue "Creates Workload CRs for LMEvalJob scheduling" "HTTPS/443"
        trustyaiOperator -> istio "Creates DestinationRule, VirtualService, EnvoyFilter for mesh integration" "HTTPS/443"
        trustyaiOperator -> prometheus "Creates ServiceMonitor resources for metrics scraping" "HTTPS/443"
        trustyaiOperator -> openshiftRouter "Creates Routes for external access to managed services" "HTTPS/443"
        trustyaiOperator -> mcpGateway "Discovers MCPGatewayExtension for NeMo EnvoyFilter config" "HTTPS/443"

        # External service egress
        trustyaiOperator -> postgresql "TAS and EvalHub persistent storage" "PostgreSQL/5432"
        trustyaiOperator -> s3Storage "LMEvalJob offline model download" "HTTPS/443"
        trustyaiOperator -> ociRegistry "LMEvalJob result artifact upload" "HTTPS/443"
        trustyaiOperator -> huggingFace "LMEvalJob model/dataset download (online mode)" "HTTPS/443"
        trustyaiOperator -> otlpCollector "EvalHub and GORCH telemetry export" "gRPC/HTTP"

        # Internal container relationships
        manager -> tasController "Runs"
        manager -> lmesController "Runs"
        manager -> evalHubController "Runs"
        manager -> gorchController "Runs"
        manager -> nemoController "Runs"
        manager -> moduleController "Runs"
        manager -> jobMgrController "Runs"
        lmesController -> lmesDriver "Deploys in evaluation pods"
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
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

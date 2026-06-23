workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, and deploys guardrails"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and guardrail policies"
        securityTeam = person "Security / Compliance" "Reviews model fairness, safety, and guardrail effectiveness"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing AI trustworthiness, evaluation, and guardrails services" {
            manager = container "Operator Manager" "Single binary running all controllers with selective enablement via --enable-services" "Go (controller-runtime)"
            tasController = container "TAS Controller" "Manages TrustyAI fairness and explainability services with KServe/ModelMesh integration" "Go Controller"
            lmesController = container "LMES Controller" "Orchestrates LM evaluation jobs using lm-evaluation-harness with driver injection pattern" "Go Controller"
            evalHubController = container "EvalHub Controller" "Manages centralized evaluation hub with multi-tenant namespace isolation and MCP server" "Go Controller"
            gorchController = container "GORCH Controller" "Deploys FMS Guardrails Orchestrator with auto-configuration from KServe InferenceServices" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Deploys NVIDIA NeMo Guardrails with EnvoyFilter and MCP Gateway integration" "Go Controller"
        }

        # Managed Services (created by the operator)
        trustyaiService = softwareSystem "TrustyAI Service" "Fairness and explainability service for ML models" "Managed"
        evalHubService = softwareSystem "EvalHub Service" "Centralized evaluation hub with provider plugins" "Managed"
        guardrailsOrchestrator = softwareSystem "FMS Guardrails Orchestrator" "Content safety guardrails for LLM inference" "Managed"
        nemoGuardrailsServer = softwareSystem "NeMo Guardrails Server" "NVIDIA NeMo Guardrails with CA and MCP Gateway" "Managed"
        lmesJobPod = softwareSystem "LMEvalJob Pod" "Ephemeral evaluation pod with driver init container" "Managed"

        # Internal RHOAI Platform
        rhodsOperator = softwareSystem "RHOAI Platform Operator" "Deploys and manages RHOAI components" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving with InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving platform" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar for Kubernetes services" "Internal RHOAI"

        # Platform Infrastructure
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh with mTLS, DestinationRules, EnvoyFilters" "Infrastructure"
        certManager = softwareSystem "cert-manager / service-ca" "Certificate management and CA bundles" "Infrastructure"
        kueue = softwareSystem "Kueue" "Job scheduling and workload management" "Infrastructure"
        mcpGateway = softwareSystem "MCP Gateway (Kuadrant)" "Model Context Protocol gateway" "Infrastructure"

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for evaluation assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation results" "External"
        postgreSQL = softwareSystem "PostgreSQL" "Relational database for EvalHub persistent storage" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        otlpEndpoint = softwareSystem "OTLP Endpoint" "OpenTelemetry collector for traces and metrics" "External"

        # Relationships — Users
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub CRs via kubectl/UI"
        dataScientist -> trustyaiService "Queries fairness metrics and explanations" "HTTPS/8443"
        dataScientist -> evalHubService "Runs evaluations and views results" "HTTPS/8443"
        mlEngineer -> trustyaiOperator "Creates GuardrailsOrchestrator, NemoGuardrails CRs"
        mlEngineer -> guardrailsOrchestrator "Sends inference requests through guardrails" "HTTPS/8443"
        securityTeam -> trustyaiService "Reviews bias detection and model monitoring data"

        # Relationships — Platform deploys operator
        rhodsOperator -> trustyaiOperator "Deploys as trustyai component"

        # Relationships — Operator to K8s API
        trustyaiOperator -> k8sApi "Reconciles CRDs, creates resources" "HTTPS/443"

        # Relationships — Operator to managed services
        tasController -> trustyaiService "Creates Deployment, Service, Route"
        lmesController -> lmesJobPod "Creates ephemeral Pod, polls via exec"
        evalHubController -> evalHubService "Creates Deployment, Service, Route, MCP server"
        gorchController -> guardrailsOrchestrator "Creates Deployment with auto-config from InferenceServices"
        nemoController -> nemoGuardrailsServer "Creates Deployment with CA bundles and EnvoyFilters"

        # Relationships — Operator integrations
        trustyaiOperator -> kserve "Watches/patches InferenceServices" "K8s API"
        trustyaiOperator -> modelMesh "Patches deployments (MM_PAYLOAD_PROCESSORS)" "K8s API"
        trustyaiOperator -> prometheus "Creates ServiceMonitor resources" "K8s API"
        trustyaiOperator -> istio "Creates DestinationRules, VirtualServices, EnvoyFilters" "K8s API"
        trustyaiOperator -> certManager "Reads CA bundles from ConfigMaps" "K8s API"
        trustyaiOperator -> kueue "LMES job scheduling, EvalHub failure reconciliation" "K8s API"
        trustyaiOperator -> mcpGateway "NemoGuardrails watches MCPGatewayExtension" "K8s API"

        # Relationships — Managed services use kube-rbac-proxy
        trustyaiService -> kubeRbacProxy "Authentication sidecar" "localhost"
        evalHubService -> kubeRbacProxy "Authentication sidecar" "localhost"
        guardrailsOrchestrator -> kubeRbacProxy "Authentication sidecar" "localhost"
        nemoGuardrailsServer -> kubeRbacProxy "Authentication sidecar" "localhost"

        # Relationships — GORCH to KServe
        guardrailsOrchestrator -> kserve "Forwards to generator/detector InferenceServices" "gRPC/HTTP"

        # Relationships — External services
        lmesJobPod -> s3Storage "Downloads evaluation assets (offline mode)" "HTTPS/443"
        lmesJobPod -> ociRegistry "Uploads evaluation results" "HTTPS/443"
        lmesJobPod -> huggingFace "Downloads models/datasets (online mode)" "HTTPS/443"
        evalHubService -> postgreSQL "Persistent storage backend" "TCP/5432"
        evalHubService -> otlpEndpoint "OpenTelemetry traces" "gRPC/HTTP"
        guardrailsOrchestrator -> otlpEndpoint "OpenTelemetry traces" "gRPC/HTTP"
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
                background #f8cecc
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                shape RoundedBox
            }
            element "Infrastructure" {
                background #dae8fc
                shape RoundedBox
            }
            element "Managed" {
                background #d5e8d4
                shape RoundedBox
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

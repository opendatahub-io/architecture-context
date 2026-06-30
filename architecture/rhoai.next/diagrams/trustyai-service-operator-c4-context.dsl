workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, deploys InferenceServices, runs evaluations, and configures guardrails"
        platformAdmin = person "Platform Admin" "Deploys and configures the TrustyAI operator and its CRDs"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing explainability, evaluation, and guardrails for Red Hat OpenShift AI" {
            operatorBinary = container "Operator Manager" "Single Go binary with 5 selectively-enabled controllers, leader election, webhook server" "Go controller-runtime"
            tasController = container "TAS Controller" "Manages TrustyAI explainability service deployments for bias/fairness monitoring (SPD, DIR)" "Go Controller"
            lmesController = container "LMES Controller" "Orchestrates LLM evaluation jobs using lm-evaluation-harness with Unitxt, S3, OCI support" "Go Controller"
            evalHubController = container "EvalHub Controller" "Multi-tenant evaluation hub API with provider/collection plugins and MCP server" "Go Controller"
            gorchController = container "GORCH Controller" "GuardrailsOrchestrator with KServe auto-discovery for content safety guardrailing" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "NVIDIA NeMo Guardrails server with Istio EnvoyFilter for MCP SSE" "Go Controller"
            lmesDriver = container "LMES Driver" "Init container binary for eval Pod lifecycle management, progress tracking, result upload" "Go CLI"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform with InferenceService CRD" "External"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "External"
        kueue = softwareSystem "Kueue" "Kubernetes workload scheduling and quota management" "External"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS, traffic routing, EnvoyFilters" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor CRDs" "External"
        certManager = softwareSystem "OpenShift Service CA" "TLS certificate provisioning via annotations" "External"
        kuadrant = softwareSystem "Kuadrant MCPGatewayExtension" "MCP gateway discovery for NeMo EnvoyFilter targeting" "External"

        odhOperator = softwareSystem "ODH / RHODS Operator" "Platform operator providing DSCInitialization config" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing AI/ML workloads" "Internal ODH"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal ODH"
        hardwareProfiles = softwareSystem "Hardware Profiles" "Resource configuration profiles for evaluation jobs" "Internal ODH"

        postgresql = softwareSystem "PostgreSQL" "Persistent storage for TrustyAI and EvalHub data" "External Service"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model/dataset storage, evaluation result upload" "External Service"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for evaluation results" "External Service"
        gitRepos = softwareSystem "Git Repositories" "Custom task source code for LMES evaluations" "External Service"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace and metric collection" "External Service"

        # Relationships
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, GuardrailsOrchestrator, NemoGuardrails CRs" "kubectl / API"
        platformAdmin -> trustyaiOperator "Deploys operator, configures overlays and enable-services flags" "kustomize / OLM"

        operatorBinary -> tasController "registers"
        operatorBinary -> lmesController "registers"
        operatorBinary -> evalHubController "registers"
        operatorBinary -> gorchController "registers"
        operatorBinary -> nemoController "registers"

        tasController -> kserve "Patches InferenceService Logger URL for payload interception" "HTTPS/443"
        tasController -> modelMesh "Injects MM_PAYLOAD_PROCESSORS env var" "Deployment Patch"
        tasController -> istio "Creates DestinationRule and VirtualService" "CRD Create"
        tasController -> postgresql "Stores payload data" "TCP/Conditional TLS"
        tasController -> prometheus "Creates ServiceMonitor" "CRD Create"

        lmesController -> kueue "Registers LMEvalJob as Kueue workload type" "CRD/HTTPS/443"
        lmesController -> s3Storage "Offline model/dataset retrieval" "HTTPS/443"
        lmesController -> ociRegistry "Evaluation result upload" "HTTPS/443"
        lmesController -> gitRepos "Custom task source fetching" "HTTPS/443"
        lmesDriver -> s3Storage "Upload results" "HTTPS/443"
        lmesDriver -> ociRegistry "Upload results" "HTTPS/443"

        evalHubController -> kueue "Watches workload admission failures" "CRD/HTTPS/443"
        evalHubController -> postgresql "Persistent evaluation data" "TCP/Conditional TLS"
        evalHubController -> hardwareProfiles "Reads resource configuration" "CRD Read"
        evalHubController -> mlflow "Creates RoleBindings for workspace access" "RBAC"
        evalHubController -> otlpCollector "OpenTelemetry export" "gRPC/HTTP"

        gorchController -> kserve "Auto-discovers generators and detectors from InferenceServices" "CRD Watch/HTTPS"
        gorchController -> otlpCollector "OpenTelemetry export" "gRPC/HTTP"

        nemoController -> istio "Creates EnvoyFilter for MCP SSE response handling" "CRD Create"
        nemoController -> kuadrant "Discovers MCPGatewayExtension for EnvoyFilter targeting" "CRD Watch"

        trustyaiOperator -> certManager "Service CA certificate provisioning" "Annotations"
        trustyaiOperator -> odhOperator "Reads trustyai-dsc-config ConfigMap for LMES overrides" "ConfigMap Read"

        odhDashboard -> trustyaiOperator "UI management of TrustyAI resources" "API"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Service" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

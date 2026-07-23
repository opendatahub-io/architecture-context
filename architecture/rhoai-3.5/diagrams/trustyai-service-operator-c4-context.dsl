workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, runs evaluations, deploys inference services"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures TrustyAI component"
        securityEngineer = person "Security Engineer" "Configures guardrails, reviews model safety"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-controller operator managing explainability, evaluation, guardrails, and NeMo services" {
            operatorBinary = container "Operator Binary" "Multi-controller operator with service registry pattern" "Go Operator (controller-runtime)" {
                tasController = component "TAS Controller" "Manages TrustyAI Service deployments for model explainability and fairness monitoring" "Go Controller"
                lmesController = component "LMES Controller" "Manages LMEvalJob pods for LM evaluation using lm-evaluation-harness" "Go Controller"
                evalHubController = component "EvalHub Controller" "Manages centralized evaluation hub with multi-tenant support" "Go Controller"
                gorchController = component "GORCH Controller" "Manages FMS guardrails orchestrator with auto-configuration from KServe" "Go Controller"
                nemoController = component "NemoGuardrails Controller" "Manages NVIDIA NeMo Guardrails server with MCP gateway integration" "Go Controller"
                moduleController = component "Module Controller" "Reconciles TrustyAI platform module lifecycle" "Go Controller"
                imageResolver = component "Image Resolver" "Three-tier image resolution: RELATED_IMAGE_ > ConfigMap > defaults" "Go Library"
            }
            taLmesDriver = container "ta-lmes-driver" "Execution engine for LM evaluation jobs with progress monitoring" "Go CLI (init container)"
        }

        kserve = softwareSystem "KServe" "ML model serving platform providing InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queue management for scheduling evaluation and guardrails workloads" "Internal RHOAI"
        istio = softwareSystem "Istio / Service Mesh" "Service mesh for mTLS, traffic routing via DestinationRules, VirtualServices, EnvoyFilters" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / Monitoring Stack" "Metrics collection via ServiceMonitor CRDs" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "External HTTPS access via Route CRDs with reencrypt TLS" "Internal RHOAI"
        platformOperator = softwareSystem "RHOAI Platform Operator" "Provides operator ConfigMap and RELATED_IMAGE_* env vars for image resolution" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing SubjectAccessReview with TLS 1.2+ FIPS ciphers" "Internal RHOAI"
        mcpGateway = softwareSystem "MCP Gateway (Kuadrant)" "Model Context Protocol gateway for NeMo Guardrails discovery" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking for EvalHub evaluation results" "Internal RHOAI"
        gatewayAPI = softwareSystem "Gateway API" "Gateway validation for NeMo Guardrails MCP integration" "Internal RHOAI"

        s3Storage = softwareSystem "S3-compatible Storage" "Model artifacts and evaluation dataset storage" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container image registries for evaluation result upload" "External"
        gitRepos = softwareSystem "Git Repositories" "Source for custom evaluation tasks" "External"
        database = softwareSystem "PostgreSQL Database" "Persistent storage for TAS inference data and EvalHub state" "External"
        otlpEndpoints = softwareSystem "OTLP Endpoints" "OpenTelemetry endpoints for EvalHub and GORCH telemetry" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Core platform API for managing all cluster resources" "External"

        # User interactions
        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, GuardrailsOrchestrator, NemoGuardrails CRs via kubectl/UI"
        platformAdmin -> platformOperator "Enables TrustyAI component in DataScienceCluster"
        securityEngineer -> trustyaiOperator "Configures guardrails policies via GuardrailsOrchestrator and NemoGuardrails CRs"

        # Internal RHOAI dependencies
        trustyaiOperator -> kserve "Watches/patches InferenceServices, reads ServingRuntimes" "K8s API/HTTPS/443"
        trustyaiOperator -> kueue "Creates/watches Workloads for job scheduling" "K8s API/HTTPS/443"
        trustyaiOperator -> istio "Creates DestinationRules, VirtualServices, EnvoyFilters" "K8s API/HTTPS/443"
        trustyaiOperator -> prometheus "Creates ServiceMonitors for metrics scraping" "K8s API/HTTPS/443"
        trustyaiOperator -> openshiftRouter "Creates Routes for external HTTPS access" "K8s API/HTTPS/443"
        platformOperator -> trustyaiOperator "Provides ConfigMap and RELATED_IMAGE_* env vars"
        trustyaiOperator -> kubeRbacProxy "Deploys as sidecar in all service pods" "Container sidecar"
        trustyaiOperator -> mcpGateway "Watches MCPGatewayExtension for NemoGuardrails" "K8s API/HTTPS/443"
        trustyaiOperator -> mlflow "Creates Experiments for EvalHub tracking" "K8s API/HTTPS/443"
        trustyaiOperator -> gatewayAPI "Validates Gateway existence for NemoGuardrails" "K8s API/HTTPS/443"

        # External dependencies
        trustyaiOperator -> kubernetesAPI "Manages CRDs, Deployments, RBAC, Pods, ConfigMaps" "HTTPS/443 SA Token"
        trustyaiOperator -> s3Storage "Downloads evaluation datasets, uploads results" "HTTPS/443 TLS 1.2+"
        trustyaiOperator -> ociRegistries "Uploads evaluation results" "HTTPS/443 TLS 1.2+"
        trustyaiOperator -> gitRepos "Clones custom evaluation tasks" "HTTPS/443 TLS 1.2+"
        trustyaiOperator -> database "Stores inference data and evaluation state" "TCP/TLS"
        trustyaiOperator -> otlpEndpoints "Exports telemetry data" "gRPC/HTTP"
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

        component operatorBinary "Components" {
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

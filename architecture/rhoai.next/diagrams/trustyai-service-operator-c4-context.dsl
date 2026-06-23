workspace {
    model {
        datascientist = person "Data Scientist" "Creates ML models, runs evaluations, deploys guardrails for responsible AI"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and operator lifecycle"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-CRD Kubernetes operator managing AI trustworthiness services: explainability, evaluation, guardrails" {
            controller = container "Operator Controller Manager" "Feature-gated controllers for 5 CRDs with leader election" "Go (controller-runtime)"
            tasController = container "TrustyAIService Controller" "Deploys explainability/fairness monitoring with KServe InferenceLogger integration" "Go Controller"
            lmesController = container "LMEvalJob Controller" "Orchestrates language model evaluation jobs with Kueue GPU scheduling" "Go Controller"
            evalHubController = container "EvalHub Controller" "Multi-tenant evaluation management API with MCP server and provider/collection discovery" "Go Controller"
            gorchController = container "GuardrailsOrchestrator Controller" "Auto-configures guardrails from KServe InferenceServices with detector discovery" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Manages NeMo Guardrails with MCP gateway and Istio EnvoyFilter integration" "Go Controller"
            lmesDriver = container "LMES Driver" "Kubernetes-native execution engine for lm-evaluation-harness with progress monitoring" "Go CLI (init container)"
            webhook = container "EvalHub Conversion Webhook" "Converts EvalHub CRs between v1alpha1 and v1" "Go Webhook Server, 9443/TCP"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Explainability and fairness monitoring service" "Managed by Operator"
        evalHubAPI = softwareSystem "EvalHub API & MCP Server" "Centralized evaluation management with multi-tenant namespace distribution" "Managed by Operator"
        guardrailsOrchestrator = softwareSystem "Guardrails Orchestrator" "Guardrails infrastructure with auto-configuration" "Managed by Operator"
        nemoGuardrails = softwareSystem "NeMo Guardrails Server" "NVIDIA NeMo Guardrails with MCP gateway integration" "Managed by Operator"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator managing RHOAI component lifecycle" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with InferenceService and ServingRuntime CRDs" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh Serving" "Multi-model serving with payload processor integration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queueing with GPU quota management" "External"
        istio = softwareSystem "Istio" "Service mesh: DestinationRule, VirtualService, EnvoyFilter" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor CRD" "External"
        serviceCA = softwareSystem "OpenShift service-ca-operator" "Automatic TLS certificate provisioning" "External"
        kuadrantMCP = softwareSystem "Kuadrant MCP" "MCPGatewayExtension for API gateway discovery" "External"

        postgresql = softwareSystem "PostgreSQL" "Persistent storage for TrustyAI predictions and EvalHub data" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for LMEval offline assets" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for LMEval result upload" "External"
        modelEndpoints = softwareSystem "Model Endpoints" "VLLM, OpenAI API, etc. for model evaluation" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace/metric collection" "External"

        # Relationships - User to System
        datascientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, GuardrailsOrchestrator, NemoGuardrails CRs" "kubectl / HTTPS"
        datascientist -> evalHubAPI "Submits evaluations, queries results" "HTTPS/443 via Route"
        datascientist -> guardrailsOrchestrator "Sends requests through guardrails" "HTTPS/443 via Route"
        datascientist -> nemoGuardrails "Sends requests through NeMo guardrails" "HTTPS/443 via Route"
        platformadmin -> rhodsOperator "Configures RHOAI platform" "HTTPS/443"

        # Platform Operator relationship
        rhodsOperator -> trustyaiOperator "Deploys operator, provides ConfigMap with image refs" "Kubernetes API"

        # Operator → Internal dependencies
        trustyaiOperator -> kserve "Watches InferenceServices; patches InferenceLogger; reads ServingRuntimes" "HTTPS/443"
        trustyaiOperator -> modelMesh "Patches MM_PAYLOAD_PROCESSORS env var" "Kubernetes API"
        trustyaiOperator -> kueue "Creates Workload CRs for GPU scheduling" "HTTPS/443"
        trustyaiOperator -> istio "Creates DestinationRule, VirtualService, EnvoyFilter" "Kubernetes API"
        trustyaiOperator -> prometheusOp "Creates ServiceMonitor CRs" "Kubernetes API"
        trustyaiOperator -> serviceCA "Uses annotation-driven TLS cert provisioning" "Annotation"
        trustyaiOperator -> kuadrantMCP "Watches MCPGatewayExtension for gateway discovery" "Kubernetes API"

        # Managed services → External
        trustyaiService -> postgresql "Stores prediction data" "TCP/TLS"
        trustyaiService -> kserve "Receives predictions via InferenceLogger" "HTTPS/8443"
        evalHubAPI -> postgresql "Stores evaluation data" "TCP/TLS"
        evalHubAPI -> otlpCollector "Exports traces/metrics" "gRPC/HTTP"
        guardrailsOrchestrator -> kserve "Routes through detector InferenceServices" "gRPC/HTTPS"
        guardrailsOrchestrator -> otlpCollector "Exports traces/metrics" "gRPC/HTTP"
        lmesDriver -> s3Storage "Downloads evaluation assets" "HTTPS/443"
        lmesDriver -> ociRegistry "Uploads result artifacts" "HTTPS/443"
        lmesDriver -> modelEndpoints "Evaluates models" "HTTPS, API Key"

        # Operator creates managed services
        trustyaiOperator -> trustyaiService "Creates Deployment, Service, Route, ServiceMonitor" "Kubernetes API"
        trustyaiOperator -> evalHubAPI "Creates Deployment, Service, Route, MCP Server" "Kubernetes API"
        trustyaiOperator -> guardrailsOrchestrator "Creates Deployment, Service, Route, auto-config" "Kubernetes API"
        trustyaiOperator -> nemoGuardrails "Creates Deployment, Service, Route, EnvoyFilter" "Kubernetes API"
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
            element "Managed by Operator" {
                background #4a90e2
                color #ffffff
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

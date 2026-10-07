workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages AI/ML model trustworthiness, evaluation, and guardrail workloads"
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform components via DataScienceCluster"

        trustyaiOperator = softwareSystem "TrustyAI Service Operator" "Multi-service Kubernetes operator managing AI/ML model trustworthiness, evaluation, and guardrail workloads" {
            manager = container "Operator Manager" "Hosts all service controllers, webhook server, metrics endpoint, and TLS profile watcher. Selectively activates controllers via --enable-services flag." "Go Operator"
            tasController = container "TrustyAIService Controller" "Reconciles TrustyAIService CRs; provisions service deployments with kube-rbac-proxy sidecars, PVCs, routes, and monitoring" "Go Controller"
            evalHubController = container "EvalHub Controller" "Reconciles EvalHub CRs; manages evaluation hub deployments with multi-tenant namespace propagation" "Go Controller"
            lmesController = container "LMEvalJob Controller" "Reconciles LMEvalJob CRs; creates evaluation pods with driver sidecars" "Go Controller"
            nemoController = container "NemoGuardrails Controller" "Reconciles NemoGuardrails CRs; deploys NVIDIA NemoGuardrails servers" "Go Controller"
            tlsWatcher = container "TLS ProfileWatcher" "Watches OpenShift APIServer TLS security profile; triggers manager restart on change" "Go Controller"
            webhookServer = container "Webhook Server" "CRD version conversion webhook for EvalHub and TrustyAIService v1alpha1/v1" "Go Service" "9443/TCP"
            driverBinary = container "LMEval Driver" "Coordinates model evaluation execution inside pods; handles device detection and progress reporting" "Go Binary"
            operatorModule = container "trustyai-operator-module" "DSC component module controller; watches TrustyAI CR and renders operator manifests" "Go Operator"
        }

        kserve = softwareSystem "KServe" "Model serving platform providing InferenceService CRDs" "Internal ODH"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API server for all resource CRUD operations" "Platform"
        istio = softwareSystem "Istio" "Service mesh for traffic management and mTLS" "Platform"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor resources" "Platform"
        kueue = softwareSystem "Kueue" "Workload queueing and admission for evaluation jobs" "Platform"
        openShiftAPI = softwareSystem "OpenShift APIServer Config" "Cluster TLS security profile configuration" "Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "Certificate provisioning and auto-rotation" "Platform"
        otelCollector = softwareSystem "OpenTelemetry Collector" "Distributed tracing and metrics export" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking for evaluation results" "Internal ODH"
        mcpGateway = softwareSystem "MCP Gateway" "MCP service discovery and gateway extensions" "Internal ODH"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute routing configuration" "Platform"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, deployment helpers" "Internal ODH"

        dataScientist -> trustyaiOperator "Creates TrustyAIService, LMEvalJob, EvalHub, NemoGuardrails CRs" "kubectl / Dashboard"
        platformAdmin -> trustyaiOperator "Manages TrustyAI component via DataScienceCluster CR" "kubectl"

        trustyaiOperator -> kubeAPI "All controller CRUD operations" "HTTPS/6443"
        trustyaiOperator -> kserve "Watches/patches InferenceServices for TrustyAI integration" "HTTPS/6443"
        trustyaiOperator -> istio "Creates VirtualServices and DestinationRules" "HTTPS/6443"
        trustyaiOperator -> prometheusOp "Creates ServiceMonitors for metrics scraping" "HTTPS/6443"
        trustyaiOperator -> kueue "Monitors and manages queued evaluation workloads" "HTTPS/6443"
        trustyaiOperator -> openShiftAPI "Watches TLS security profile; triggers restart on change" "HTTPS/6443"
        trustyaiOperator -> otelCollector "Exports traces and metrics (opt-in)" "OTLP gRPC/HTTP"
        trustyaiOperator -> mlflow "Creates/reads experiment tracking resources" "HTTPS/6443"
        trustyaiOperator -> mcpGateway "Reads MCP gateway extension configuration" "HTTPS/6443"
        trustyaiOperator -> gatewayAPI "Reads HTTPRoute resources for routing" "HTTPS/6443"

        serviceCA -> trustyaiOperator "Provisions and rotates TLS certificates" "Annotation-based"
        operatorModule -> odhPlatformUtils "Uses for platform detection and manifest rendering" "Go library"

        manager -> tasController "Delegates TrustyAIService reconciliation"
        manager -> evalHubController "Delegates EvalHub reconciliation"
        manager -> lmesController "Delegates LMEvalJob reconciliation"
        manager -> nemoController "Delegates NemoGuardrails reconciliation"
        manager -> tlsWatcher "TLS profile monitoring"
        manager -> webhookServer "CRD conversion webhooks"
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
            element "Internal ODH" {
                background #7ed321
                color #333333
            }
            element "Platform" {
                background #f5a623
                color #333333
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / Platform User" "Submits batch inference jobs via API or kubectl"
        platformOp = person "Platform Operator" "Deploys and configures the operator via opendatahub-operator/rhods-operator"

        batchGatewayOperator = softwareSystem "LLM-D Batch Gateway Operator" "Manages the full lifecycle of LLM-D batch gateway deployments by reconciling LLMBatchGateway CRs into Kubernetes resources via Helm chart rendering" {
            controller = container "LLMBatchGateway Reconciler" "Watches LLMBatchGateway CRs, renders Helm chart, applies resources via Server-Side Apply" "Go (controller-runtime)"
            metricsController = container "Metrics Controller" "Self-heals operator monitoring resources (Service, ServiceMonitor, PrometheusRule)" "Go (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Loads embedded batch-gateway chart, converts CR spec to Helm values, renders templates in-process" "Helm SDK v3"
            secretSync = container "Secret Sync" "Handles cross-namespace secret references via Gateway API ReferenceGrant semantics" "Go"
        }

        batchGatewayWorkloads = softwareSystem "Batch Gateway Workloads" "Managed deployments rendered from Helm chart" {
            apiServer = container "API Server" "OpenAI-compatible HTTP API for batch job submission (/v1/batches) and file management (/v1/files)" "HTTP/HTTPS 8000/TCP"
            processor = container "Processor" "Worker that dequeues batch jobs and forwards inference requests with AIMD adaptive concurrency" "Worker"
            garbageCollector = container "Garbage Collector" "Periodic cleanup of expired jobs and files" "Worker"
        }

        # External dependencies
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        postgresql = softwareSystem "PostgreSQL" "Job state storage backend (default)" "External"
        redis = softwareSystem "Redis / Valkey" "Alternative job state storage backend" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output file storage" "External"
        inferenceGW = softwareSystem "Inference Gateway" "LLM inference endpoint (llm-d / GIE / EPP / vLLM)" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "ServiceMonitor, PodMonitor, PrometheusRule CRDs" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and ReferenceGrant for ingress and cross-namespace secrets" "External"

        # Internal platform dependencies
        platformOperator = softwareSystem "opendatahub-operator / rhods-operator" "Deploys operator and sets component images via params.env" "Internal Platform"
        batchGatewayChart = softwareSystem "batch-gateway Helm Chart" "Upstream Helm chart embedded at /charts/batch-gateway" "Internal Platform"

        # Relationships - User interactions
        user -> batchGatewayWorkloads "Submits batch jobs via" "HTTP/HTTPS 8000/TCP"
        user -> k8sAPI "Creates LLMBatchGateway CRs via kubectl" "HTTPS/443"
        platformOp -> platformOperator "Configures component images"

        # Relationships - Operator
        platformOperator -> batchGatewayOperator "Deploys and sets image env vars" "params.env"
        batchGatewayOperator -> k8sAPI "CRUD on managed resources via Server-Side Apply" "HTTPS/443, TLS 1.2+"
        batchGatewayOperator -> batchGatewayWorkloads "Creates and manages Deployments, Services, ConfigMaps" "Server-Side Apply"
        batchGatewayOperator -> certManager "Creates Certificate CRs for TLS" "HTTPS/443"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "HTTPS/443"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, reads ReferenceGrants" "HTTPS/443"

        # Relationships - Workloads
        apiServer -> postgresql "Reads/writes job state" "TCP/5432"
        apiServer -> s3 "Stores/retrieves batch files" "HTTPS/443"
        processor -> postgresql "Dequeues jobs, updates status" "TCP/5432"
        processor -> inferenceGW "Forwards inference requests" "HTTP/HTTPS, Optional mTLS"
        processor -> s3 "Reads input, writes output" "HTTPS/443"
        garbageCollector -> postgresql "Cleans expired records" "TCP/5432"
        garbageCollector -> s3 "Deletes expired files" "HTTPS/443"

        # Optional alternatives
        apiServer -> redis "Alternative state storage" "TCP/6379"
        processor -> redis "Alternative state storage" "TCP/6379"
        garbageCollector -> redis "Alternative state storage" "TCP/6379"

        # Observability
        apiServer -> otlpCollector "Exports traces" "gRPC/4317"
        processor -> otlpCollector "Exports traces" "gRPC/4317"
        garbageCollector -> otlpCollector "Exports traces" "gRPC/4317"

        # Internal container relationships
        controller -> helmRenderer "Renders chart with CR spec values"
        controller -> secretSync "Delegates cross-namespace secret handling"
    }

    views {
        systemContext batchGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container batchGatewayOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container batchGatewayWorkloads "WorkloadContainers" {
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
                background #08427b
                color #ffffff
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

workspace {
    model {
        platformAdmin = person "Platform Admin" "Creates and manages LLMBatchGateway CRs for batch inference"
        client = person "Batch Client" "Submits batch inference jobs via API server"

        batchGatewayOperator = softwareSystem "LLM-D Batch Gateway Operator" "Kubernetes operator that reconciles LLMBatchGateway CRs into managed batch inference workloads via Helm chart rendering" {
            reconciler = container "LLMBatchGatewayReconciler" "Main reconcile loop: validates spec, resolves secrets, renders Helm charts, applies resources, garbage-collects orphans" "Go (controller-runtime)"
            metricsController = container "MetricsController" "Ensures operator self-monitoring infrastructure (Service, ServiceMonitor, PrometheusRule)" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Loads and renders embedded Helm charts (batch-gateway, async-processor) with CRD-derived values" "Go (helm.sh/helm/v3)"
        }

        managedWorkloads = softwareSystem "Managed Batch Gateway Workloads" "Helm-rendered workloads managed by the operator" {
            apiServer = container "API Server" "HTTP endpoint for batch job submission and file management" "Container (batch-gateway-apiserver)"
            processor = container "Processor" "Dispatches inference requests to gateways with AIMD concurrency control" "Container (batch-gateway-processor)"
            garbageCollector = container "Garbage Collector" "Expires completed jobs and orphaned files" "Container (batch-gateway-gc)"
            asyncProcessor = container "Async-Processor" "Dispatches inference asynchronously via Redis MQ (optional)" "Container (llm-d-async)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, leader election" "External"
        platformOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator that deploys this operator via kustomize" "Internal Platform"
        inferenceGateway = softwareSystem "Inference Gateway / EPP" "LLM inference serving endpoint" "Internal Platform"
        postgresql = softwareSystem "PostgreSQL" "Job state persistence database" "External"
        redis = softwareSystem "Redis / Valkey" "Alternative job state backend and async message queue" "External"
        s3 = softwareSystem "S3 / MinIO" "Batch input/output file storage" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring CRDs (ServiceMonitor, PodMonitor, PrometheusRule)" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and ReferenceGrant for ingress and cross-namespace access" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace collection" "External"

        # Relationships - Operator
        platformAdmin -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl"
        platformOperator -> batchGatewayOperator "Deploys via kustomize, sets component images" "Kustomize"
        batchGatewayOperator -> kubernetesAPI "Watches CRs, applies resources via SSA" "HTTPS/443"
        batchGatewayOperator -> managedWorkloads "Creates and manages workload resources" "Server-Side Apply"

        reconciler -> helmRenderer "Renders charts with CRD-derived values"
        reconciler -> kubernetesAPI "CRUD resources, leader election" "HTTPS/443 TLS 1.2+"

        # Relationships - Managed Workloads
        client -> apiServer "Submits batch jobs, manages files" "HTTP/HTTPS 8000"
        apiServer -> postgresql "Stores job state" "PostgreSQL/5432 Optional TLS"
        apiServer -> redis "Stores job state (alternative)" "Redis/6379 Optional TLS"
        apiServer -> s3 "Stores batch files" "HTTPS/443 TLS"
        processor -> inferenceGateway "Dispatches inference requests (sync)" "HTTP/HTTPS Optional TLS/mTLS"
        processor -> postgresql "Reads/updates job state" "PostgreSQL/5432"
        processor -> s3 "Reads input, writes output" "HTTPS/443"
        asyncProcessor -> redis "Polls MQ, reads/writes" "Redis/6379 Optional TLS"
        asyncProcessor -> inferenceGateway "Dispatches inference (async)" "HTTP/HTTPS Optional TLS/mTLS"

        # Relationships - Optional integrations
        batchGatewayOperator -> certManager "Creates Certificate CRs for TLS" "HTTPS/443"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "HTTPS/443"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoute, reads ReferenceGrant" "HTTPS/443"
        apiServer -> otlpCollector "Exports traces (optional)" "gRPC/4317"
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

        container managedWorkloads "ManagedWorkloadContainers" {
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
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

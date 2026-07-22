workspace {
    model {
        platformAdmin = person "Platform Admin" "Creates and configures LLMBatchGateway custom resources"
        dataScientist = person "Data Scientist" "Submits batch inference jobs via API"

        batchGatewayOperator = softwareSystem "LLM-D Batch Gateway Operator" "Kubernetes operator that manages the full lifecycle of LLM-D batch gateway deployments for batch LLM inference workloads" {
            operator = container "Operator Controller" "Watches LLMBatchGateway CRs, renders Helm charts, applies via SSA, garbage-collects orphans" "Go (controller-runtime)"
            metricsController = container "Metrics Controller" "Self-heals operator monitoring resources (Service, ServiceMonitor, PrometheusRule)" "Go (controller-runtime)"
            batchChart = container "Batch-Gateway Helm Chart" "Embedded chart defining API server, processor, GC templates" "Helm v3 (template-only)"
            asyncChart = container "Async-Processor Helm Chart" "Embedded chart defining async processor deployment templates" "Helm v3 (template-only)"
        }

        managedAPIServer = softwareSystem "Managed API Server" "HTTP server accepting batch job submissions (/v1/batches, /v1/files)" "Managed Component"
        managedProcessor = softwareSystem "Managed Processor" "Dispatches individual inference requests from batch jobs (sync mode)" "Managed Component"
        managedGC = softwareSystem "Managed Garbage Collector" "Expires old jobs and files" "Managed Component"
        managedAsyncProcessor = softwareSystem "Managed Async Processor" "Polls Redis queues and dispatches inference requests (async mode)" "Managed Component"

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys this operator via kustomize overlays" "Internal RHOAI"
        inferenceGateway = softwareSystem "Inference Gateway (llm-d GIE/EPP)" "Serves LLM inference requests" "Internal RHOAI"
        postgresql = softwareSystem "PostgreSQL" "Job state persistence (default backend)" "External"
        redis = softwareSystem "Redis / Valkey" "Alternative state backend or async message queue" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output file storage" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry distributed tracing" "External"

        # Relationships - Operator
        platformAdmin -> batchGatewayOperator "Creates LLMBatchGateway CRs via kubectl"
        batchGatewayOperator -> kubernetes "Watches CRs, applies resources via SSA" "HTTPS/443"
        rhodsOperator -> batchGatewayOperator "Deploys via kustomize overlay; provides params.env images"

        # Relationships - Managed Components
        batchGatewayOperator -> managedAPIServer "Creates and manages" "SSA"
        batchGatewayOperator -> managedProcessor "Creates and manages" "SSA"
        batchGatewayOperator -> managedGC "Creates and manages" "SSA"
        batchGatewayOperator -> managedAsyncProcessor "Creates and manages (optional)" "SSA"

        dataScientist -> managedAPIServer "Submits batch jobs" "HTTP/HTTPS 8000/TCP"
        managedAPIServer -> postgresql "Stores job state" "TCP/5432"
        managedAPIServer -> s3 "Stores input/output files" "HTTPS/443"
        managedProcessor -> postgresql "Reads/updates job state" "TCP/5432"
        managedProcessor -> inferenceGateway "Dispatches inference requests (sync)" "HTTP/HTTPS, Bearer token"
        managedProcessor -> s3 "Reads/writes batch files" "HTTPS/443"
        managedProcessor -> redis "Enqueues async requests" "TCP/6379"
        managedGC -> postgresql "Expires old jobs" "TCP/5432"
        managedAsyncProcessor -> redis "Polls queue, writes results" "TCP/6379"
        managedAsyncProcessor -> inferenceGateway "Dispatches inference requests (async)" "HTTP/HTTPS"

        # Observability
        prometheus -> batchGatewayOperator "Scrapes operator metrics" "HTTP/8443"
        prometheus -> managedAPIServer "Scrapes API server metrics" "HTTP/8081"
        prometheus -> managedProcessor "Scrapes processor metrics" "HTTP/9090"
        prometheus -> managedGC "Scrapes GC metrics" "HTTP/9091"
        managedAPIServer -> otlpCollector "Exports traces" "gRPC/4317"
        managedProcessor -> otlpCollector "Exports traces" "gRPC/4317"

        # Optional dependencies
        batchGatewayOperator -> certManager "Creates Certificate CRs for TLS"
    }

    views {
        systemContext batchGatewayOperator "SystemContext" {
            include *
            autoLayout
        }

        container batchGatewayOperator "Containers" {
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
            element "Managed Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
        }
    }
}

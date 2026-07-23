workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates batch inference jobs via LLMBatchGateway CRs"
        platformAdmin = person "Platform Admin" "Deploys and configures the operator via RHOAI"

        batchGatewayOperator = softwareSystem "LLM-D Batch Gateway Operator" "Manages lifecycle of batch inference gateway deployments via Helm chart rendering" {
            controller = container "LLMBatchGateway Controller" "Reconciles LLMBatchGateway CRs into Kubernetes resources by rendering Helm charts via Server-Side Apply" "Go (controller-runtime)"
            metricsController = container "Metrics Controller" "Ensures operator self-monitoring infrastructure (Service, ServiceMonitor, PrometheusRule)" "Go (controller-runtime)"
            helmRenderer = container "Helm Renderer" "Renders embedded batch-gateway and async-processor Helm charts at runtime" "Helm v3 SDK"
            secretSync = container "Secret Sync" "Cross-namespace secret resolution using Gateway API ReferenceGrant" "Go"
        }

        managedStack = softwareSystem "Batch Gateway Stack" "Managed workloads created by the operator per LLMBatchGateway CR" {
            apiServer = container "API Server" "Accepts batch job submissions via OpenAI-compatible HTTP API" "Container"
            processor = container "Processor" "Dispatches individual inference requests to inference gateways" "Container"
            garbageCollector = container "Garbage Collector" "Expires old jobs and files" "Container"
            asyncProcessor = container "Async Processor" "Queue-based dispatch to inference pools (optional)" "Container"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Platform operator that configures component images via params.env" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and ReferenceGrant for ingress and cross-namespace access" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "ServiceMonitor, PodMonitor, PrometheusRule monitoring" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        postgresql = softwareSystem "PostgreSQL" "Job state storage backend" "External"
        redis = softwareSystem "Redis / Valkey" "Job state storage or async message queue" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Batch input/output file storage" "External"
        inferenceGateway = softwareSystem "Inference Gateway / llm-d EPP" "Target for inference request dispatch" "Internal RHOAI"
        otlpCollector = softwareSystem "OTLP Collector" "OpenTelemetry trace export" "External"

        user -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl/API"
        platformAdmin -> rhoaiOperator "Configures RHOAI platform"
        rhoaiOperator -> batchGatewayOperator "Sets component image env vars via params.env"

        batchGatewayOperator -> k8sAPI "CR watches, resource CRUD, status updates" "HTTPS/6443"
        batchGatewayOperator -> certManager "Creates Certificate CRs for TLS" "Kubernetes API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, reads ReferenceGrants" "Kubernetes API"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "Kubernetes API"
        prometheus -> batchGatewayOperator "Scrapes operator metrics" "HTTP/8443"

        batchGatewayOperator -> managedStack "Creates and manages via Server-Side Apply"

        managedStack -> postgresql "Job state storage" "TCP/Configurable"
        managedStack -> redis "State store or async message queue" "TCP/Configurable"
        managedStack -> s3 "Batch file storage" "HTTPS/443"
        managedStack -> inferenceGateway "Inference request dispatch" "HTTP(S)/Configurable"
        managedStack -> otlpCollector "Trace export" "HTTP or gRPC"
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

        container managedStack "ManagedStackContainers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

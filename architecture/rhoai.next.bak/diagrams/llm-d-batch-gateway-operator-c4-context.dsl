workspace {
    model {
        admin = person "Platform Admin" "Deploys and configures batch inference gateways via LLMBatchGateway CRs"
        client = person "API Client" "Submits batch inference jobs and retrieves results via OpenAI-compatible API"

        batchGatewayOperator = softwareSystem "LLM-D Batch Gateway Operator" "Kubernetes operator that reconciles LLMBatchGateway CRs into managed batch gateway deployments via embedded Helm chart rendering" {
            controller = container "LLMBatchGateway Controller" "Main reconciliation loop: fetches CR, resolves secrets, renders Helm chart, applies resources via Server-Side Apply, garbage-collects orphans, updates status" "Go (controller-runtime)"
            metricsController = container "MetricsController" "Ensures operator's own metrics Service, ServiceMonitor, and PrometheusRule are always present; self-heals on deletion" "Go (controller-runtime)"
            helmRenderer = container "HelmRenderer" "Loads embedded batch-gateway Helm chart, maps CRD spec to Helm values, renders templates into unstructured Kubernetes objects" "Go (Helm v3 library)"
            secretSync = container "Secret Sync" "Handles cross-namespace secret resolution using Gateway API ReferenceGrant, copies secrets into CR namespace with owner references" "Go"
        }

        batchGatewaySystem = softwareSystem "Batch Gateway System" "Managed workloads deployed by the operator" {
            apiserver = container "API Server" "OpenAI-compatible batch inference API: accepts batch jobs and file uploads" "Container (8000/TCP)"
            processor = container "Processor" "Dispatches inference requests to backend LLM gateways with AIMD concurrency control" "Container"
            gc = container "Garbage Collector" "Cleans up expired jobs and files" "Container"
        }

        platformOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator that deploys this operator via kustomize manifests and supplies component image references via params.env" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, CRD watch, leader election" "Infrastructure"
        inferenceGW = softwareSystem "Inference Gateway (vLLM / GIE/EPP)" "Backend LLM inference endpoints" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for batch job state storage" "External"
        redis = softwareSystem "Redis / Valkey" "Alternative database backend for batch job state" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for batch input/output files" "External"
        certManager = softwareSystem "cert-manager" "Automatic TLS certificate provisioning" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute for ingress, ReferenceGrant for cross-namespace access" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "ServiceMonitor, PodMonitor, PrometheusRule for metrics collection" "External"

        # Relationships
        admin -> batchGatewayOperator "Creates/updates LLMBatchGateway CRs" "kubectl"
        client -> batchGatewaySystem "Submits batch jobs" "HTTP/HTTPS 8000/TCP"
        platformOperator -> batchGatewayOperator "Deploys operator, supplies component images" "kustomize + params.env"

        batchGatewayOperator -> k8sAPI "CRD watch, resource CRUD, leader election" "HTTPS/443"
        batchGatewayOperator -> batchGatewaySystem "Creates and manages via Server-Side Apply" "K8s API"
        batchGatewayOperator -> certManager "Creates Certificate resources" "K8s API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, watches ReferenceGrants" "K8s API"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "K8s API"

        controller -> helmRenderer "Renders chart with CR spec values"
        controller -> secretSync "Resolves cross-namespace secrets"

        apiserver -> postgresql "Stores job metadata" "PostgreSQL/5432"
        apiserver -> s3 "Stores input/output files" "HTTPS/443"
        processor -> inferenceGW "Dispatches inference requests" "HTTP/HTTPS"
        processor -> postgresql "Polls for pending jobs" "PostgreSQL/5432"
        processor -> s3 "Writes result files" "HTTPS/443"
        gc -> postgresql "Queries expired jobs" "PostgreSQL/5432"
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

        container batchGatewaySystem "ManagedWorkloads" {
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
            element "Infrastructure" {
                background #4a90e2
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

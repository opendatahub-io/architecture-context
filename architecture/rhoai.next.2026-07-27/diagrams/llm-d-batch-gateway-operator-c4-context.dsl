workspace {
    model {
        admin = person "Platform Admin" "Deploys and configures batch inference gateways"
        datascientist = person "Data Scientist" "Submits batch inference jobs via API"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Kubernetes operator managing LLMBatchGateway CRs to deploy multi-component batch inference gateways via Helm chart rendering" {
            controllerManager = container "Controller Manager" "Watches LLMBatchGateway CRs, renders Helm charts, reconciles child resources" "Go / controller-runtime"
            llmBatchGatewayReconciler = container "LLMBatchGateway Reconciler" "Primary reconciler for LLMBatchGateway CRs, manages Deployments, Services, ConfigMaps, Secrets, HTTPRoutes, Certificates" "Go Controller"
            metricsController = container "Metrics Controller" "Reconciles ServiceMonitors, PodMonitors, PrometheusRules when POD_NAMESPACE is set" "Go Controller"
            helmRenderer = container "Helm Chart Renderer" "Renders embedded batch-gateway and async-processor Helm charts with CR spec values and pinned images" "helm.sh/helm/v3"
        }

        apiServer = softwareSystem "Batch Gateway API Server" "HTTP API for batch job submission" "Managed Workload"
        requestProcessor = softwareSystem "Request Processor" "Dispatches inference requests (sync HTTP or async Redis)" "Managed Workload"
        garbageCollector = softwareSystem "Garbage Collector" "Cleans up expired jobs and files" "Managed Workload"
        asyncProcessor = softwareSystem "Async Processor" "Redis queue-based inference dispatch (optional, dispatchMode=async)" "Managed Workload"

        kubernetes = softwareSystem "Kubernetes API" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Platform Dependency"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based traffic routing" "Platform Dependency"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring resource management and metrics scraping" "Platform Dependency"
        inferenceGateway = softwareSystem "Inference Gateway" "Model inference endpoint for request dispatch" "External"
        database = softwareSystem "Database" "PostgreSQL, Redis, or Valkey backend for batch state" "External"
        storage = softwareSystem "Object Storage" "S3 or PVC for file storage" "External"

        admin -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl"
        datascientist -> apiServer "Submits batch inference jobs" "HTTP"

        batchGatewayOperator -> kubernetes "Watches CRs, creates/updates child resources" "HTTPS/6443, TLS 1.2+, SA token"
        batchGatewayOperator -> certManager "Creates Certificate CRs for TLS" "Kubernetes API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes for traffic routing" "Kubernetes API"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitors, PodMonitors, PrometheusRules" "Kubernetes API"

        batchGatewayOperator -> apiServer "Deploys via Helm-rendered Deployments"
        batchGatewayOperator -> requestProcessor "Deploys via Helm-rendered Deployments"
        batchGatewayOperator -> garbageCollector "Deploys via Helm-rendered Deployments"
        batchGatewayOperator -> asyncProcessor "Deploys via Helm-rendered Deployments (conditional)"

        requestProcessor -> inferenceGateway "Sync: HTTP dispatch" "HTTP"
        asyncProcessor -> inferenceGateway "Async: Redis queue dispatch via EPP" "Redis/HTTP"
        apiServer -> database "Batch job state management"
        garbageCollector -> storage "Expired file cleanup"
        requestProcessor -> database "Job status updates"
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
            element "Platform Dependency" {
                background #d79b00
                color #ffffff
            }
            element "Managed Workload" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        admin = person "Platform Admin" "Creates and manages LLMBatchGateway custom resources"
        datascientist = person "Data Scientist" "Submits batch inference jobs via API server"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Kubernetes operator that manages batch inference gateway deployments via Helm chart rendering and Server-Side Apply" {
            reconciler = container "LLMBatchGatewayReconciler" "Primary controller: renders Helm charts, applies resources, manages status, orphan cleanup, cross-namespace secret sync" "Go (controller-runtime)"
            metricsController = container "MetricsController" "Ensures operator-level Service, ServiceMonitor, and PrometheusRule resources" "Go (controller-runtime)"
            tlsWatcher = container "TLS Profile Watcher" "Watches OpenShift TLS profile changes and triggers graceful restart" "Go (SecurityProfileWatcher)"
            helmRenderer = container "Helm Renderer" "Loads and renders embedded batch-gateway and async-processor Helm charts" "Go (Helm v3 SDK)"
        }

        # Rendered operands
        apiServer = softwareSystem "Batch Gateway API Server" "OpenAI-compatible batch job submission endpoint" "Operand"
        processor = softwareSystem "Batch Gateway Processor" "Dispatches inference requests (sync mode)" "Operand"
        garbageCollector = softwareSystem "Batch Gateway GC" "Cleans up expired jobs and files" "Operand"
        asyncProcessor = softwareSystem "Async Processor" "Redis queue-based inference dispatch (optional, async mode)" "Operand"

        # Platform dependencies
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        odhOperator = softwareSystem "opendatahub-operator / rhods-operator" "Parent platform operator that deploys this operator" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute-based ingress and ReferenceGrant authorization" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring resource management (ServiceMonitor, PrometheusRule)" "External"
        openshiftConfig = softwareSystem "OpenShift APIServer Config" "Cluster-wide TLS profile configuration" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning for Services" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"

        # Relationships
        admin -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl/API"
        datascientist -> apiServer "Submits batch inference jobs" "HTTPS"

        reconciler -> helmRenderer "Renders charts with CR spec values"
        reconciler -> kubernetesAPI "CRUD, watches, SSA, status updates" "HTTPS/6443"
        metricsController -> kubernetesAPI "Ensures monitoring resources" "HTTPS/6443"
        tlsWatcher -> kubernetesAPI "Watches config.openshift.io/v1 APIServer" "HTTPS/6443"

        batchGatewayOperator -> apiServer "Deploys via Helm chart rendering"
        batchGatewayOperator -> processor "Deploys via Helm chart rendering"
        batchGatewayOperator -> garbageCollector "Deploys via Helm chart rendering"
        batchGatewayOperator -> asyncProcessor "Deploys via Helm chart rendering (async mode)"

        odhOperator -> batchGatewayOperator "Deploys operator, provides image refs via params.env"
        batchGatewayOperator -> certManager "Creates Certificate CRs (conditional)" "HTTPS/6443"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, reads ReferenceGrants (conditional)" "HTTPS/6443"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule (conditional)" "HTTPS/6443"
        batchGatewayOperator -> openshiftConfig "Reads cluster TLS profile" "HTTPS/6443"
        serviceCa -> batchGatewayOperator "Provisions TLS cert for metrics Service"
        prometheus -> batchGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443"
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
                color #000000
            }
            element "Operand" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}

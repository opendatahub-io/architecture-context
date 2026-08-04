workspace {
    model {
        platformOperator = person "Platform Operator" "Creates and manages LLMBatchGateway custom resources"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Kubernetes operator managing lifecycle of LLMBatchGateway CRs, deploying batch inference gateway stack via embedded Helm charts" {
            manager = container "Manager" "controller-runtime based operator manager process" "Go"
            reconciler = container "LLMBatchGatewayReconciler" "Reconciles LLMBatchGateway CRs, renders Helm charts, applies resources via SSA" "Go Controller"
            metricsController = container "MetricsController" "Creates and maintains operator metrics Service, ServiceMonitor, PrometheusRule" "Go Controller"
            helmRenderer = container "Helm Chart Renderer" "Renders embedded batch-gateway and async-processor charts" "Helm v3"
        }

        batchGatewayStack = softwareSystem "Batch Gateway Stack" "Deployed inference gateway components" {
            apiServer = container "API Server" "Batch inference API server" "Deployment"
            processor = container "Request Processor" "Processes batch inference requests" "Deployment"
            garbageCollector = container "Garbage Collector" "Cleans up completed batch resources" "Deployment"
            asyncProcessor = container "Async Processor" "Handles async inference requests (conditional)" "Deployment"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management (conditional)" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes routing via HTTPRoutes and ReferenceGrants (conditional)" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack for ServiceMonitors, PodMonitors, PrometheusRules (conditional)" "External"

        platformOperator -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl/API"
        batchGatewayOperator -> kubernetesAPI "CRUD on managed resources" "HTTPS/6443 TLS 1.2+ SA Token"
        batchGatewayOperator -> batchGatewayStack "Deploys via server-side apply"
        batchGatewayOperator -> certManager "Creates Certificate CRs (if CRD detected)" "Kubernetes API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, reads ReferenceGrants (if CRD detected)" "Kubernetes API"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitors, PodMonitors, PrometheusRules (if CRD detected)" "Kubernetes API"

        manager -> reconciler "Starts and manages"
        manager -> metricsController "Starts and manages"
        reconciler -> helmRenderer "Renders charts with CR-derived values"
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

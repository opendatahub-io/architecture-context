workspace {
    model {
        admin = person "Platform Admin" "Creates and manages LLMBatchGateway custom resources"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Kubernetes operator that manages LLMBatchGateway CRs, deploying batch inference gateway infrastructure via embedded Helm charts" {
            manager = container "Manager" "Main operator process; runs reconcilers, metrics controller, TLS watcher" "Go controller-runtime"
            reconciler = container "LLMBatchGateway Reconciler" "Watches LLMBatchGateway CRs and renders embedded Helm charts into managed resources" "controller-runtime Reconciler"
            metricsController = container "Metrics Controller" "Creates and manages operator self-monitoring resources (Service, ServiceMonitor, PrometheusRule)" "controller-runtime Reconciler"
            secretSync = container "Secret Synchronizer" "Cross-namespace secret synchronization gated by ReferenceGrant" "Go component"
            tlsWatcher = container "SecurityProfile Watcher" "Watches OpenShift APIServer TLS profile and triggers graceful restart on change" "Go component"
            batchGatewayChart = container "batch-gateway Helm Chart" "Embedded chart rendering API server, garbage collector, services, configmaps" "Helm v3"
            asyncProcessorChart = container "async-processor Helm Chart" "Embedded chart rendering async processor deployment and supporting resources" "Helm v3"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API server" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management" "External"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API for traffic routing" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Prometheus monitoring stack operator" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile configuration" "External"
        servingCertSigner = softwareSystem "OpenShift service-serving-cert signer" "Auto-provisions TLS certificates for operator metrics" "External"

        admin -> batchGatewayOperator "Creates LLMBatchGateway CRs via kubectl" "HTTPS/6443"
        batchGatewayOperator -> k8sAPI "Watches CRs, creates/updates managed resources" "HTTPS/6443"
        batchGatewayOperator -> certManager "Creates Certificate CRs for managed workload TLS" "Kubernetes API"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoute resources for batch gateway routing" "Kubernetes API"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "Kubernetes API"
        batchGatewayOperator -> openshiftAPIServer "Reads TLS profile, watches for changes" "Kubernetes API"
        prometheus -> batchGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443"
        servingCertSigner -> batchGatewayOperator "Provisions metrics TLS certificate" "Kubernetes API"

        manager -> reconciler "Starts and manages"
        manager -> metricsController "Starts and manages"
        manager -> tlsWatcher "Starts and manages"
        reconciler -> secretSync "Delegates secret sync"
        reconciler -> batchGatewayChart "Renders with runtime values"
        reconciler -> asyncProcessorChart "Renders with runtime values"
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

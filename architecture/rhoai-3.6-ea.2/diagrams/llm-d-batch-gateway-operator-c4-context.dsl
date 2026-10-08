workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures batch inference gateway deployments via LLMBatchGateway CRs"

        batchGatewayOperator = softwareSystem "llm-d-batch-gateway-operator" "Kubernetes operator that reconciles LLMBatchGateway CRs into batch gateway deployments via embedded Helm chart rendering" {
            reconciler = container "LLMBatchGatewayReconciler" "Primary reconcile loop: renders Helm charts, applies resources via SSA, manages status conditions" "Go Controller"
            metricsController = container "MetricsController" "Ensures operator self-monitoring resources stay consistent" "Go Controller"
            securityWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS profile changes and triggers operator restart" "Go Controller"
            helmRenderer = container "HelmRenderer" "In-process Helm v3 chart rendering for batch-gateway and async-processor charts" "Go Library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRUD on all managed resources" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning via Certificate CRDs" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute for ingress and ReferenceGrant for cross-namespace secret authorization" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack providing ServiceMonitor, PodMonitor, and PrometheusRule CRDs" "External"
        openshiftConfig = softwareSystem "OpenShift Config API" "Cluster-wide TLS profile configuration via config.openshift.io/APIServer" "External"
        serviceCA = softwareSystem "OpenShift service-ca" "Provisions and auto-rotates TLS certificates for Services" "External"
        parentOperator = softwareSystem "opendatahub-operator / ai-gateway-operator" "Parent platform operator that injects component images via environment variables" "Internal Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "External"

        platformAdmin -> batchGatewayOperator "Creates LLMBatchGateway CR via kubectl/oc"
        batchGatewayOperator -> kubernetesAPI "CRUD on Deployments, StatefulSets, Services, Secrets, ConfigMaps, RBAC" "HTTPS/6443"
        batchGatewayOperator -> certManager "Creates Certificate CRs for API server TLS" "HTTPS/6443"
        batchGatewayOperator -> gatewayAPI "Creates HTTPRoutes, reads ReferenceGrants" "HTTPS/6443"
        batchGatewayOperator -> prometheusOperator "Creates ServiceMonitor, PodMonitor, PrometheusRule" "HTTPS/6443"
        batchGatewayOperator -> openshiftConfig "Reads cluster-wide TLS profile" "HTTPS/6443"
        serviceCA -> batchGatewayOperator "Provisions metrics TLS certificate"
        parentOperator -> batchGatewayOperator "Injects component images via env vars"
        prometheus -> batchGatewayOperator "Scrapes /metrics endpoint" "HTTPS/8443"

        reconciler -> helmRenderer "Renders charts with CR-derived values"
        securityWatcher -> reconciler "Triggers restart on TLS profile change"
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
            element "Internal Platform" {
                background #9b59b6
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
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

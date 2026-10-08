workspace {
    model {
        user = person "Data Scientist / Platform Admin" "Queries metrics, views dashboards, investigates traces"

        odhObservability = softwareSystem "odh-observability" "Kubernetes operator that declaratively provisions a complete observability stack for RHOAI" {
            controller = container "odh-observability Controller" "Reconciles Monitoring CR, provisions subsystems via ~50 embedded templates and SSA" "Go controller-runtime"
            webhook = container "Mutating Webhook" "Injects scrape labels on PodMonitor/ServiceMonitor in opt-in namespaces" "Admission Webhook"
            clusterProxy = container "Cluster Prometheus Proxy" "kube-rbac-proxy for cluster-wide metrics access" "kube-rbac-proxy"
            namespaceProxy = container "Namespace Prometheus Proxy" "kube-rbac-proxy + prom-label-proxy for tenant-isolated metrics" "kube-rbac-proxy + prom-label-proxy"
            thanosProxy = container "Thanos Querier Proxy" "kube-rbac-proxy + prom-label-proxy for multi-namespace queries" "kube-rbac-proxy + prom-label-proxy"
            korrel8r = container "korrel8r" "Cross-signal correlation engine for metrics, logs, and traces" "Go Service"
        }

        coo = softwareSystem "Cluster Observability Operator" "Provides MonitoringStack and ThanosQuerier CRDs" "External Operator"
        tempoOp = softwareSystem "Tempo Operator" "Provides Tempo CRDs for distributed tracing" "External Operator"
        otelOp = softwareSystem "OpenTelemetry Operator" "Provides OpenTelemetryCollector and Instrumentation CRDs" "External Operator"
        persesOp = softwareSystem "Perses Operator" "Provides Perses CRDs for dashboarding" "External Operator"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for webhook" "External Operator"
        lokiOp = softwareSystem "Loki Operator" "Provides LokiStack CRD for log storage" "External Operator"
        clo = softwareSystem "Cluster Logging Operator" "Provides ClusterLogForwarder for log forwarding" "External Operator"
        prometheus = softwareSystem "Prometheus (MonitoringStack)" "Metrics storage and alerting" "Managed by COO"
        thanos = softwareSystem "Thanos Querier" "Multi-instance metrics aggregation" "Managed by COO"
        tempo = softwareSystem "Tempo" "Distributed trace storage" "Managed by Tempo Operator"
        lokiStack = softwareSystem "LokiStack" "Log storage for usage logs" "Managed by Loki Operator"
        perses = softwareSystem "Perses" "Observability dashboards" "Managed by Perses Operator"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress routing for external access" "External"
        kserve = softwareSystem "KServe" "ML inference serving platform" "Internal ODH"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking" "Internal ODH"

        user -> odhObservability "Queries metrics and traces via proxy routes"
        user -> perses "Views observability dashboards"

        odhObservability -> coo "Creates MonitoringStack, ThanosQuerier, ServiceMonitor, PrometheusRule" "Kubernetes API"
        odhObservability -> tempoOp "Creates TempoMonolithic/TempoStack" "Kubernetes API"
        odhObservability -> otelOp "Creates OpenTelemetryCollector, Instrumentation" "Kubernetes API"
        odhObservability -> persesOp "Creates Perses, PersesDatasource, PersesDashboard" "Kubernetes API"
        odhObservability -> certManager "Creates Certificate, Issuer" "Kubernetes API"
        odhObservability -> lokiOp "Creates LokiStack" "Kubernetes API"
        odhObservability -> clo "Creates ClusterLogForwarder" "Kubernetes API"
        odhObservability -> k8sAPI "CRUD on managed resources, reads APIServer TLS profile" "HTTPS/6443"
        odhObservability -> openShiftRouter "Creates Routes for external access" "Kubernetes API"
        odhObservability -> kserve "Watches InferenceService for namespace discovery" "Kubernetes API"
        odhObservability -> mlflow "Updates MLflow Experiment for trace export" "Kubernetes API"
        odhObservability -> prometheus "Proxies metrics queries" "HTTPS/8443"
        odhObservability -> thanos "Proxies aggregated queries" "HTTPS/8443"
        korrel8r -> prometheus "Reads metrics" "HTTPS"
        korrel8r -> tempo "Reads traces" "HTTPS"
        korrel8r -> lokiStack "Reads logs" "HTTPS"
    }

    views {
        systemContext odhObservability "SystemContext" {
            include *
            autoLayout
        }

        container odhObservability "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External Operator" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #cccccc
            }
            element "Managed by COO" {
                background #d5e8d4
            }
            element "Managed by Tempo Operator" {
                background #d5e8d4
            }
            element "Managed by Loki Operator" {
                background #d5e8d4
            }
            element "Managed by Perses Operator" {
                background #d5e8d4
            }
        }
    }
}

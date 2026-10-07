workspace {
    model {
        admin = person "Platform Admin" "Configures the observability stack via the Monitoring CR"
        user = person "Data Scientist / SRE" "Queries metrics, traces, and logs via dashboards"

        odhObservability = softwareSystem "odh-observability" "Kubernetes operator that provisions and manages a complete observability stack for OpenShift AI" {
            controller = container "MonitoringReconciler" "Watches Monitoring CR; renders and applies templates via SSA" "Go controller-runtime"
            webhook = container "Mutating Webhook" "Injects scrape labels on ServiceMonitor/PodMonitor in opted-in namespaces" "Go Webhook Server :9443"
            clusterProxy = container "Cluster Proxy" "kube-rbac-proxy providing cluster-wide Prometheus access" "Deployment :8443"
            namespaceProxy = container "Namespace Proxy" "kube-rbac-proxy + prom-label-proxy for tenant-scoped metrics" "Deployment :8443/:9090"
            korrel8r = container "Korrel8r" "Correlation engine linking metrics, logs, and traces" "Deployment :8443"
        }

        coo = softwareSystem "Cluster Observability Operator" "Provides MonitoringStack, ThanosQuerier, ServiceMonitor, PrometheusRule CRDs" "External Operator"
        tempoOp = softwareSystem "Tempo Operator" "Provides TempoMonolithic and TempoStack CRDs for distributed tracing" "External Operator"
        otelOp = softwareSystem "OpenTelemetry Operator" "Provides OpenTelemetryCollector and Instrumentation CRDs" "External Operator"
        persesOp = softwareSystem "Perses Operator" "Provides Perses, PersesDatasource, PersesDashboard CRDs" "External Operator"
        lokiOp = softwareSystem "Loki Operator" "Provides LokiStack CRD for log storage" "External Operator"
        loggingOp = softwareSystem "Cluster Logging Operator" "Provides ClusterLogForwarder CRD for log forwarding" "External Operator"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for the webhook" "External"
        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for watches, SSA apply, CRD discovery" "Infrastructure"
        openshiftApi = softwareSystem "OpenShift APIServer" "Cluster TLS security profile configuration" "Infrastructure"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, SSA deploy, template rendering, garbage collection" "Internal Library"

        admin -> odhObservability "Creates/configures Monitoring CR (default-monitoring)"
        user -> clusterProxy "Queries cluster-wide metrics" "HTTPS/8443 Bearer"
        user -> namespaceProxy "Queries namespace-scoped metrics" "HTTPS/8443 Bearer"
        user -> korrel8r "Runs correlation queries" "HTTPS/8443 Bearer"

        controller -> coo "Discovers and manages MonitoringStack, ThanosQuerier, ServiceMonitor, PrometheusRule" "HTTPS/6443"
        controller -> tempoOp "Discovers and manages TempoMonolithic/TempoStack" "HTTPS/6443"
        controller -> otelOp "Discovers and manages OpenTelemetryCollector, Instrumentation" "HTTPS/6443"
        controller -> persesOp "Discovers and manages Perses, datasources, dashboards" "HTTPS/6443"
        controller -> lokiOp "Discovers and manages LokiStack" "HTTPS/6443"
        controller -> loggingOp "Discovers and manages ClusterLogForwarder" "HTTPS/6443"
        controller -> certManager "Creates Issuer and Certificate for webhook TLS" "HTTPS/6443"
        controller -> k8sApi "Watches, SSA apply, CRD discovery, status updates" "HTTPS/6443"
        controller -> openshiftApi "Reads cluster TLS security profile" "HTTPS/6443"
        controller -> odhPlatformUtils "Template rendering, SSA deploy, garbage collection" "Go library"

        k8sApi -> webhook "Sends admission requests for PodMonitor/ServiceMonitor" "HTTPS/9443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Infrastructure" {
                background #d6b656
                color #ffffff
            }
            element "Internal Library" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}

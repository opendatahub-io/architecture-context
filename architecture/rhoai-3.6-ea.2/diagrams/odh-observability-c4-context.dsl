workspace {
    model {
        platformAdmin = person "Platform Admin" "Configures the RHOAI observability stack via Monitoring CR"
        dataSci = person "Data Scientist" "Queries metrics, views dashboards, and inspects traces"

        odhObservability = softwareSystem "odh-observability" "Kubernetes operator that declaratively provisions and manages the full RHOAI observability stack via a Monitoring CR" {
            controller = container "odh-observability Controller" "Reconciles Monitoring CR, renders embedded Go templates, applies resources via SSA, runs garbage collection" "Go controller-runtime"
            webhook = container "Mutating Admission Webhook" "Injects monitoring labels on ServiceMonitor/PodMonitor resources in opted-in namespaces" "Go Admission Webhook"
            clusterProxy = container "data-science-prometheus-cluster-proxy" "Authenticated HTTPS proxy for cluster-wide Prometheus metrics access" "kube-rbac-proxy"
            nsProxy = container "data-science-prometheus-namespace-proxy" "Namespace-scoped Prometheus proxy with tenant isolation via namespace label injection" "kube-rbac-proxy + prom-label-proxy"
            korrel8r = container "Korrel8r" "Cross-signal correlation engine linking logs, metrics, and traces" "REST Service"
        }

        clusterObsOp = softwareSystem "Cluster Observability Operator" "Manages MonitoringStack and ThanosQuerier CRDs for Prometheus metrics" "External Operator"
        tempoOp = softwareSystem "Tempo Operator" "Manages TempoMonolithic/TempoStack CRDs for distributed tracing" "External Operator"
        otelOp = softwareSystem "OpenTelemetry Operator" "Manages OpenTelemetryCollector and Instrumentation CRDs" "External Operator"
        persesOp = softwareSystem "Perses Operator" "Manages Perses dashboarding CRDs" "External Operator"
        lokiOp = softwareSystem "Loki Operator" "Manages LokiStack CRD for log storage" "External Operator"
        clusterLogging = softwareSystem "Cluster Logging Operator" "Manages ClusterLogForwarder for log forwarding" "External Operator"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for the webhook" "External Operator"
        prometheusOp = softwareSystem "prometheus-operator" "Provides ServiceMonitor, PodMonitor, and Probe CRDs" "External Operator"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Infrastructure"
        openshiftConfig = softwareSystem "OpenShift APIServer Config" "Cluster-wide TLS security profile configuration" "Infrastructure"
        kserve = softwareSystem "KServe" "ML inference serving; provides InferenceService CRDs" "Internal ODH"
        mlflow = softwareSystem "MLflow Operator" "ML experiment tracking" "Internal ODH"

        platformAdmin -> odhObservability "Creates/updates Monitoring CR"
        dataSci -> odhObservability "Queries metrics via namespace proxy Route" "HTTPS/443"

        odhObservability -> clusterObsOp "Creates MonitoringStack, ThanosQuerier, ServiceMonitor, PrometheusRule CRs" "Kubernetes API"
        odhObservability -> tempoOp "Creates TempoMonolithic/TempoStack CRs" "Kubernetes API"
        odhObservability -> otelOp "Creates OpenTelemetryCollector, Instrumentation CRs" "Kubernetes API"
        odhObservability -> persesOp "Creates Perses, PersesDatasource, PersesDashboard CRs" "Kubernetes API"
        odhObservability -> lokiOp "Creates LokiStack CRs" "Kubernetes API"
        odhObservability -> clusterLogging "Creates ClusterLogForwarder CRs" "Kubernetes API"
        odhObservability -> certManager "Creates Issuer, Certificate CRs for webhook TLS" "Kubernetes API"
        odhObservability -> k8sAPI "CRUD operations, garbage collection, resource management" "HTTPS/6443"
        odhObservability -> openshiftConfig "Reads cluster TLS profile for proxy configuration" "Kubernetes API"
        odhObservability -> prometheusOp "Reads ServiceMonitor, PodMonitor, Probe CRDs" "Kubernetes API"
        odhObservability -> kserve "Reads InferenceService CRs to discover namespaces for log forwarding" "Kubernetes API"
        odhObservability -> mlflow "Updates Experiment CRs for trace export" "Kubernetes API"
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
            element "Infrastructure" {
                background #6c8ebf
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}

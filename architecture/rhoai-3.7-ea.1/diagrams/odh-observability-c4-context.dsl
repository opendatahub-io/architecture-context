workspace {
    model {
        admin = person "Cluster Admin" "Configures the Monitoring CR (directly or via DSCI)"
        tenant = person "Data Scientist / Tenant" "Queries namespace-scoped metrics via Perses or Routes"

        odhObs = softwareSystem "odh-observability" "Operator that reconciles the singleton Monitoring CR into the RHOAI observability stack" {
            manager = container "Manager" "MonitoringReconciler: prerequisite checks, template render, SSA apply, label GC. Metrics :8443, health :8081" "Go controller-runtime"
            webhook = container "Mutating Webhook" "Adds monitoring.opendatahub.io/scrape=true to PodMonitors/ServiceMonitors in opted-in namespaces (:9443)" "Go"
            probe = container "Admission Probe" "Canary PodMonitor every 5 min to verify the admission path" "Go runnable"
            nsProxy = container "Namespace Query Proxies" "kube-rbac-proxy -> method-gate -> prom-label-proxy in front of DS Prometheus and Thanos (:8443)" "Deployment"
            clusterProxy = container "Cluster Proxy" "kube-rbac-proxy allow-paths=/metrics, mTLS to prometheus-operated:9090" "Deployment"
            korrel8r = container "Korrel8r" "Signal correlation REST API (:8443)" "Deployment"
        }

        platformOp = softwareSystem "rhods-operator / opendatahub-operator" "Drives the module via ModuleHandler and DSCI spec.monitoring" "Internal ODH"
        kserve = softwareSystem "KServe" "Inference workloads and ServiceMonitors" "Internal ODH"
        maas = softwareSystem "Models-as-a-Service" "Sends OTLP usage logs" "Internal ODH"
        mlflow = softwareSystem "MLflow" "Trace export target" "Internal ODH"
        dashboard = softwareSystem "odh-dashboard" "Observe dashboards; owns Perses ingress" "Internal ODH"

        k8s = softwareSystem "Kubernetes API" "Control plane" "External"
        coo = softwareSystem "Cluster Observability Operator" "MonitoringStack, ThanosQuerier, Perses" "External"
        tempoOp = softwareSystem "Tempo Operator" "TempoMonolithic / TempoStack" "External"
        otelOp = softwareSystem "OpenTelemetry Operator" "Collectors, Instrumentation, TargetAllocator" "External"
        lokiOp = softwareSystem "Loki Operator" "LokiStack" "External"
        clo = softwareSystem "Cluster Logging Operator" "ClusterLogForwarder" "External"
        certManager = softwareSystem "cert-manager" "Webhook and TargetAllocator certificates" "External"
        olm = softwareSystem "OLM" "OperatorConditions, ClusterExtensions" "External"
        objStore = softwareSystem "S3 / GCS" "Tempo and Loki storage backends" "External"
        remoteHub = softwareSystem "Remote OTLP Hub" "User-defined remote exporters" "External"

        admin -> platformOp "Configures DSCI spec.monitoring"
        admin -> odhObs "Creates Monitoring CR"
        platformOp -> odhObs "Installs Helm chart, manages Monitoring CR"
        tenant -> nsProxy "PromQL queries" "HTTPS/443 via reencrypt Route, Bearer token"
        dashboard -> nsProxy "Perses datasources" "HTTPS/8443"

        manager -> k8s "Watch, SSA, discovery, GC" "HTTPS/6443"
        k8s -> webhook "AdmissionReview" "HTTPS/9443"
        probe -> k8s "Creates canary PodMonitor" "HTTPS/6443"
        nsProxy -> k8s "TokenReview + SAR" "HTTPS/6443"
        korrel8r -> k8s "Caller-token queries" "HTTPS/6443"

        manager -> coo "Renders MonitoringStack, ThanosQuerier, Perses CRs"
        manager -> tempoOp "Renders TempoMonolithic/TempoStack"
        manager -> otelOp "Renders OpenTelemetryCollector, Instrumentation"
        manager -> lokiOp "Renders LokiStack"
        manager -> clo "Renders ClusterLogForwarder"
        manager -> olm "Prerequisite detection"
        odhObs -> certManager "Certificates for webhook and TargetAllocator"
        manager -> kserve "Reads InferenceServices" "HTTPS/6443"
        maas -> odhObs "OTLP usage logs" "gRPC/HTTP 4317/4318 TLS"
        odhObs -> mlflow "Collector trace export"
        odhObs -> objStore "Tempo/Loki storage (via operands)" "HTTPS/443"
        odhObs -> remoteHub "Remote export (via collectors)" "OTLP TLS"
    }

    views {
        systemContext odhObs "SystemContext" {
            include *
            autoLayout
        }

        container odhObs "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}

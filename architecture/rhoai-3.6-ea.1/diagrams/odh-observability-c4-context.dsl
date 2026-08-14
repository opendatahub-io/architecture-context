workspace {
    model {
        sre = person "SRE / Platform Admin" "Monitors RHOAI platform health and metrics"
        dataScientist = person "Data Scientist" "Runs ML workloads that produce metrics"

        odhObservability = softwareSystem "odh-observability" "Kubernetes operator that deploys and manages a unified observability stack for RHOAI: Prometheus monitoring, distributed tracing, and usage log collection" {
            manager = container "Manager" "controller-runtime operator process" "Go Operator" {
                reconciler = component "MonitoringReconciler" "Reconciles Monitoring CR, renders templates, applies manifests via SSA" "controller-runtime"
                deployer = component "Deployer" "Server-side apply deployment engine from odh-platform-utilities" "Go Library"
                webhookServer = component "Webhook Server" "Mutating admission webhook for PodMonitor/ServiceMonitor label injection" "Go HTTP/TLS"
            }
            clusterProxy = container "kube-rbac-proxy (cluster)" "Authenticated proxy for cluster-wide Prometheus metrics access" "kube-rbac-proxy" "Proxy"
            namespaceProxy = container "kube-rbac-proxy (namespace)" "Authenticated proxy for namespace-scoped Prometheus metrics access" "kube-rbac-proxy + prom-label-proxy" "Proxy"
            prometheus = container "Prometheus" "Metrics collection and storage for data science workloads" "Prometheus"
            collector = container "OpenTelemetry Collector" "Metrics processing and usage log forwarding" "OpenTelemetry"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Platform"
        serviceCA = softwareSystem "OpenShift service-ca" "Service certificate provisioning" "Platform"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus CRDs and instances" "Platform"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Shared Go library for platform detection, SSA deployment, and status management" "Internal RHOAI"
        lokiStack = softwareSystem "LokiStack" "Log aggregation and storage for usage logs" "Platform"
        dsWorkloads = softwareSystem "Data Science Workloads" "User ML workloads producing metrics" "External"

        # Relationships - Users
        sre -> odhObservability "Monitors platform via Prometheus Routes" "HTTPS"
        dataScientist -> dsWorkloads "Deploys ML models and pipelines"

        # Relationships - Operator
        odhObservability -> k8sAPI "Manages resources (CRUD, Watch, SSA)" "HTTPS/6443"
        odhObservability -> prometheusOperator "Creates Prometheus instances via CRDs" "Kubernetes API"
        odhObservability -> certManager "Obtains webhook TLS certificates" "Kubernetes API"
        odhObservability -> serviceCA "Obtains Prometheus TLS certificates" "Kubernetes API"

        # Relationships - Data Plane
        dsWorkloads -> prometheus "Scraped for metrics" "HTTP/9090"
        clusterProxy -> prometheus "Proxies metrics requests" "mTLS/9090"
        namespaceProxy -> prometheus "Proxies namespace-scoped metrics" "HTTPS/9090"
        clusterProxy -> k8sAPI "SubjectAccessReview auth delegation" "HTTPS/6443"
        namespaceProxy -> k8sAPI "SubjectAccessReview auth delegation" "HTTPS/6443"
        collector -> lokiStack "Forwards usage logs" "HTTPS"

        # Relationships - Internal
        reconciler -> deployer "Uses for manifest rendering and SSA"
        manager -> k8sAPI "Webhook admission requests" "HTTPS/9443"
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

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "Platform" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Proxy" {
                background #9b59b6
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}

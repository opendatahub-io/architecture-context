workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits Spark applications and interactive sessions"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator managing Apache Spark application lifecycle through CRDs" {
            controller = container "spark-operator-controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs into Kubernetes workloads" "Go Controller (Deployment)"
            webhook = container "spark-operator-webhook" "Validates and mutates SparkApplication CRs and Spark pods at admission time" "Go Webhook Server (Deployment)"
            moduleController = container "spark-operator-module-controller" "ODH/RHOAI module controller managing workload operator lifecycle via SparkOperator platform CR" "Go Controller (Deployment)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management and admission control" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform orchestrator managing component lifecycle" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for webhook TLS" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via PodMonitor scraping" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection and manifest rendering library" "Internal Platform"

        sparkDriver = softwareSystem "Spark Driver Pod" "Executes Spark application driver logic" "Workload"
        sparkExecutors = softwareSystem "Spark Executor Pods" "Execute distributed Spark tasks" "Workload"
        sparkConnect = softwareSystem "Spark Connect Server" "Persistent gRPC server for interactive Spark sessions" "Workload"

        # Relationships
        user -> sparkOperator "Creates SparkApplication / ScheduledSparkApplication / SparkConnect CRs via kubectl" "HTTPS/6443"
        odhOperator -> sparkOperator "Creates SparkOperator platform CR to manage component lifecycle" "Kubernetes API"

        controller -> k8sAPI "Watches CRDs, creates/manages pods, services, configmaps, PDBs, ingresses" "HTTPS/6443"
        controller -> sparkDriver "Creates driver pods for SparkApplication CRs" "Kubernetes API"
        controller -> sparkConnect "Creates Spark Connect server pods" "Kubernetes API"

        webhook -> k8sAPI "Reads webhook configurations, resource quotas, pods" "HTTPS/6443"
        webhook -> openShiftAPI "Reads TLS security profile for cipher suite configuration" "HTTPS/6443"

        moduleController -> k8sAPI "Manages Deployments, CRDs, RBAC, Webhooks, NetworkPolicies for workload operator" "HTTPS/6443"
        moduleController -> odhPlatformUtils "Platform detection and condition management" "Go library"

        sparkDriver -> sparkExecutors "Spark RPC for task distribution" "TCP/7078, TCP/7079"

        sparkOperator -> certManager "Creates Certificate and Issuer CRs for webhook TLS (optional)" "Kubernetes API"
        sparkOperator -> prometheusOperator "Creates PodMonitor for metrics scraping" "Kubernetes API"

        k8sAPI -> webhook "Sends admission reviews for Spark pods and CRs" "HTTPS/443→9443"
    }

    views {
        systemContext sparkOperator "SystemContext" {
            include *
            autoLayout
        }

        container sparkOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Workload" {
                background #f5a623
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

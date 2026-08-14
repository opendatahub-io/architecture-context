workspace {
    model {
        user = person "Data Engineer" "Submits and manages Apache Spark workloads on OpenShift"

        sparkOperator = softwareSystem "Spark Operator" "Manages Apache Spark application lifecycle on Kubernetes/OpenShift via CRDs" {
            controller = container "spark-operator-controller" "Reconciles SparkApplication, ScheduledSparkApplication, SparkConnect CRs; creates driver/executor Pods, Services, ConfigMaps, PDBs" "Go Operator"
            webhook = container "spark-operator-webhook" "Validates, defaults, and mutates Spark resources and Pods via 7 admission endpoints" "Go Webhook Server"
            module = container "spark-operator-module" "RHOAI platform integration; reconciles SparkOperator CR to deploy entire operator stack" "Go Controller-Runtime Operator"
            webhookService = container "spark-operator-webhook-svc" "ClusterIP service exposing webhook on 443/TCP" "Kubernetes Service"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Central API server for all cluster operations" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via PodMonitor CRDs" "Internal Platform"
        odhOperator = softwareSystem "ODH Operator" "Manages RHOAI platform components" "Internal Platform"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, deployment helpers" "Internal Platform"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS profile configuration" "External"

        # User interactions
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"

        # Internal container relationships
        controller -> kubeAPI "Watches CRs, creates Pods/Services/ConfigMaps/PDBs" "HTTPS/6443, TLS 1.2+"
        webhook -> kubeAPI "Reads SparkApplications, ResourceQuotas, manages webhook certs" "HTTPS/6443, TLS 1.2+"
        module -> kubeAPI "Deploys operator stack: Deployments, CRDs, RBAC, webhooks, NetworkPolicies" "HTTPS/6443, TLS 1.2+"
        kubeAPI -> webhookService "Sends admission requests" "HTTPS/443, TLS"
        webhookService -> webhook "Routes to webhook pods"

        # Platform relationships
        odhOperator -> sparkOperator "Creates SparkOperator CR to trigger deployment" "Kubernetes API"
        module -> certManager "Creates Certificate and Issuer CRs for webhook TLS" "CRD CRUD"
        module -> prometheusOperator "Creates PodMonitor CRs for monitoring" "CRD CRUD"
        module -> odhPlatformUtils "Uses for platform detection and manifest rendering" "Go Library"
        controller -> openShiftAPI "Reads TLS profile at startup for cipher suite alignment" "HTTPS"
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
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

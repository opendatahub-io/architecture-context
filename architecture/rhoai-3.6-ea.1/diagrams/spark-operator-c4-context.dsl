workspace {
    model {
        user = person "Data Scientist" "Creates and manages Apache Spark workloads on OpenShift"
        clusterAdmin = person "Cluster Administrator" "Manages RHOAI platform components"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator managing Apache Spark workloads via CRDs (SparkApplication, ScheduledSparkApplication, SparkConnect)" {
            controller = container "Controller Deployment" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRs; creates driver/executor pods, services, ingress, PDBs" "Go Operator (controller-runtime)" "spark-operator-controller"
            webhook = container "Webhook Deployment" "Validates and mutates Spark workload submissions; 7 admission webhooks with failurePolicy: Fail" "Go Webhook Server" "spark-operator-webhook"
            module = container "Spark Operator Module" "Meta-operator that manages controller and webhook lifecycle; implements PlatformObject interface for ODH integration" "Go Operator (controller-runtime)" "spark-operator-module"
        }

        odhOperator = softwareSystem "ODH Operator" "Manages RHOAI platform component lifecycle" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Manages TLS certificate lifecycle via CRDs" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages monitoring resources via PodMonitor CRDs" "External"
        openshiftAPIServer = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS profile configuration" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource operations" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Go library for platform detection, manifest rendering, deployment helpers" "Internal RHOAI"

        # User interactions
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"
        clusterAdmin -> odhOperator "Manages RHOAI platform"

        # Internal relationships
        module -> controller "Deploys and manages lifecycle"
        module -> webhook "Deploys and manages lifecycle"
        controller -> webhook "CRs validated/mutated before reconciliation"

        # External dependencies
        odhOperator -> sparkOperator "Creates SparkOperator CR, reads status via PlatformObject" "Kubernetes API"
        sparkOperator -> kubernetesAPI "CRUD operations on Pods, Services, Ingress, PDBs, ConfigMaps" "HTTPS/6443"
        sparkOperator -> certManager "Creates Certificate and Issuer CRs for webhook TLS" "Kubernetes API"
        sparkOperator -> prometheusOperator "Creates PodMonitor CRs for monitoring" "Kubernetes API"
        webhook -> openshiftAPIServer "Reads cluster TLS profile at startup" "HTTPS/6443"
        sparkOperator -> odhPlatformUtils "Platform detection, manifest rendering" "Go library"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

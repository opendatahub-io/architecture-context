workspace {
    model {
        dataScientist = person "Data Scientist" "Submits Spark applications and uses SparkConnect for interactive analytics"
        ciSystem = person "CI System" "Automates Spark job submissions"

        sparkOperator = softwareSystem "Spark Operator" "Manages Apache Spark application lifecycles on Kubernetes" {
            controller = container "spark-operator controller" "Reconciles SparkApplication, ScheduledSparkApplication, SparkConnect CRs; manages driver/executor pods" "Go Controller"
            webhook = container "spark-operator webhook" "Validates and mutates Spark CRs and pods via admission webhooks; self-provisions TLS" "Go Webhook Server" {
                tags "Webhook"
            }
            moduleController = container "spark-operator-module controller" "ODH platform module managing workload operator lifecycle via SparkOperator CR" "Go Controller" {
                tags "Module"
            }
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Central API for cluster resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Internal Platform"
        prometheusOperator = softwareSystem "prometheus-operator" "Prometheus monitoring stack management" "Internal Platform"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Platform operator managing ODH component modules" "Internal Platform"
        volcano = softwareSystem "Volcano" "Batch scheduler for Kubernetes" "External Optional"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Extended scheduling capabilities" "External Optional"
        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Platform detection and manifest rendering library" "Internal Platform"

        # Relationships - Users
        dataScientist -> sparkOperator "Submits SparkApplication/ScheduledSparkApplication/SparkConnect CRs" "kubectl / HTTPS"
        ciSystem -> sparkOperator "Automates Spark job submissions" "kubectl / HTTPS"

        # Relationships - Internal
        controller -> kubernetesAPI "Watches CRs, manages pods, services, PDBs" "HTTPS/6443"
        webhook -> kubernetesAPI "Reads resource quotas, updates webhook configs" "HTTPS/6443"
        moduleController -> kubernetesAPI "Manages CRDs, RBAC, Deployments, webhooks" "HTTPS/6443"
        moduleController -> certManager "Manages Certificate and Issuer CRs" "Kubernetes API"
        moduleController -> prometheusOperator "Manages PodMonitor CRs" "Kubernetes API"
        controller -> webhook "Admission reviews for CR validation" "HTTPS/9443"

        # Relationships - Platform
        odhOperator -> sparkOperator "Creates SparkOperator CR to manage lifecycle" "Kubernetes API"
        moduleController -> odhPlatformUtilities "Platform detection, manifest rendering" "Go library"

        # Relationships - Optional
        controller -> volcano "Optional batch scheduling integration" "Kubernetes API"
        controller -> schedulerPlugins "Optional gang scheduling" "Kubernetes API"
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
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Optional" {
                background #cccccc
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Webhook" {
                background #4a90e2
            }
            element "Module" {
                background #6c5ce7
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits Spark applications for data processing and ML workloads"
        platformAdmin = person "Platform Admin" "Manages SparkOperator CR for ODH/RHOAI platform integration"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator managing Apache Spark application lifecycle on OpenShift" {
            controller = container "SparkApplication Controller" "Reconciles SparkApplication lifecycle including driver pods, executor pods, services, and ingress" "Go Controller"
            scheduledController = container "ScheduledSparkApplication Controller" "Manages cron-triggered SparkApplication creation" "Go Controller"
            sparkConnectController = container "SparkConnect Controller" "Reconciles SparkConnect resources for interactive Spark sessions" "Go Controller"
            moduleController = container "SparkOperator Module Controller" "Reconciles SparkOperator CR for ODH platform module lifecycle" "Go Controller"
            webhookServer = container "Webhook Server" "Validates and mutates SparkApplication, ScheduledSparkApplication, SparkConnect CRs, and Spark pods" "Go Admission Webhook"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and admission" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "Platform Dependency"
        prometheusOperator = softwareSystem "prometheus-operator" "Kubernetes-native monitoring with Prometheus" "Platform Dependency"
        openshiftConfig = softwareSystem "OpenShift Cluster Configuration" "Cluster-wide API server and TLS profile settings" "Platform Dependency"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, and deployment helpers" "Internal ODH"

        dataScientist -> sparkOperator "Submits SparkApplication / ScheduledSparkApplication / SparkConnect via kubectl"
        platformAdmin -> sparkOperator "Manages SparkOperator CR for platform integration"

        sparkOperator -> kubernetesAPI "Manages pods, services, configmaps, RBAC, ingresses, PDBs" "HTTPS/6443 TLS 1.2+"
        sparkOperator -> certManager "Creates Certificate and Issuer CRs for webhook TLS" "Kubernetes API"
        sparkOperator -> prometheusOperator "Creates PodMonitor CRs for metrics collection" "Kubernetes API"
        sparkOperator -> openshiftConfig "Reads APIServer TLS profile configuration" "Kubernetes API"

        controller -> kubernetesAPI "Creates driver pods, executor pods, services, configmaps" "HTTPS/6443"
        scheduledController -> kubernetesAPI "Creates SparkApplication CRs on cron schedule" "HTTPS/6443"
        sparkConnectController -> kubernetesAPI "Manages SparkConnect session resources" "HTTPS/6443"
        moduleController -> kubernetesAPI "Manages operator deployments, RBAC, CRDs, webhooks" "HTTPS/6443"
        webhookServer -> kubernetesAPI "Reads ResourceQuotas, manages webhook configs" "HTTPS/6443"

        moduleController -> certManager "Certificate lifecycle management" "CRD CRUD"
        moduleController -> prometheusOperator "PodMonitor lifecycle management" "CRD CRUD"
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
            element "Platform Dependency" {
                background #775791
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

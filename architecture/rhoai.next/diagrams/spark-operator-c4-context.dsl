workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Apache Spark applications on OpenShift/Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Automates lifecycle of Apache Spark applications, scheduled jobs, and Spark Connect servers on OpenShift/Kubernetes" {
            controller = container "Spark Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages 17-state lifecycle state machine" "Go Operator (controller-runtime)"
            webhook = container "Spark Webhook" "Mutating/validating admission webhooks for Spark CRDs and pods; manages TLS certificates" "Go Webhook Server"
            moduleController = container "Spark Operator Module" "ODH platform module controller managing spark-operator component lifecycle" "Go Operator (controller-runtime)"
        }

        kubeAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRDs" "External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Batch scheduling via task group annotations" "External"
        rhodsOperator = softwareSystem "RHODS / ODH Operator" "Platform operator that deploys spark-operator via kustomize overlays" "Internal RHOAI"
        restSubmitter = softwareSystem "REST Submitter Service" "Remote spark-submit execution service" "External"

        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"
        sparkOperator -> kubeAPI "CRD reconciliation, pod CRUD, status updates, event emission" "HTTPS/443"
        kubeAPI -> sparkOperator "Admission webhook requests" "HTTPS/443 -> 9443"
        sparkOperator -> prometheus "Exposes operator metrics (spark_app_*, spark_executor_*)" "HTTP/8080"
        sparkOperator -> certManager "Optional: delegates webhook TLS certificate management" "Certificate CRD"
        sparkOperator -> volcano "Optional: creates PodGroup for gang scheduling" "PodGroup CRD"
        sparkOperator -> yunikorn "Optional: annotates pods for task group scheduling" "Pod annotations"
        sparkOperator -> restSubmitter "Optional: remote spark-submit via REST API (mTLS)" "HTTP/HTTPS"
        rhodsOperator -> sparkOperator "Deploys and manages operator lifecycle" "Kustomize overlays"

        controller -> kubeAPI "Creates driver/executor pods, services, ingresses, PDBs" "HTTPS/443"
        webhook -> kubeAPI "Validates ResourceQuotas, reads OpenShift TLS profile" "HTTPS/443"
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
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
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

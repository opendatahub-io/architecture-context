workspace {
    model {
        user = person "Data Scientist" "Submits and manages Spark applications on OpenShift/Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates submission, scheduling, monitoring, and lifecycle management of Apache Spark applications" {
            controller = container "Spark Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRs; manages driver/executor pod lifecycle, Services, Ingress, and monitoring ConfigMaps" "Go Operator (controller-runtime)"
            webhook = container "Spark Webhook" "Mutates Spark pods with volumes, env vars, scheduling config; validates SparkApplication specs; enforces resource quotas; manages webhook certificate lifecycle" "Go Admission Webhook"
            schedulerRegistry = container "Batch Scheduler Registry" "Pluggable scheduler integration supporting Volcano, YuniKorn, and kube-scheduler plugins" "Go Plugin System"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "OpenShift platform configuration API (config.openshift.io)" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys spark-operator via kustomize overlay; substitutes image refs via ApplyParams" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate lifecycle management for webhook" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional batch scheduler for gang scheduling via PodGroup CRDs" "External"
        yunikorn = softwareSystem "YuniKorn Scheduler" "Optional kube-scheduler plugin framework for task group scheduling" "External"
        kueue = softwareSystem "Kueue" "Workload admission via pod labels" "External"
        ingressController = softwareSystem "Ingress Controller" "nginx/OpenShift Router for Spark Web UI exposure" "External"

        # Relationships
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"
        user -> sparkOperator "Connects to SparkConnect servers" "gRPC/15002"

        controller -> k8sAPI "CRUD for pods, services, ingresses, configmaps, CRDs; webhook registration; leader election" "HTTPS/443"
        controller -> openshiftAPI "Reads cluster TLS security profile for webhook cipher suite configuration" "HTTPS/443"
        controller -> schedulerRegistry "Uses pluggable scheduler for gang scheduling"

        webhook -> k8sAPI "Reads pods, configmaps; updates webhook configurations" "HTTPS/443"
        k8sAPI -> webhook "Sends admission requests for pods, SparkApplications, ScheduledSparkApplications" "HTTPS/9443"

        rhodsOperator -> sparkOperator "Deploys via config/overlays/rhoai kustomize"
        prometheus -> sparkOperator "Scrapes operator metrics (application counts, latency, executor states)" "HTTP/8080"
        certManager -> sparkOperator "Manages TLS certificates for webhook endpoint"
        controller -> volcano "Creates/deletes PodGroup CRs for gang scheduling" "HTTPS/443"
        sparkOperator -> ingressController "Creates Ingress resources for Spark Web UI" "HTTP/80, HTTPS/443"
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

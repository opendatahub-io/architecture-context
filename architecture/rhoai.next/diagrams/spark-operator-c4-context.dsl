workspace {
    model {
        user = person "Data Scientist" "Creates and submits Spark applications, scheduled jobs, and Spark Connect servers"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates lifecycle management of Apache Spark applications, scheduled jobs, and Spark Connect servers on OpenShift/Kubernetes" {
            controller = container "Spark Operator Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages Spark driver/executor pod lifecycle, services, ingresses, and monitoring" "Go Operator (controller-runtime)"
            webhook = container "Spark Operator Webhook" "Validates and defaults SparkApplication/ScheduledSparkApplication CRs; mutates Spark pods to inject 25+ operator-managed configurations" "Go Admission Webhook Server"
            certProvider = container "Certificate Provider" "Generates and rotates self-signed TLS certificates for webhook server; optional cert-manager integration" "Go Library"
            batchScheduler = container "Batch Scheduler Registry" "Extensible factory-pattern registry for Volcano, Yunikorn, and kube-scheduler plugin integration" "Go Library"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core API server for cluster resource management" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection via PodMonitor" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduling system using PodGroup CRDs" "External Optional"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Resource scheduler with task-group annotation-based scheduling" "External Optional"
        kubeSchedulerPlugins = softwareSystem "kube-scheduler Plugins" "Scheduler plugins for coarse-grained PodGroup scheduling" "External Optional"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for Kubernetes" "External Optional"
        rhodsOperator = softwareSystem "RHOAI Operator" "Platform operator that deploys Spark Operator via kustomize overlays" "Internal Platform"

        # User interactions
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"

        # Internal container interactions
        controller -> webhook "Shares container image, independent deployment"
        certProvider -> webhook "Provides TLS certificates" "TLS"
        batchScheduler -> controller "Provides scheduler integration"

        # External interactions
        controller -> k8sAPI "CRUD on pods, services, configmaps, ingresses, CRDs, events" "HTTPS/6443"
        webhook -> k8sAPI "Admission webhook callbacks, CR lookups" "HTTPS/6443 + HTTPS/9443"
        controller -> volcano "Creates/deletes Volcano PodGroups for batch scheduling" "HTTPS/6443 (via K8s API)"
        controller -> kubeSchedulerPlugins "Creates/deletes scheduler-plugins PodGroups" "HTTPS/6443 (via K8s API)"
        controller -> yunikorn "Sets task-group annotations on driver/executor pods" "N/A (annotation injection)"
        webhook -> certManager "Optional: certificate issuance and rotation" "HTTPS/6443 (via K8s API)"
        prometheus -> controller "Scrapes operator metrics" "HTTP/8080"
        prometheus -> webhook "Scrapes webhook metrics" "HTTP/8080"
        rhodsOperator -> sparkOperator "Deploys via kustomize overlays" "Kustomize"
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
                background #BBBBBB
                color #ffffff
            }
            element "Internal Platform" {
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

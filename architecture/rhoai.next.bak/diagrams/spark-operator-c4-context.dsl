workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications, scheduled jobs, and SparkConnect sessions"
        sre = person "SRE / Platform Admin" "Monitors operator health and Spark workload metrics"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates lifecycle management of Apache Spark applications, scheduled jobs, and Spark Connect servers" {
            controller = container "spark-operator-controller" "Watches SparkApplication, ScheduledSparkApplication, and SparkConnect CRs; manages Spark driver/executor pods via spark-submit; creates Services and Ingresses for Spark UI; handles retries, TTL, and cleanup" "Go Operator (controller-runtime)"
            webhook = container "spark-operator-webhook" "Admission webhooks that mutate Spark pods (inject config, volumes, env vars, sidecars, GPU, monitoring), validate SparkApplications, and manage self-signed TLS certificates" "Go Webhook Server (controller-runtime)"
            certProvider = container "Certificate Provider" "Self-signed CA generation, Secret synchronization, and cert rotation for webhook TLS" "Go Library (pkg/certificate)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource CRUD, admission webhooks, and authentication" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster-wide TLS security profile configuration" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via PodMonitor" "Internal Platform"
        volcano = softwareSystem "Volcano Scheduler" "Optional batch scheduler for gang scheduling via PodGroup CRs" "External Optional"
        yuniKorn = softwareSystem "YuniKorn Scheduler" "Optional scheduler with task-group annotation injection" "External Optional"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Optional gang scheduling via scheduling.k8s.io PodGroup CRs" "External Optional"
        kueue = softwareSystem "Kueue" "Workload queueing integration via label conventions" "External Optional"
        certManager = softwareSystem "cert-manager" "Optional external TLS certificate management" "External Optional"
        rhodsOperator = softwareSystem "RHOAI / ODH Operator" "Platform operator that deploys spark-operator via kustomize overlays" "Internal Platform"
        workbench = softwareSystem "ODH/RHOAI Workbench" "Interactive notebook environment for data scientists" "Internal Platform"

        # User interactions
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl" "HTTPS/443"
        user -> sparkOperator "Views Spark UI" "HTTP/4040"
        sre -> prometheus "Reviews Spark application and executor metrics"

        # Workbench interactions
        workbench -> sparkOperator "Connects to SparkConnect server for interactive Spark sessions" "gRPC/15002"

        # Internal container interactions
        controller -> webhook "Pod admission review during driver/executor creation" "HTTPS/9443"
        webhook -> certProvider "Manages TLS certificate lifecycle"

        # External dependencies
        sparkOperator -> k8sAPI "Watches CRDs, creates/updates pods, services, configmaps, ingresses, webhook configurations" "HTTPS/443"
        sparkOperator -> openShiftAPI "Reads cluster TLS security profile (config.openshift.io/v1 APIServer)" "HTTPS/443"
        sparkOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        sparkOperator -> yuniKorn "Injects task-group annotations on driver/executor pods"
        sparkOperator -> schedulerPlugins "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        sparkOperator -> kueue "Applies kueue.x-k8s.io/ labels for workload queueing"
        sparkOperator -> certManager "Optional: delegates webhook TLS certificate management" "HTTPS/443"

        # Platform dependencies
        rhodsOperator -> sparkOperator "Deploys via kustomize overlays, injects image references"
        prometheus -> sparkOperator "Scrapes spark_application_* and spark_executor_* metrics" "HTTP/8080"
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
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

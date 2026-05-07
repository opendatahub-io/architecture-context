workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications on OpenShift"
        sparkConnectClient = person "SparkConnect Client" "Connects to SparkConnect server for interactive queries"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator for managing Apache Spark applications, scheduled jobs, and Spark Connect sessions" {
            controller = container "Spark Operator Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages driver/executor pods, services, ingresses, and monitoring ConfigMaps" "Go Operator (controller-runtime)" {
                sparkAppReconciler = component "SparkApplication Reconciler" "16-state state machine for Spark app lifecycle" "controller-runtime"
                scheduledSparkReconciler = component "ScheduledSparkApp Reconciler" "Cron-based SparkApplication creation with concurrency policy" "controller-runtime"
                sparkConnectReconciler = component "SparkConnect Reconciler" "Manages SparkConnect server pods and services" "controller-runtime"
                sparkSubmit = component "spark-submit" "In-process Spark submission with full Spark distribution" "PySpark 4.0.1"
                schedulerRegistry = component "Scheduler Registry" "Pluggable batch scheduler integration" "Go Library"
                certProvider = component "Certificate Provider" "Self-signed TLS cert generation and management" "Go Library"
            }

            webhook = container "Spark Operator Webhook" "Mutates and validates SparkApplication and ScheduledSparkApplication CRs; mutates Spark pods with 26-step pipeline (env, volumes, scheduling, monitoring)" "Go Webhook Server (controller-runtime)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration platform API" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        certManager = softwareSystem "cert-manager" "Optional external TLS certificate management" "External"
        volcano = softwareSystem "Volcano" "Optional batch scheduler for gang scheduling via PodGroups" "External"
        yunikorn = softwareSystem "Apache YuniKorn" "Optional batch scheduler with annotation-based task groups" "External"
        kubeSchedulerPlugins = softwareSystem "Kube-Scheduler Plugins" "Optional scheduler framework for batch scheduling" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Spark Operator via kustomize overlays" "Internal RHOAI"

        sparkDriver = softwareSystem "Spark Driver Pod" "Executes Spark application main class, coordinates executors" "Managed"
        sparkExecutors = softwareSystem "Spark Executor Pods" "Execute Spark tasks, communicate with driver" "Managed"
        sparkConnectServer = softwareSystem "SparkConnect Server" "Persistent Spark Connect server for interactive queries" "Managed"

        # User interactions
        user -> sparkOperator "Creates SparkApplication / ScheduledSparkApplication / SparkConnect CRs via kubectl" "HTTPS/443"
        sparkConnectClient -> sparkConnectServer "Connects for interactive query execution" "gRPC/15002"

        # Operator internal flows
        controller -> k8sAPI "CRD reconciliation, pod/service/configmap/ingress CRUD, leader election" "HTTPS/443, SA token"
        controller -> sparkDriver "Creates via spark-submit" "Kubernetes API"
        webhook -> k8sAPI "Updates webhook configurations" "HTTPS/443, SA token"
        k8sAPI -> webhook "Admission reviews (mutate + validate)" "HTTPS/9443, TLS"

        # Managed workloads
        sparkDriver -> k8sAPI "Creates executor pods" "HTTPS/443, SA token"
        sparkDriver -> sparkExecutors "Coordinates task execution" "TCP/7078, 7079"

        # External integrations
        sparkOperator -> volcano "Creates PodGroup CRDs for gang scheduling" "Kubernetes API"
        sparkOperator -> yunikorn "Adds task group annotations" "Pod annotations"
        sparkOperator -> kubeSchedulerPlugins "Creates PodGroup for batch scheduling" "Kubernetes API"
        sparkOperator -> certManager "Optional TLS certificate management" "Certificate CRD"
        prometheus -> sparkOperator "Scrapes operator metrics" "HTTP/8080"
        prometheus -> sparkDriver "Scrapes JMX metrics from sidecars" "HTTP/8090"
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

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #9b59b6
                color #ffffff
            }
            element "Managed" {
                background #7ed321
                color #000000
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

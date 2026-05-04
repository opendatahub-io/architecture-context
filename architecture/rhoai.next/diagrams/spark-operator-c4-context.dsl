workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications on Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates lifecycle management of Apache Spark applications, scheduled jobs, and Spark Connect servers" {
            controller = container "spark-operator controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages Spark driver/executor pod lifecycle, services, ingresses, and monitoring" "Go Operator (controller-runtime)"
            webhook = container "spark-operator webhook" "Validates and defaults SparkApplication/ScheduledSparkApplication CRs; mutates Spark pods to inject operator-managed configuration (25+ mutations)" "Go Admission Webhook Server"
            certProvider = container "Certificate Provider" "Generates and rotates self-signed TLS certificates for webhook server" "Go Library"
            schedulerRegistry = container "Batch Scheduler Registry" "Extensible factory-pattern registry for Volcano, Yunikorn, and kube-scheduler plugin integration" "Go Library"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes API for all cluster interactions" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys spark-operator via kustomize overlays" "Internal Platform"

        volcano = softwareSystem "Volcano Scheduler" "Batch scheduling system for Kubernetes with PodGroup support" "External Optional"
        kubeSchedulerPlugins = softwareSystem "kube-scheduler plugins" "Scheduler plugins with PodGroup API for coarse-grained scheduling" "External Optional"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Apache Yunikorn unified scheduler with annotation-based task groups" "External Optional"
        certManager = softwareSystem "cert-manager" "Certificate management for Kubernetes (optional, alternative to internal cert generation)" "External Optional"

        sparkDriver = softwareSystem "Spark Driver Pod" "Runs Spark driver process, manages executor lifecycle" "Managed Workload"
        sparkExecutors = softwareSystem "Spark Executor Pods" "Run Spark tasks, communicate with driver via RPC" "Managed Workload"

        # Relationships
        user -> sparkOperator "Creates SparkApplication/ScheduledSparkApplication/SparkConnect CRs via kubectl" "HTTPS/6443"
        rhodsOperator -> sparkOperator "Deploys via kustomize overlays" "Kustomize"

        controller -> k8sAPI "CRUD on pods, services, configmaps, ingresses, CRDs, events" "HTTPS/6443"
        controller -> sparkDriver "Creates via spark-submit, monitors lifecycle" "Process exec + K8s API"
        controller -> schedulerRegistry "Creates PodGroups for batch scheduling" "Internal"

        webhook -> k8sAPI "Receives admission webhook callbacks" "HTTPS/9443"
        webhook -> certProvider "Obtains TLS certificates" "Internal"

        k8sAPI -> webhook "Admission webhook requests (validate, default, mutate)" "HTTPS/9443"

        sparkDriver -> sparkExecutors "Spark RPC and Block Manager" "HTTP/7078, 7079"
        sparkDriver -> k8sAPI "Request executor pods, report status" "HTTPS/6443"

        prometheus -> sparkOperator "Scrapes /metrics endpoint via PodMonitor" "HTTP/8080"

        controller -> volcano "Creates/deletes Volcano PodGroup CRs" "HTTPS/6443 via K8s API"
        controller -> kubeSchedulerPlugins "Creates/deletes scheduler-plugins PodGroups" "HTTPS/6443 via K8s API"
        controller -> yunikorn "Injects task-group annotations on pods" "Pod annotations"

        sparkOperator -> certManager "Optionally delegates certificate issuance" "HTTPS/6443 via K8s API"
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
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape Person
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

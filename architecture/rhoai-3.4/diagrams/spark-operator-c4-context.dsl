workspace {
    model {
        user = person "Data Scientist / Engineer" "Submits and manages Apache Spark applications on Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates Apache Spark application lifecycle — submission, monitoring, scheduling, and cleanup" {
            controller = container "spark-operator-controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages driver/executor pod lifecycle via state machine (13+ states)" "Go Operator (controller-runtime v0.20.4)"
            webhook = container "spark-operator-webhook" "Validates and mutates SparkApplication, ScheduledSparkApplication, and Pod resources; 24-step mutation pipeline for Spark pod configuration" "Go Webhook Server (9443/TCP HTTPS)"
            pysparkRuntime = container "PySpark 4.0.1 Runtime" "Apache Spark runtime bundled in operator image for spark-submit execution" "Java 17 + Python"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting platform" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate lifecycle management" "External"
        volcano = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRDs for co-scheduling" "External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Gang scheduling via pod annotations" "External"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys component manifests" "Internal RHOAI"

        # Relationships
        user -> sparkOperator "Creates SparkApplication / ScheduledSparkApplication CRs via kubectl" "HTTPS/443"
        sparkOperator -> k8sAPI "CRUD for Pods, Services, ConfigMaps, Ingresses, CRDs, Events" "HTTPS/443, TLS 1.2+, ServiceAccount token"
        sparkOperator -> volcano "Creates PodGroup CRDs for gang scheduling" "CRD-based (no network)"
        sparkOperator -> yunikorn "Annotates pods with task group definitions" "Annotation-based (no network)"
        sparkOperator -> certManager "Delegates TLS certificate management for webhook" "CRD-based (no network)"
        prometheus -> sparkOperator "Scrapes operator metrics (spark_application_count, submit_count, running_count)" "HTTP/8080"
        rhodsOperator -> sparkOperator "Deploys spark-operator manifests via ApplyParams with image substitution" "Kustomize"

        # Internal container relationships
        controller -> k8sAPI "CRD reconciliation, pod/service CRUD, leader election" "HTTPS/443"
        webhook -> k8sAPI "Webhook configuration updates" "HTTPS/443"
        k8sAPI -> webhook "Admission review requests" "HTTPS/9443"
        controller -> pysparkRuntime "Invokes spark-submit for SparkApplication jobs" "In-process"
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
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

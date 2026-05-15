workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits and manages Apache Spark applications on Kubernetes"
        ciPipeline = person "CI Pipeline" "Automated submission of scheduled Spark jobs"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that manages Apache Spark application lifecycle, scheduled jobs, and Spark Connect sessions" {
            controller = container "Controller" "Reconciles SparkApplication, ScheduledSparkApplication, SparkConnect CRDs; manages Spark driver/executor pod lifecycle via spark-submit" "Go Operator (controller-runtime)" {
                sparkAppController = component "SparkApplication Controller" "Submits Spark jobs, monitors driver/executor pods, manages Web UI services/ingresses, handles restart policies" "Controller"
                schedController = component "ScheduledSparkApplication Controller" "Creates SparkApplication instances on cron schedules with concurrency policy enforcement" "Controller"
                connectController = component "SparkConnect Controller" "Manages persistent Spark Connect server pods and services for interactive Spark sessions" "Controller"
                mutWhConfigCtrl = component "MutatingWebhookConfig Controller" "Maintains CA bundle in MutatingWebhookConfiguration for certificate rotation" "Controller"
                valWhConfigCtrl = component "ValidatingWebhookConfig Controller" "Maintains CA bundle in ValidatingWebhookConfiguration for certificate rotation" "Controller"
                sparkSubmit = component "spark-submit" "Local binary execution for Spark application submission (bundled PySpark 4.0.1, Java 17)" "Process"
            }

            webhook = container "Webhook Server" "Validates and mutates SparkApplication resources and Spark pods at admission time; manages self-signed TLS certificates" "Go Webhook Server (controller-runtime)" {
                mutSparkApp = component "SparkApplication Mutator" "Sets default values on SparkApplication resources" "Mutating Webhook"
                valSparkApp = component "SparkApplication Validator" "Validates DNS names, NodeSelector, DriverIngress, Spark version, ResourceQuota" "Validating Webhook"
                mutSchedApp = component "ScheduledSparkApplication Mutator" "Sets default values on ScheduledSparkApplication resources" "Mutating Webhook"
                valSchedApp = component "ScheduledSparkApplication Validator" "Validates DNS-1035 label compliance" "Validating Webhook"
                podMutator = component "Pod Mutator" "Injects volumes, env vars, sidecars, scheduling annotations, Prometheus config into Spark pods" "Mutating Webhook"
                certManager = component "Certificate Manager" "Generates and rotates self-signed RSA 2048-bit TLS certificates" "Internal"
            }
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRUD operations on all Kubernetes resources" "External"
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduler for gang scheduling via PodGroup CRD" "External Optional"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Batch scheduler for gang scheduling via pod annotations" "External Optional"
        schedulerPlugins = softwareSystem "scheduler-plugins" "kube-scheduler integration for PodGroup-based scheduling" "External Optional"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor for operator and Spark pod metrics" "External"
        certManagerExt = softwareSystem "cert-manager" "Optional external TLS certificate management" "External Optional"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Spark Operator via kustomize overlays" "Internal RHOAI"

        # Relationships - Users
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs via kubectl"
        ciPipeline -> sparkOperator "Submits automated Spark jobs"

        # Relationships - Operator to external
        sparkOperator -> k8sApi "Manages pods, services, ingresses, configmaps, secrets, webhook configs, CRDs" "HTTPS/443"
        sparkOperator -> volcano "Creates PodGroup CRDs for gang scheduling" "HTTPS/443"
        sparkOperator -> yunikorn "Adds gang scheduling annotations to driver/executor pods"
        sparkOperator -> schedulerPlugins "Creates PodGroup CRDs for kube-scheduler integration" "HTTPS/443"
        sparkOperator -> certManagerExt "Optional: external TLS certificate provisioning" "HTTPS/443"

        # Relationships - External to operator
        prometheus -> sparkOperator "Scrapes operator metrics" "HTTP/8080"
        rhodsOperator -> sparkOperator "Deploys via kustomize overlays, substitutes image references"
        k8sApi -> sparkOperator "Sends admission webhook requests" "HTTPS/9443"

        # Container-level relationships
        controller -> k8sApi "CRUD operations for pods, services, ingresses" "HTTPS/443 TLS 1.2+"
        webhook -> k8sApi "Reads SparkApplications, ResourceQuotas" "HTTPS/443 TLS 1.2+"
        k8sApi -> webhook "Admission requests" "HTTPS/9443 TLS (self-signed)"
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

        component webhook "WebhookComponents" {
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
                border dashed
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
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}

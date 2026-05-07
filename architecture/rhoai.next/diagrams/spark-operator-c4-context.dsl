workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications on Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates lifecycle management of Apache Spark applications, scheduled jobs, and Spark Connect servers" {
            controller = container "Spark Operator Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages Spark driver/executor pod lifecycle, services, ingresses, and monitoring" "Go Operator (controller-runtime)" {
                saController = component "SparkApplication Controller" "13+ state machine for Spark job lifecycle: submission, retries, suspension, TTL cleanup" "Go Controller"
                ssaController = component "ScheduledSparkApplication Controller" "Cron-based scheduling with concurrency policies and history management" "Go Controller"
                scController = component "SparkConnect Controller" "Manages persistent Spark Connect server pods and services" "Go Controller"
                mwhController = component "MutatingWebhookConfig Controller" "Synchronizes CA bundle in MutatingWebhookConfiguration" "Go Controller"
                vwhController = component "ValidatingWebhookConfig Controller" "Synchronizes CA bundle in ValidatingWebhookConfiguration" "Go Controller"
                certProvider = component "Certificate Provider" "Generates/rotates self-signed TLS certs or integrates with cert-manager" "Go Library"
                schedulerRegistry = component "Batch Scheduler Registry" "Extensible factory for Volcano, Yunikorn, kube-scheduler plugin integration" "Go Library"
            }

            webhook = container "Spark Operator Webhook" "Validates and defaults SparkApplication and ScheduledSparkApplication CRs; mutates Spark pods with 25+ configuration injections" "Go Admission Webhook Server" {
                saDefaulter = component "SparkApplication Defaulter" "Sets default values on SparkApplication CRs" "Go Webhook"
                saValidator = component "SparkApplication Validator" "Validates SparkApplication CRs" "Go Webhook"
                ssaDefaulter = component "ScheduledSparkApplication Defaulter" "Sets default values on ScheduledSparkApplication CRs" "Go Webhook"
                ssaValidator = component "ScheduledSparkApplication Validator" "Validates ScheduledSparkApplication CRs" "Go Webhook"
                podMutator = component "Spark Pod Mutator" "Applies 25+ mutations to driver/executor pods: env, volumes, ports, init containers, GPU, Prometheus, security, scheduling, DNS" "Go Webhook"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and admission webhook callbacks" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes operator metrics" "Internal Platform"
        rhodsOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Platform operator that deploys spark-operator via kustomize overlays" "Internal Platform"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate issuance and rotation" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional batch scheduler using PodGroup CRDs for gang scheduling" "External"
        kubeSchedulerPlugins = softwareSystem "kube-scheduler plugins" "Optional coarse-grained scheduling via PodGroup CRDs" "External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Optional annotation-based batch scheduler with memory overhead calculations" "External"

        // Relationships
        user -> sparkOperator "Creates SparkApplication, ScheduledSparkApplication, SparkConnect CRs" "kubectl / HTTPS"
        sparkOperator -> k8sAPI "CRUD on pods, services, configmaps, ingresses, CRDs, events" "HTTPS/6443"
        k8sAPI -> sparkOperator "Admission webhook callbacks for CR validation and pod mutation" "HTTPS/9443"
        prometheus -> sparkOperator "Scrapes operator metrics" "HTTP/8080"
        rhodsOperator -> sparkOperator "Deploys and manages operator lifecycle" "Kustomize"
        sparkOperator -> certManager "Optional: TLS certificate issuance" "HTTPS/6443 via K8s API"
        sparkOperator -> volcano "Creates/deletes Volcano PodGroups" "HTTPS/6443 via K8s API"
        sparkOperator -> kubeSchedulerPlugins "Creates/deletes scheduler-plugins PodGroups" "HTTPS/6443 via K8s API"
        sparkOperator -> yunikorn "Sets task-group annotations on pods" "N/A (annotation injection)"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
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

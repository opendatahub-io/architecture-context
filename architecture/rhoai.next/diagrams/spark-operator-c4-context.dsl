workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications on OpenShift/Kubernetes"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates lifecycle management of Apache Spark applications, scheduled Spark applications, and Spark Connect servers" {
            controller = container "spark-operator controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRs; manages driver/executor pods, web UI services, ingress, and monitoring ConfigMaps" "Go Operator (controller-runtime)" "Component"
            webhook = container "spark-operator webhook" "Validates and defaults SparkApplication/ScheduledSparkApplication CRs; mutates Spark driver/executor pods with configuration injection (26 categories)" "Go Webhook Server" "Component"
            certProvider = container "Certificate Provider" "Manages TLS certificates for webhook server via internal self-signed CA (RSA 2048, 10yr) or cert-manager" "Go Library" "Component"
            schedulerRegistry = container "Scheduler Registry" "Pluggable batch scheduler abstraction supporting Volcano, Yunikorn, and kube-scheduler PodGroups" "Go Library" "Component"
        }

        k8sApiServer = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane" "External"
        sparkSubmit = softwareSystem "spark-submit" "Spark application submission CLI bundled in operator image" "External"
        volcano = softwareSystem "Volcano Scheduler" "Optional batch scheduler for gang scheduling via PodGroups" "External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Optional batch scheduler via task group annotations" "External"
        kubeScheduler = softwareSystem "kube-scheduler PodGroups" "Optional coscheduling via scheduler-plugins" "External"
        certManager = softwareSystem "cert-manager" "Optional external TLS certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External"
        kueue = softwareSystem "Kueue" "Optional workload queuing via pod labels" "External"
        odhOperator = softwareSystem "ODH / RHOAI Operator" "Deploys spark-operator via kustomize overlays; manages image references" "Internal Platform"

        # Relationships
        user -> sparkOperator "Creates SparkApplication / ScheduledSparkApplication / SparkConnect CRs" "kubectl / HTTPS"
        sparkOperator -> k8sApiServer "CRUD on pods, services, ingresses, configmaps, secrets, CRDs, webhook configs" "HTTPS/443 TLS 1.2+"
        sparkOperator -> sparkSubmit "Submits Spark applications via 29-stage argument pipeline" "Local exec"
        sparkOperator -> volcano "Gang scheduling via PodGroup CRDs (auto-detects CRD availability)" "HTTPS/443 TLS 1.2+"
        sparkOperator -> yunikorn "Gang scheduling via task group annotations" "Pod annotations"
        sparkOperator -> kubeScheduler "Coscheduling via PodGroup CRDs" "HTTPS/443 TLS 1.2+"
        sparkOperator -> certManager "Optional TLS certificate provisioning" "Secret watch"
        sparkOperator -> kueue "Workload queuing via pod labels" "Pod labels"
        prometheus -> sparkOperator "Scrapes metrics" "HTTP/8080"
        odhOperator -> sparkOperator "Deploys via kustomize; injects RELATED_IMAGE env vars" "Kustomize"
        k8sApiServer -> sparkOperator "Admission review requests to webhook" "HTTPS/9443 TLS"

        # Container-level relationships
        controller -> k8sApiServer "CRUD operations" "HTTPS/443"
        controller -> sparkSubmit "spark-submit subprocess" "Local exec"
        controller -> schedulerRegistry "Selects batch scheduler" "In-process"
        schedulerRegistry -> volcano "PodGroup management" "HTTPS/443"
        schedulerRegistry -> yunikorn "Annotation injection" "Pod annotations"
        schedulerRegistry -> kubeScheduler "PodGroup management" "HTTPS/443"
        k8sApiServer -> webhook "Admission reviews" "HTTPS/9443"
        certProvider -> webhook "Provisions TLS certificates" "In-process"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits Spark applications and scheduled jobs via kubectl or CI pipelines"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator for managing Apache Spark applications, scheduled jobs, and Spark Connect servers" {
            controller = container "Controller Manager" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages driver/executor pod lifecycle" "Go Operator (controller-runtime)"
            webhook = container "Webhook Server" "Mutates Spark pods with volumes, env vars, sidecars, monitoring, security contexts; validates SparkApplication specs" "Go Webhook Server (controller-runtime)"
            sparkDriverSA = container "spark-operator-spark SA" "ServiceAccount used by Spark driver pods to manage executor pods and services" "RBAC Identity"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane for resource management" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "External"
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduler with gang scheduling via PodGroup CRDs" "External"
        kubeSchedPlugins = softwareSystem "kube-scheduler-plugins" "Scheduler plugins with PodGroup support" "External"
        yunikorn = softwareSystem "Yunikorn Scheduler" "Annotation-based batch scheduler with task groups" "External"
        kueue = softwareSystem "Kueue" "Workload management via label propagation" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys Spark Operator via kustomize overlays" "Internal Platform"
        sparkRuntime = softwareSystem "Apache Spark Runtime" "Spark 4.0.1 driver and executor pods running on Kubernetes" "External"

        # Relationships
        user -> sparkOperator "Submits SparkApplication / ScheduledSparkApplication / SparkConnect CRs" "kubectl / HTTPS"
        user -> k8sAPI "Creates Spark CRDs" "HTTPS/443"

        controller -> k8sAPI "Reconciles CRDs, creates/manages pods, services, ingresses" "HTTPS/443"
        webhook -> k8sAPI "Reads SparkApplication specs, updates webhook configurations" "HTTPS/443"
        k8sAPI -> webhook "Sends admission review requests" "HTTPS/9443 TLS"
        controller -> sparkRuntime "Executes spark-submit for driver pods" "Process exec"

        sparkOperator -> prometheus "Exposes operator and Spark job metrics" "HTTP/8080"
        sparkOperator -> certManager "Optional TLS certificate provisioning for webhook" "CRD API"
        sparkOperator -> volcano "Creates PodGroup CRs for gang scheduling" "HTTPS/443 via K8s API"
        sparkOperator -> kubeSchedPlugins "Creates PodGroup CRs with resource constraints" "HTTPS/443 via K8s API"
        sparkOperator -> yunikorn "Adds task group annotations to pods" "Pod annotations"
        sparkOperator -> kueue "Propagates workload management labels" "Pod labels"

        rhodsOperator -> sparkOperator "Deploys via kustomize overlays at pinned commits" "Kustomize"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
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

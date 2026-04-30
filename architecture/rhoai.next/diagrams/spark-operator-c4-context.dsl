workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits Spark applications for data processing and ML workloads"
        ciSystem = person "CI/CD System" "Automates Spark job submissions"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator for managing Apache Spark applications, scheduled jobs, and Spark Connect servers" {
            controller = container "Controller Manager" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages driver/executor pod lifecycle" "Go (controller-runtime)"
            webhook = container "Webhook Server" "Mutates Spark pods with volumes, env vars, sidecars, monitoring, security contexts; validates SparkApplication specs" "Go (controller-runtime)"
            sparkDriverSA = container "spark-operator-spark SA" "ServiceAccount used by Spark driver pods to manage executor pods" "Kubernetes ServiceAccount"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management and admission control" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via PodMonitor" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for webhook server" "External"

        volcanoScheduler = softwareSystem "Volcano Scheduler" "Optional batch scheduler for gang scheduling via PodGroup CRDs" "External"
        yunikornScheduler = softwareSystem "Yunikorn Scheduler" "Optional batch scheduler with task group annotations" "External"
        kubeSchedulerPlugins = softwareSystem "kube-scheduler-plugins" "Optional batch scheduler with PodGroup CRDs" "External"
        kueue = softwareSystem "Kueue" "Optional workload management via label propagation" "External"

        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that deploys spark-operator via kustomize overlays" "Internal RHOAI"

        sparkRuntime = softwareSystem "Apache Spark Runtime" "Spark 4.0.1 driver and executor processes running in pods" "External"

        user -> sparkOperator "Submits SparkApplication/ScheduledSparkApplication/SparkConnect CRs" "kubectl / HTTPS"
        ciSystem -> sparkOperator "Automates Spark job submissions" "kubectl / HTTPS"

        sparkOperator -> k8sAPI "CRUD for pods, services, ingresses, CRD status updates" "HTTPS/443"
        k8sAPI -> webhook "Admission webhooks (mutate/validate)" "HTTPS/9443"
        controller -> sparkRuntime "Creates and monitors Spark driver/executor pods" "spark-submit"
        prometheus -> sparkOperator "Scrapes operator and Spark job metrics" "HTTP/8080"
        sparkOperator -> certManager "Optional: TLS certificate provisioning" "CRD"
        sparkOperator -> volcanoScheduler "Creates PodGroup CRs for gang scheduling" "HTTPS/443"
        sparkOperator -> yunikornScheduler "Adds task group annotations for gang scheduling" "Pod annotations"
        sparkOperator -> kubeSchedulerPlugins "Creates PodGroup CRs with min members" "HTTPS/443"
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

workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications via CRDs"

        sparkOperator = softwareSystem "Spark Operator" "Manages lifecycle of Apache Spark applications on OpenShift" {
            controller = container "Spark Operator Controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages driver/executor pods, services, ingresses, PDBs" "Go Operator (controller-runtime)" "Primary"
            webhook = container "Webhook Server" "Validates and mutates SparkApplication, ScheduledSparkApplication, SparkConnect CRs and Spark pods; enforces SparkConf security policies" "Go Admission Webhook" "Primary"
            moduleController = container "Module Controller" "Manages spark-operator deployment lifecycle via SparkOperator CRD; handles platform detection and kustomize rendering" "Go Operator (controller-runtime)" "Module"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API server for all resource operations" "External"
        openshiftApi = softwareSystem "OpenShift API Server" "Provides cluster TLS security profile configuration" "External"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that creates SparkOperator CR to deploy spark-operator" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "Optional TLS certificate management for webhook" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection via PodMonitor" "External"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling via PodGroup CRDs" "External"
        yunikornScheduler = softwareSystem "YuniKorn Scheduler" "Gang scheduling via pod annotations" "External"
        kubeSchedulerPlugins = softwareSystem "kube-scheduler (scheduler-plugins)" "Gang scheduling via PodGroup CRDs" "External"
        s3Storage = softwareSystem "Object Storage (S3)" "Model and data artifact storage for Spark jobs" "External"

        user -> sparkOperator "Creates SparkApplication / ScheduledSparkApplication / SparkConnect CRs via kubectl"
        rhodsOperator -> sparkOperator "Creates SparkOperator CR to deploy operator" "Kubernetes API"
        sparkOperator -> k8sApi "CRUD operations on pods, services, ingresses, ConfigMaps, CRDs" "HTTPS/443"
        sparkOperator -> openshiftApi "Reads cluster TLS security profile" "HTTPS/443"
        sparkOperator -> certManager "Requests webhook TLS certificates" "Kubernetes API"
        sparkOperator -> volcanoScheduler "Creates PodGroup CRs for gang scheduling" "Kubernetes API"
        sparkOperator -> yunikornScheduler "Sets task-group and queue annotations" "Annotations"
        sparkOperator -> kubeSchedulerPlugins "Creates PodGroup CRs for gang scheduling" "Kubernetes API"
        prometheus -> sparkOperator "Scrapes metrics from controller and webhook" "HTTP/8080"

        controller -> k8sApi "Creates/manages driver pods, executor pods, services, ingresses, PDBs, NetworkPolicies" "HTTPS/443"
        webhook -> k8sApi "Admission review responses" "HTTPS/443"
        moduleController -> controller "Deploys and manages controller deployment" "Kustomize rendering"
        moduleController -> webhook "Deploys and manages webhook deployment" "Kustomize rendering"
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
            element "Primary" {
                background #4a90e2
                color #ffffff
            }
            element "Module" {
                background #50b5e8
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        user = person "Data Engineer / Data Scientist" "Submits Spark applications and connects via SparkConnect"
        ciPipeline = person "CI Pipeline" "Automated submission of scheduled Spark jobs"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator for managing Apache Spark applications, scheduled jobs, and Spark Connect sessions on OpenShift" {
            controller = container "spark-operator-controller" "Reconciles SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; manages Spark driver/executor pod lifecycle" "Go Operator" "Deployment"
            webhook = container "spark-operator-webhook" "Mutating and validating admission webhooks for Spark resources and pods; enforces ResourceQuota" "Go Webhook Server" "Deployment"
            moduleController = container "spark-operator-module-controller" "Meta-operator managing the lifecycle of the Spark workload operator as an ODH/RHOAI component" "Go Operator" "Deployment"
            pythonSDK = container "kubeflow_spark_api" "Python client SDK for programmatic interaction with Spark Operator CRDs" "Python Library"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides TLS profile configuration (config.openshift.io)" "External"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate lifecycle management" "Internal Platform"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring via PodMonitor resources" "Internal Platform"
        platformOperator = softwareSystem "opendatahub-operator / rhods-operator" "Platform operator that creates SparkOperator CR" "Internal Platform"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection and manifest rendering library" "Internal Platform"
        volcano = softwareSystem "Volcano" "Batch scheduler for gang scheduling" "External"

        sparkRuntime = softwareSystem "Spark Runtime" "Driver and executor pods running Spark workloads" {
            driverPod = container "Spark Driver Pod" "Runs Spark driver process, manages executors" "JVM / PySpark" "Pod"
            executorPods = container "Spark Executor Pods" "Run Spark tasks distributed by driver" "JVM / PySpark" "Pod"
            sparkUI = container "Spark UI" "Web interface for monitoring Spark applications" "HTTP Service" "Service"
            sparkConnect = container "SparkConnect gRPC" "Persistent Spark Connect session endpoint" "gRPC Service" "Service"
        }

        # User interactions
        user -> sparkOperator "Submits SparkApplication / SparkConnect CRs via kubectl"
        user -> sparkConnect "Connects via SparkConnect gRPC client" "gRPC/15002"
        user -> sparkUI "Monitors running applications" "HTTP/4040"
        ciPipeline -> sparkOperator "Creates ScheduledSparkApplication CRs"

        # Internal flows
        controller -> kubernetesAPI "Reconciles CRDs, manages pods/services" "HTTPS/6443"
        controller -> openShiftAPI "Retrieves TLS profile configuration" "HTTPS/6443"
        webhook -> kubernetesAPI "Checks ResourceQuota, updates webhook configs" "HTTPS/6443"
        kubernetesAPI -> webhook "Sends admission requests" "HTTPS/9443"
        moduleController -> kubernetesAPI "Deploys controller, webhook, CRDs, RBAC" "HTTPS/6443"

        # Platform interactions
        platformOperator -> sparkOperator "Creates SparkOperator CR" "Kubernetes API"
        moduleController -> odhPlatformUtils "Platform detection, manifest rendering" "Go library"
        controller -> certManager "Manages Certificate and Issuer CRs" "Kubernetes API"
        controller -> prometheusOperator "Creates PodMonitor for metrics" "Kubernetes API"

        # Spark runtime
        controller -> driverPod "Creates and monitors driver pods" "Kubernetes API"
        driverPod -> executorPods "Launches and manages executors" "TCP/7078,7079"
        controller -> sparkUI "Creates Kubernetes Service" "Kubernetes API"
        controller -> sparkConnect "Creates gRPC endpoint service" "Kubernetes API"

        # Batch scheduling
        controller -> volcano "Gang scheduling integration" "Kubernetes API"
    }

    views {
        systemContext sparkOperator "SystemContext" {
            include *
            autoLayout
        }

        container sparkOperator "SparkOperatorContainers" {
            include *
            autoLayout
        }

        container sparkRuntime "SparkRuntimeContainers" {
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
            element "Deployment" {
                shape RoundedBox
            }
            element "Pod" {
                shape Hexagon
            }
            element "Service" {
                shape Pipe
            }
        }
    }
}

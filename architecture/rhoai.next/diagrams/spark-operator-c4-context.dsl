workspace {
    model {
        user = person "Data Scientist" "Creates and deploys Spark applications on OpenShift"
        clusterAdmin = person "Cluster Admin" "Manages platform components and RBAC"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates Apache Spark application lifecycle management on OpenShift" {
            controller = container "Spark Controller" "Watches SparkApplication, ScheduledSparkApplication, SparkConnect CRs; manages Spark job lifecycle via 13-state state machine reconciliation" "Go Operator (controller-runtime)"
            webhook = container "Webhook Server" "Validates/defaults CRs on create/update; mutates Spark pods to inject 23 categories of configuration (volumes, env, sidecars, GPU, scheduling)" "Go Webhook Server" {
                tags "Webhook"
            }
            moduleController = container "Module Controller" "Platform bridge -- watches SparkOperator CR from ODH/RHOAI and renders workload operator manifests via server-side apply" "Go Operator (controller-runtime)" {
                tags "Platform Bridge"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" {
            tags "External"
        }
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "RHOAI/ODH platform operator that manages component lifecycles" {
            tags "Internal Platform"
        }
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science workloads" {
            tags "Internal Platform"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "External"
        }
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" {
            tags "External"
        }
        volcano = softwareSystem "Volcano Scheduler" "Batch scheduler with gang scheduling via PodGroup" {
            tags "External"
        }
        yunikorn = softwareSystem "YuniKorn Scheduler" "Batch scheduler via pod annotations" {
            tags "External"
        }
        kubeScheduler = softwareSystem "kube-scheduler-plugins" "Kubernetes native gang scheduling via PodGroup" {
            tags "External"
        }
        openShiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS security profile configuration" {
            tags "External"
        }
        restSubmitter = softwareSystem "REST Spark Submitter" "External Spark submission service with mTLS (optional, feature gate)" {
            tags "External"
        }

        // User interactions
        user -> sparkOperator "Creates SparkApplication/ScheduledSparkApplication/SparkConnect CRs via kubectl"
        clusterAdmin -> rhodsOperator "Configures platform components"

        // Platform interactions
        rhodsOperator -> sparkOperator "Creates SparkOperator CR to trigger module controller"
        odhDashboard -> sparkOperator "Workbench clients connect via SparkConnect gRPC/15002"

        // External dependencies
        sparkOperator -> k8sAPI "CRD watches, pod CRUD, RBAC enforcement" "HTTPS/443"
        sparkOperator -> prometheus "Exposes application and executor metrics" "HTTP/8080"
        sparkOperator -> certManager "Optional TLS certificate management for webhook"
        sparkOperator -> volcano "Gang scheduling via PodGroup CR" "HTTPS/443"
        sparkOperator -> yunikorn "Gang scheduling via pod annotations"
        sparkOperator -> kubeScheduler "Gang scheduling via scheduler-plugins PodGroup" "HTTPS/443"
        sparkOperator -> openShiftAPI "Fetches cluster TLS security profile" "HTTPS/443"
        sparkOperator -> restSubmitter "External Spark submission with mTLS" "HTTPS (mTLS)"

        // Container-level interactions
        controller -> k8sAPI "Watches CRs, creates pods/services/ingresses" "HTTPS/443"
        webhook -> k8sAPI "Receives admission reviews" "HTTPS/9443"
        moduleController -> k8sAPI "Server-side apply of workload operator manifests" "HTTPS/443"
        controller -> openShiftAPI "Fetches TLS security profile" "HTTPS/443"
        controller -> restSubmitter "REST submission with mTLS" "HTTPS"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Webhook" {
                background #f5a623
                color #ffffff
            }
            element "Platform Bridge" {
                background #9b59b6
                color #ffffff
            }
        }
    }
}

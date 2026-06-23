workspace {
    model {
        user = person "Data Scientist" "Creates and manages Spark applications on Kubernetes/OpenShift"

        sparkOperator = softwareSystem "Spark Operator" "Kubernetes operator that automates submission, scheduling, monitoring, and lifecycle management of Apache Spark applications" {
            controller = container "spark-operator-controller" "Watches SparkApplication, ScheduledSparkApplication, and SparkConnect CRDs; creates and manages driver pods, Services, Ingresses, and ConfigMaps" "Go Operator (controller-runtime v0.20.4)"
            webhook = container "spark-operator-webhook" "Mutates Spark pods (injects volumes, env vars, labels, security contexts), validates SparkApplication specs, enforces ResourceQuota" "Go Admission Webhook (9443/TCP HTTPS)"
            mwhController = container "MutatingWebhookConfig Controller" "Syncs self-signed CA certificate bundle to MutatingWebhookConfiguration for certificate rotation" "Go Controller"
            vwhController = container "ValidatingWebhookConfig Controller" "Syncs self-signed CA certificate bundle to ValidatingWebhookConfiguration for certificate rotation" "Go Controller"
            certManager = container "Certificate Manager" "Self-signed RSA-2048 CA with 10-year validity, 180-day expiry check, auto-regeneration" "Go (pkg/certificate)"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Kubernetes cluster API for resource management" "External"
        openShiftAPI = softwareSystem "OpenShift APIServer" "OpenShift cluster configuration including TLS security profiles" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that deploys spark-operator via kustomize overlays" "Internal Platform"

        volcano = softwareSystem "Volcano" "Batch scheduler for gang scheduling via PodGroup CRDs" "External Optional"
        schedulerPlugins = softwareSystem "Kube-scheduler Plugins" "Scheduler plugins for PodGroup-based co-scheduling" "External Optional"
        yunikorn = softwareSystem "YuniKorn" "Scheduler using pod annotations for gang scheduling" "External Optional"
        kueue = softwareSystem "Kueue" "Workload queuing via pod labels" "External Optional"
        certManagerExt = softwareSystem "cert-manager" "Optional external certificate management" "External Optional"

        sparkDriver = softwareSystem "Spark Driver Pod" "Executes Spark application driver logic, creates executor pods" "Managed Workload"
        sparkExecutor = softwareSystem "Spark Executor Pods" "Execute Spark tasks assigned by the driver" "Managed Workload"
        sparkConnect = softwareSystem "SparkConnect Server" "Persistent Spark Connect gRPC server for interactive sessions" "Managed Workload"

        # Relationships
        user -> sparkOperator "Creates SparkApplication/ScheduledSparkApplication/SparkConnect CRs" "kubectl / HTTPS 443"
        user -> sparkConnect "Connects for interactive sessions" "gRPC 15002"
        user -> sparkDriver "Views Spark Web UI" "HTTP 4040 (via Ingress)"

        sparkOperator -> k8sAPI "CRUD on Pods, Services, Ingresses, ConfigMaps, CRDs, Events, Leases" "HTTPS/443 TLS 1.2+"
        sparkOperator -> openShiftAPI "Reads cluster TLS security profile for webhook cipher configuration" "HTTPS/443 TLS 1.2+"
        sparkOperator -> sparkDriver "Creates and manages driver pods" "K8s API"
        sparkOperator -> sparkExecutor "Mutates executor pods at admission" "Webhook"

        controller -> webhook "Pods intercepted at admission" "AdmissionReview"
        mwhController -> certManager "Gets CA cert bundle" "Internal"
        vwhController -> certManager "Gets CA cert bundle" "Internal"

        sparkDriver -> k8sAPI "Creates executor pods" "HTTPS/443 SA token"
        sparkDriver -> sparkExecutor "Spark RPC communication" "TCP 7078,7079"
        sparkConnect -> sparkExecutor "Spark RPC communication" "TCP 7078,7079"

        k8sAPI -> webhook "Admission reviews (mutate/validate)" "HTTPS 443→9443 mTLS"

        prometheus -> sparkOperator "Scrapes metrics" "HTTP/8080"
        rhodsOperator -> sparkOperator "Deploys via kustomize overlays" "Manifest management"

        sparkOperator -> volcano "Creates PodGroup CRDs for gang scheduling" "K8s API"
        sparkOperator -> schedulerPlugins "Creates PodGroup CRDs for co-scheduling" "K8s API"
        sparkOperator -> yunikorn "Annotates pods with task-groups" "Pod annotations"
        sparkOperator -> kueue "Labels pods with queue-name" "Pod labels"
        sparkOperator -> certManagerExt "Optional TLS certificate management" "K8s CRD API"
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
                background #cccccc
                color #333333
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

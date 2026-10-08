workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML workloads (Jobs, PyTorchJobs, RayJobs)"
        platformAdmin = person "Platform Admin" "Configures Kueue operator and cluster resource quotas"

        kueueOperator = softwareSystem "Kueue Operator" "OpenShift operator managing Kueue workload queuing system for Kubernetes-native job scheduling and resource quota management" {
            operatorController = container "openshift-kueue-operator" "Watches Kueue CR and reconciles operand stack (CRDs, RBAC, webhooks, NetworkPolicies, certificates)" "Go Operator (library-go)" "operator"
            controllerManager = container "kueue-controller-manager" "Manages workload queuing, admission webhooks, scheduling, and visibility API" "Go Controller (upstream Kueue)" "operand"
            webhookServer = container "Webhook Server" "17 mutating + 18 validating admission webhooks for 14 workload types; fail-closed policy" "HTTPS/9443" "webhook"
            visibilityAPI = container "Visibility API Server" "Aggregated Kubernetes API for querying pending workloads in ClusterQueues and LocalQueues" "HTTPS/8082" "api"
            mustGather = container "must-gather" "Diagnostic data collection for Kueue support cases" "Shell scripts" "diagnostic"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and admission control" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks and metrics" "External"
        prometheusOperator = softwareSystem "Prometheus / Monitoring" "Metrics collection via ServiceMonitor" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "PyTorchJob, MPIJob, TFJob, PaddleJob, XGBoostJob workloads" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay" "RayCluster and RayJob workloads" "Internal RHOAI"
        codeFlare = softwareSystem "CodeFlare" "AppWrapper workloads" "Internal RHOAI"
        jobSetController = softwareSystem "JobSet Controller" "JobSet workloads" "Internal RHOAI"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Controller" "LeaderWorkerSet workloads" "Internal RHOAI"

        # Relationships
        platformAdmin -> kueueOperator "Configures via Kueue CR (kubectl)" "HTTPS/6443"
        dataScientist -> kubernetesAPI "Creates workloads (Jobs, PyTorchJobs, RayJobs)" "HTTPS/6443"

        operatorController -> kubernetesAPI "Reconciles operand resources" "HTTPS/6443"
        operatorController -> certManager "Creates Issuer + Certificate CRs" "HTTPS/6443"
        operatorController -> controllerManager "Deploys and manages" "Kubernetes"

        controllerManager -> kubernetesAPI "Manages workloads, queues, RBAC" "HTTPS/6443"
        controllerManager -> webhookServer "Hosts" "Internal"

        kubernetesAPI -> webhookServer "Dispatches admission requests" "HTTPS/9443"

        prometheusOperator -> controllerManager "Scrapes metrics" "HTTPS/8443 mTLS"

        kubeflowTraining -> webhookServer "Workloads intercepted" "HTTPS/9443"
        kubeRay -> webhookServer "Workloads intercepted" "HTTPS/9443"
        codeFlare -> webhookServer "Workloads intercepted" "HTTPS/9443"
        jobSetController -> webhookServer "Workloads intercepted" "HTTPS/9443"
        leaderWorkerSet -> webhookServer "Workloads intercepted" "HTTPS/9443"
    }

    views {
        systemContext kueueOperator "SystemContext" {
            include *
            autoLayout
        }

        container kueueOperator "Containers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "operator" {
                background #4a90e2
                color #ffffff
            }
            element "operand" {
                background #7ed321
                color #ffffff
            }
            element "webhook" {
                background #f5a623
                color #ffffff
            }
            element "api" {
                background #50e3c2
                color #333333
            }
            element "diagnostic" {
                background #b8b8b8
                color #333333
            }
        }
    }
}

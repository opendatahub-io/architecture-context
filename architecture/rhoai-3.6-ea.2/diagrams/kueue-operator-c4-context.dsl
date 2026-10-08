workspace {
    model {
        admin = person "Cluster Admin" "Configures Kueue operator and ClusterQueues"
        user = person "Data Scientist" "Submits batch and AI/ML jobs via LocalQueues"

        kueueOperator = softwareSystem "Kueue Operator" "OpenShift operator that deploys, configures, and lifecycle-manages the Kueue workload queueing system" {
            operator = container "openshift-kueue-operator" "Watches Kueue CR, reconciles operand resources (deployment, CRDs, RBAC, webhooks, certs, monitoring)" "Go Operator (openshift/library-go)" {
                reconciler = component "TargetConfigReconciler" "Main sync loop managing all operand resources" "Go"
                certHandler = component "CertHandler" "Manages cert-manager Issuer and Certificate CRs" "Go"
                webhookFilter = component "WebhookFilter" "Dynamically filters webhook configurations based on enabled integrations" "Go"
            }

            operand = container "kueue-controller-manager" "Core queueing, admission, scheduling, and webhook serving" "Go Controller (controller-runtime)" {
                scheduler = component "Scheduler" "Fair-share scheduling and preemption across ClusterQueues" "Go"
                admissionController = component "AdmissionController" "Evaluates workload admission based on quotas and checks" "Go"
                webhookServer = component "WebhookServer" "Mutating and validating webhooks for workload integrations" "Go"
                visibilityAPI = component "VisibilityAPI" "API aggregation server for pending workload visibility" "Go"
            }

            mustGather = container "must-gather" "Collects Kueue-specific diagnostic data" "Shell scripts"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate provisioning for webhooks and metrics" "External Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection via ServiceMonitor" "External Platform"
        k8sAPI = softwareSystem "Kubernetes API" "Core resource management, CRD operations, leader election" "External Platform"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Training job frameworks (PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob)" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay" "Ray cluster and job management" "Internal RHOAI"
        codeFlare = softwareSystem "CodeFlare" "AppWrapper workload management" "Internal RHOAI"
        jobSetController = softwareSystem "JobSet Controller" "Multi-replica job orchestration" "External Platform"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Controller" "Leader-worker topology jobs" "External Platform"

        // Relationships
        admin -> kueueOperator "Creates Kueue CR via kubectl" "HTTPS/6443"
        user -> k8sAPI "Submits Jobs, PyTorchJobs, RayJobs" "HTTPS/6443"

        kueueOperator -> k8sAPI "Manages operand resources (deployments, CRDs, RBAC, webhooks)" "HTTPS/6443"
        kueueOperator -> certManager "Creates Issuer and Certificate CRs" "HTTPS/6443"

        operator -> operand "Deploys and manages lifecycle"

        operand -> k8sAPI "Watches workloads, manages admission, leader election" "HTTPS/6443"
        prometheus -> operand "Scrapes metrics" "HTTPS/8443"

        operand -> kubeflowTraining "Intercepts via webhooks" "HTTPS/9443"
        operand -> kubeRay "Intercepts via webhooks" "HTTPS/9443"
        operand -> codeFlare "Intercepts via webhooks" "HTTPS/9443"
        operand -> jobSetController "Intercepts via webhooks" "HTTPS/9443"
        operand -> leaderWorkerSet "Intercepts via webhooks" "HTTPS/9443"
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

        component operator "OperatorComponents" {
            include *
            autoLayout
        }

        component operand "OperandComponents" {
            include *
            autoLayout
        }

        styles {
            element "External Platform" {
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

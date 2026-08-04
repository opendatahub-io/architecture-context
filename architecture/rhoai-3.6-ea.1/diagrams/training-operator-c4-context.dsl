workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits distributed training jobs"
        mlEngineer = person "ML Engineer" "Builds training pipelines and manages job configurations"

        trainingOperator = softwareSystem "Training Operator" "Kubernetes operator managing distributed ML training jobs across six frameworks (PyTorch, TensorFlow, JAX, MPI, XGBoost, PaddlePaddle)" {
            controllerManager = container "Controller Manager" "Runs 6 reconcilers (one per CRD) managing the lifecycle of training job Pods, Services, and ServiceAccounts" "Go controller-runtime v0.19.1"
            webhookServer = container "Webhook Server" "Validates training job CRs on CREATE/UPDATE with failurePolicy: Fail" "Go, TLS on port 9443"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics at :8080/metrics" "HTTP, no auth"
            kubectlDelivery = container "kubectl-delivery" "Init container that copies kubectl binary into training Pods requiring it (MPI jobs)" "Container image"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource CRUD and admission webhooks" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Internal Platform"
        volcanoScheduler = softwareSystem "Volcano Scheduler" "Gang scheduling for coordinated pod group launches" "External, Optional"
        schedulerPlugins = softwareSystem "Kubernetes Scheduler Plugins" "Alternative gang scheduler via scheduling.x-k8s.io" "External, Optional"
        openShiftAPIServer = softwareSystem "OpenShift APIServer" "Cluster-wide TLS security profile configuration" "External, Optional"
        certController = softwareSystem "cert-controller" "OPA cert-controller v0.12.0 for webhook TLS certificate lifecycle" "External"

        # User interactions
        dataScientist -> trainingOperator "Submits training jobs (PyTorchJob, TFJob, etc.) via kubectl/API"
        mlEngineer -> trainingOperator "Configures and manages training job templates and pipelines"

        # Internal container interactions
        controllerManager -> webhookServer "Hosts webhook server for admission validation"

        # External interactions
        trainingOperator -> kubernetesAPI "CRUD operations on Pods, Services, SAs, PodGroups, NetworkPolicies" "HTTPS/6443, SA token"
        kubernetesAPI -> trainingOperator "Sends admission webhook requests for training job validation" "HTTPS/9443, TLS"
        prometheus -> trainingOperator "Scrapes operator metrics" "HTTP/8080"
        trainingOperator -> volcanoScheduler "Creates/manages PodGroups for gang scheduling" "via Kubernetes API"
        trainingOperator -> schedulerPlugins "Creates/manages PodGroups (alternative scheduler)" "via Kubernetes API"
        trainingOperator -> openShiftAPIServer "Reads TLS security profile at startup" "HTTPS/6443, SA token"
        certController -> trainingOperator "Provisions and rotates webhook TLS certificates"
    }

    views {
        systemContext trainingOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainingOperator "Containers" {
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
            element "External, Optional" {
                background #bbbbbb
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

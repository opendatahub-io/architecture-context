workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch jobs and ML training workloads"
        admin = person "Platform Administrator" "Configures queues, quotas, and resource policies"

        kueue = softwareSystem "Kueue" "Job queueing controller managing workload admission and resource allocation" {
            controller = container "kueue-controller-manager" "Manages workload admission, queue reconciliation, and job lifecycle" "Go Controller" {
                queueMgr = component "Queue Manager" "Manages ClusterQueues, LocalQueues, and workload prioritization" "Go"
                admissionMgr = component "Admission Manager" "Controls workload admission based on quotas and priorities" "Go"
                reconciler = component "Job Reconciler" "Watches and reconciles batch jobs and training workloads" "Go"
                autoscalerIntegration = component "Autoscaler Integration" "Creates ProvisioningRequests for cluster autoscaling" "Go"
            }
            webhook = container "Webhook Server" "Validates and mutates job resources during admission" "Go Webhook" {
                mutatingWebhook = component "Mutating Webhook" "Adds queue labels and resource annotations to jobs" "Go"
                validatingWebhook = component "Validating Webhook" "Validates job configurations against queue policies" "Go"
            }
            visibilityServer = container "Visibility API Server" "Extended API providing visibility into pending workloads" "Go APIService"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "ML training job operator for PyTorch, TensorFlow, MPI jobs" "Internal ODH"
        rayOperator = softwareSystem "Ray Operator" "Distributed computing framework for Ray workloads" "Internal ODH"
        jobsetController = softwareSystem "JobSet Controller" "Multi-job workflow orchestrator" "Internal ODH"
        clusterAutoscaler = softwareSystem "cluster-autoscaler" "Kubernetes cluster autoscaler" "External"
        certManager = softwareSystem "cert-manager" "Kubernetes certificate management" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "External"

        # Relationships
        user -> kueue "Submits jobs via kubectl/API" "HTTPS/6443"
        admin -> kueue "Configures ClusterQueues, LocalQueues, ResourceFlavors" "HTTPS/6443"

        kueue -> kubernetes "Watches and reconciles jobs, workloads, and CRDs" "HTTPS/6443"
        kubernetes -> kueue "Calls webhooks for job validation/mutation" "HTTPS/9443"
        kubernetes -> kueue "Routes visibility API queries" "HTTPS/8082"

        kueue -> kubeflowTraining "Manages admission for ML training jobs (PyTorchJob, TFJob, MPIJob, etc.)" "HTTPS/6443"
        kueue -> rayOperator "Manages admission for Ray distributed workloads (RayJob, RayCluster)" "HTTPS/6443"
        kueue -> jobsetController "Manages admission for multi-job workflows (JobSet)" "HTTPS/6443"
        kueue -> clusterAutoscaler "Creates ProvisioningRequests for node autoscaling" "HTTPS/443"
        certManager -> kueue "Provisions TLS certificates for webhooks and visibility API" "Internal"
        prometheus -> kueue "Scrapes metrics (queue depth, admission latency, quotas)" "HTTPS/8443"

        kubeflowTraining -> kubernetes "Creates ML training job CRDs" "HTTPS/6443"
        rayOperator -> kubernetes "Creates Ray workload CRDs" "HTTPS/6443"
        jobsetController -> kubernetes "Creates JobSet CRDs" "HTTPS/6443"

        # Controller internal relationships
        queueMgr -> admissionMgr "Provides queue and quota state"
        admissionMgr -> reconciler "Admits or suspends workloads"
        reconciler -> autoscalerIntegration "Requests node provisioning"

        # Webhook internal relationships
        mutatingWebhook -> validatingWebhook "Mutations before validation"
    }

    views {
        systemContext kueue "KueueSystemContext" {
            include *
            autoLayout
            description "System context diagram for Kueue job queueing controller in RHOAI"
        }

        container kueue "KueueContainers" {
            include *
            autoLayout
            description "Container diagram showing Kueue's internal components"
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
            description "Component diagram for kueue-controller-manager"
        }

        component webhook "WebhookComponents" {
            include *
            autoLayout
            description "Component diagram for webhook server"
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #dae8fc
                color #000000
            }
            element "Component" {
                background #fff2cc
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}

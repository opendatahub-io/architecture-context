workspace {
    model {
        admin = person "Cluster Admin" "Configures the Kueue operator via the singleton Kueue CR"
        batchUser = person "Data Scientist / Batch User" "Submits batch workloads (Jobs, PyTorchJobs, RayJobs, etc.) to managed namespaces"

        kueueOperator = softwareSystem "kueue-operator" "OpenShift operator that deploys and manages the Kueue job queuing system for Kubernetes workload scheduling and resource management" {
            operator = container "openshift-kueue-operator" "Parent operator that watches the Kueue CR and reconciles the full operand stack" "Go Operator (2 replicas, leader election)"
            controllerManager = container "kueue-controller-manager" "Core Kueue controller implementing queue scheduling, workload admission, preemption, gang scheduling, and admission webhooks" "Go Controller (1 replica)"
            webhookServer = container "Webhook Server" "17 mutating + 18 validating admission webhook endpoints for managed workload types; scoped to opt-in namespaces" "HTTPS/9443"
            visibilityAPI = container "Visibility API Server" "Pending workloads query API for monitoring queue status" "HTTPS/8082"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics with mTLS via cert-manager" "HTTPS/8443"
            mustGather = container "must-gather" "Diagnostic data collection for Kueue cluster state" "Shell Scripts"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management — operator gates on its availability; creates Issuer and Certificate CRs for webhook and metrics TLS" "External Prerequisite"
        prometheusOperator = softwareSystem "prometheus-operator" "Metrics collection platform; ServiceMonitor with mTLS scraping configuration" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Core resource management — deployments, CRDs, RBAC, webhook configurations" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Provides MPIJob, PyTorchJob, TFJob, PaddleJob, XGBoostJob workload types" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Provides RayCluster and RayJob workload types" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare Operator" "Provides AppWrapper workload type" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Provides JobSet workload type" "Internal RHOAI"
        leaderWorkerSet = softwareSystem "LeaderWorkerSet Controller" "Provides LeaderWorkerSet workload type" "Internal RHOAI"

        # Relationships
        admin -> kueueOperator "Creates/updates Kueue CR via kubectl" "HTTPS/6443"
        batchUser -> k8sAPI "Submits batch workloads to managed namespaces" "HTTPS/6443"

        operator -> controllerManager "Deploys and manages lifecycle"
        operator -> certManager "Creates Issuer + Certificate CRs; gates on availability" "HTTPS/6443"
        operator -> k8sAPI "Applies bindata assets (CRDs, RBAC, Deployments, Webhooks, NetworkPolicies)" "HTTPS/6443"

        controllerManager -> k8sAPI "Watches CRDs, manages workload admission" "HTTPS/6443"
        controllerManager -> webhookServer "Serves admission webhooks"
        controllerManager -> visibilityAPI "Serves visibility queries"
        controllerManager -> metricsEndpoint "Exposes Prometheus metrics"

        k8sAPI -> webhookServer "Admission webhook calls" "HTTPS/9443"
        prometheusOperator -> metricsEndpoint "Scrapes metrics with mTLS" "HTTPS/8443"

        kueueOperator -> kubeflowTraining "Admission control for kubeflow.org workloads" "Webhook/9443"
        kueueOperator -> rayOperator "Admission control for ray.io workloads" "Webhook/9443"
        kueueOperator -> codeflare "Admission control for AppWrapper workloads" "Webhook/9443"
        kueueOperator -> jobsetController "Admission control for JobSet workloads" "Webhook/9443"
        kueueOperator -> leaderWorkerSet "Admission control for LeaderWorkerSet workloads" "Webhook/9443"
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
            element "External Prerequisite" {
                background #ff6b6b
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

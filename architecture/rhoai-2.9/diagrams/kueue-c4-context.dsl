workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Submits batch jobs and training workloads to the cluster"
        ci = person "CI/CD Pipeline" "Automates job submission for ML training and batch processing"

        kueue = softwareSystem "Kueue" "Job queueing and resource management system that controls when jobs should be admitted based on available cluster resources" {
            controller = container "Kueue Controller Manager" "Manages workload admission, queue reconciliation, and resource allocation" "Go Operator" {
                cqController = component "ClusterQueue Controller" "Manages cluster-wide resource quotas and admission policies"
                lqController = component "LocalQueue Controller" "Manages namespace-scoped queues"
                wlController = component "Workload Controller" "Manages workload lifecycle and admission"
                acController = component "AdmissionCheck Controller" "Validates workloads before admission"
                jobControllers = component "Job Integration Controllers" "Integrates with Job, JobSet, Pod, Kubeflow, Ray frameworks"
            }
            webhook = container "Webhook Server" "Validates and mutates job resources on creation" "Go Admission Webhook" {
                mutatingWebhook = component "Mutating Webhook" "Injects Kueue labels and manages job suspension"
                validatingWebhook = component "Validating Webhook" "Validates job queue references and CRD configuration"
            }
            visibility = container "Visibility Server" "Provides visibility into pending workloads and queue status" "HTTP API"
            metrics = container "Metrics Server" "Exposes controller metrics for monitoring" "Prometheus Exporter"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring system" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages distributed ML training jobs (TFJob, PyTorchJob, MPIJob)" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Manages Ray clusters and jobs for distributed computing" "Internal RHOAI"
        clusterAutoscaler = softwareSystem "cluster-autoscaler" "Automatically provisions cluster nodes based on resource demands" "External"

        jobFrameworks = softwareSystem "Job Frameworks" "Various job execution frameworks" {
            batchJobs = container "Kubernetes Jobs" "Standard batch/v1 Jobs" "Core API"
            jobSet = container "JobSet" "Multi-job coordination" "jobset.x-k8s.io"
            kubeflowJobs = container "Kubeflow Training Jobs" "TFJob, PyTorchJob, MPIJob, etc." "kubeflow.org"
            rayJobs = container "Ray Workloads" "RayJob, RayCluster" "ray.io"
            pods = container "Plain Pods" "Individual pods with queueing" "Core API"
        }

        // User interactions
        user -> kueue "Submits jobs via kubectl"
        ci -> kueue "Automates job submission"

        // Kueue internal relationships
        controller -> webhook "Manages webhook configuration"
        controller -> visibility "Provides queue status data"
        controller -> metrics "Exports metrics"

        // Component relationships within controller
        wlController -> cqController "Requests admission"
        wlController -> lqController "Queries queue mapping"
        wlController -> acController "Validates before admission"
        jobControllers -> wlController "Creates workloads from jobs"

        // External system interactions
        kueue -> kubernetes "Watches and reconciles CRDs, Jobs, Pods via API (6443/TCP, HTTPS, ServiceAccount Token)"
        kubernetes -> webhook "Validates/mutates job resources via admission webhooks (9443/TCP, HTTPS, mTLS)"
        certManager -> webhook "Provides TLS certificates for webhook server"
        prometheus -> metrics "Scrapes controller metrics (8080/TCP, HTTP)"

        // Job framework integrations
        kueue -> jobFrameworks "Manages job lifecycle and admission"
        user -> jobFrameworks "Creates job resources"
        ci -> jobFrameworks "Creates job resources"

        // Internal RHOAI integrations
        kueue -> kubeflowTraining "Queues and admits Kubeflow training jobs (TFJob, PyTorchJob, MPIJob) via CRD reconciliation"
        kueue -> rayOperator "Queues and admits Ray workloads (RayJob, RayCluster) via CRD reconciliation"

        // Autoscaling integration
        kueue -> clusterAutoscaler "Requests node provisioning via ProvisioningRequest API (6443/TCP, HTTPS, ServiceAccount Token)"
        clusterAutoscaler -> kubernetes "Provisions nodes based on ProvisioningRequests"
    }

    views {
        systemContext kueue "SystemContext" {
            include *
            autoLayout
        }

        container kueue "Containers" {
            include *
            autoLayout
        }

        component controller "ControllerComponents" {
            include *
            autoLayout
        }

        component webhook "WebhookComponents" {
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
                color #000000
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
                background #2e7bb4
                color #ffffff
            }
            element "Component" {
                background #1c5c8a
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}

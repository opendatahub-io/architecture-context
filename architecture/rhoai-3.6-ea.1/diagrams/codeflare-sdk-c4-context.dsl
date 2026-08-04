workspace {
    model {
        user = person "Data Scientist" "Submits and manages distributed compute workloads on Ray clusters"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python SDK for submitting and managing distributed compute workloads on Ray clusters with integrated Kueue queue management" {
            rayJobClient = container "RayJobClient" "Wraps Ray JobSubmissionClient for job submission, monitoring, and lifecycle management" "Python"
            kueueIntegration = container "Kueue Integration" "Queries LocalQueues and WorkloadPriorityClasses, resolves defaults, injects queue labels" "Python"
            authLayer = container "Authentication Layer" "Kubernetes authentication via kube-authkit (Bearer token, kubeconfig, in-cluster)" "Python / kube-authkit"
            certGenerator = container "Certificate Generator" "Generates self-signed CA and keypairs (RSA-3072, SHA-256) for Ray cluster mTLS" "Python / cryptography"
        }

        kubernetesApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        ray = softwareSystem "Ray Cluster" "Distributed compute framework with dashboard endpoint" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queue management via kueue.x-k8s.io/v1beta1" "Internal RHOAI"
        kubeAuthkit = softwareSystem "kube-authkit" "Kubernetes authentication abstraction library" "Internal RHOAI"
        openshiftClient = softwareSystem "openshift-client" "OpenShift-specific Kubernetes operations" "External"

        user -> codeflareSdk "Submits jobs, queries queues, manages workloads"
        codeflareSdk -> kubernetesApi "CRUD operations, Secrets management" "HTTPS/6443"
        codeflareSdk -> ray "Job submission and monitoring" "HTTP/HTTPS"
        codeflareSdk -> kueue "Query LocalQueues, WorkloadPriorityClasses" "via K8s CustomObjects API"

        rayJobClient -> ray "Submit/monitor jobs" "HTTP/HTTPS"
        kueueIntegration -> kueue "Query queues and priority classes" "kueue.x-k8s.io/v1beta1"
        authLayer -> kubernetesApi "Authenticate" "TLS 1.2+ / Bearer token"
        authLayer -> kubeAuthkit "Delegates authentication" "In-process"
        certGenerator -> kubernetesApi "Store TLS certs as Secrets" "HTTPS/6443"
    }

    views {
        systemContext codeflareSdk "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes" {
            rayClusterModule = container "ray.cluster" "RayCluster CR lifecycle management (create, apply, delete, status, wait_ready)" "Python Module"
            rayJobsModule = container "ray.rayjobs" "RayJob CR submission and management with managed cluster support" "Python Module"
            rayClientModule = container "ray.client" "Wrapper around Ray JobSubmissionClient for direct job submission" "Python Module"
            kubeClusterModule = container "common.kubernetes_cluster" "Kubernetes authentication via kube-authkit and API client management" "Python Module"
            kueueModule = container "common.kueue" "Kueue LocalQueue and WorkloadPriorityClass discovery and validation" "Python Module"
            generateCertModule = container "common.utils.generate_cert" "TLS certificate generation for mTLS (RSA 3072-bit, SHA-256)" "Python Module"
            widgetsModule = container "common.widgets" "Jupyter notebook ipywidgets for interactive cluster management UI" "Python Module"
            vendoredClient = container "vendored.python_client" "Vendored KubeRay Python client for RayCluster and RayJob API operations" "Python Module"
        }

        kubeRayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob CRs, creates Ray head/worker pods" "Internal Platform"
        kueue = softwareSystem "Kueue" "Queue management and admission control for Ray clusters" "Internal Platform"
        rhoaiGateway = softwareSystem "RHOAI Gateway (Gateway API)" "Dashboard URL discovery via HTTPRoute in RHOAI 3.x" "Internal Platform"
        openshiftRouter = softwareSystem "OpenShift Router" "Dashboard URL discovery via Routes (legacy)" "Internal Platform"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "CA certificate bundle mounted into Ray cluster pods" "Internal Platform"

        k8sApiServer = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "External"
        rayHeadNode = softwareSystem "Ray Head Node" "Ray cluster head node with dashboard, client, and GCS ports" "External"
        kubeAuthkit = softwareSystem "kube-authkit" "Kubernetes authentication abstraction library" "External"

        # Person relationships
        dataScientist -> codeflareSdk "Creates Ray clusters and submits jobs via" "Python API"

        # SDK to Kubernetes API
        codeflareSdk -> k8sApiServer "CRD CRUD operations (RayCluster, RayJob, Secrets, Kueue, HTTPRoute)" "HTTPS/6443 TLS 1.2+ Bearer Token"

        # SDK to Ray Head
        codeflareSdk -> rayHeadNode "Job submission and monitoring via dashboard" "HTTPS/443 TLS 1.2+ Bearer Token"
        codeflareSdk -> rayHeadNode "Ray client connection for direct job submission" "gRPC/10001 mTLS Client Certificate"

        # SDK dependencies on platform components
        codeflareSdk -> kubeRayOperator "Creates RayCluster and RayJob CRs reconciled by" "K8s API CRD"
        codeflareSdk -> kueue "Reads LocalQueue, Workload, WorkloadPriorityClass for queue mgmt" "K8s API CRD"
        codeflareSdk -> rhoaiGateway "Discovers dashboard URL via HTTPRoute labels" "K8s API CRD"
        codeflareSdk -> openshiftRouter "Discovers dashboard URL via Routes (fallback)" "K8s API CRD"
        codeflareSdk -> kubeAuthkit "Kubernetes authentication abstraction" "Library import"

        # Container relationships
        rayClusterModule -> kubeClusterModule "Uses for K8s auth"
        rayClusterModule -> kueueModule "Uses for queue assignment"
        rayClusterModule -> generateCertModule "Uses for mTLS cert generation"
        rayClusterModule -> vendoredClient "Uses for KubeRay API calls"
        rayJobsModule -> kubeClusterModule "Uses for K8s auth"
        rayJobsModule -> kueueModule "Uses for queue assignment"
        rayJobsModule -> vendoredClient "Uses for KubeRay API calls"
        rayClientModule -> kubeClusterModule "Uses for K8s auth"
        widgetsModule -> rayClusterModule "Wraps cluster operations for Jupyter UI"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for managing Ray clusters and jobs on Kubernetes" {
            clusterModule = container "ray.cluster" "RayCluster lifecycle management — create, apply, delete, monitor" "Python Module"
            rayjobsModule = container "ray.rayjobs" "RayJob lifecycle — submit, stop, resubmit, delete batch jobs" "Python Module"
            clientModule = container "ray.client" "Thin wrapper around Ray JobSubmissionClient" "Python Module"
            k8sAuth = container "kubernetes_cluster" "Multi-method K8s authentication via kube-authkit" "Python Module"
            kueueModule = container "kueue" "LocalQueue discovery and priority validation" "Python Module"
            certGen = container "generate_cert" "mTLS certificate generation (RSA 3072, SHA-256)" "Python Module"
            widgets = container "widgets" "Jupyter ipywidgets for interactive cluster management" "Python Module"
            vendoredClient = container "vendored.python_client" "Vendored KubeRay Python client for CRD CRUD" "Python Module (Vendored)"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob CRs to deploy Ray pods" "Internal Platform"
        kueue = softwareSystem "Kueue" "Batch job queuing and resource management" "Internal Platform"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Gateway API for dashboard URL resolution (RHOAI v3.0+)" "Internal Platform"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "CA certificate bundle ConfigMap mounted in Ray pods" "Internal Platform"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for all resource operations" "External"
        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster (head + workers)" "External"

        # Relationships - External
        dataScientist -> codeflareSDK "Creates clusters and submits jobs via Python API"
        codeflareSDK -> k8sAPI "CRD CRUD operations" "HTTPS/6443, Bearer Token / OIDC"
        codeflareSDK -> rayCluster "Job submission and client connections" "mTLS (8265, 10001, 6379)"

        # Relationships - Internal Platform
        codeflareSDK -> kuberayOperator "Creates RayCluster/RayJob CRs" "via K8s API"
        codeflareSDK -> kueue "Queries LocalQueues, validates priority classes" "via K8s API"
        codeflareSDK -> rhoaiGateway "Discovers dashboard URLs via HTTPRoute/Gateway CRs" "via K8s API"
        kuberayOperator -> rayCluster "Deploys and manages Ray pods"
        kuberayOperator -> k8sAPI "Reconciles CRs"

        # Container-level relationships
        dataScientist -> clusterModule "Cluster(config).apply()"
        dataScientist -> rayjobsModule "RayJob(config).submit()"
        dataScientist -> clientModule "RayJobClient(dashboard_url)"
        widgets -> clusterModule "Interactive buttons"
        clusterModule -> k8sAuth "Authentication"
        clusterModule -> kueueModule "Queue labels"
        clusterModule -> certGen "mTLS certs"
        rayjobsModule -> k8sAuth "Authentication"
        rayjobsModule -> kueueModule "Queue labels"
        rayjobsModule -> vendoredClient "CRD CRUD ops"
        k8sAuth -> k8sAPI "Bearer Token / OIDC / kubeconfig" "HTTPS/6443"
        certGen -> k8sAPI "Read CA Secret" "HTTPS/6443"
        clientModule -> rayCluster "Job submission" "HTTPS/8265 mTLS"
    }

    views {
        systemContext codeflareSDK "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSDK "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
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
        }
    }
}

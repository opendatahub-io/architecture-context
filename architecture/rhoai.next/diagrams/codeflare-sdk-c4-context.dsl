workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks or Python scripts"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for requesting, managing, and interacting with Ray clusters and Ray jobs on Kubernetes" {
            clusterModule = container "ray.cluster" "Manages RayCluster CR lifecycle (apply, down, status, wait_ready)" "Python Module"
            rayjobsModule = container "ray.rayjobs" "Manages RayJob CR lifecycle (submit, stop, resubmit, delete)" "Python Module"
            rayClientModule = container "ray.client" "Thin wrapper around Ray JobSubmissionClient for direct job submission" "Python Module"
            authModule = container "common.kubernetes_cluster" "Kubernetes authentication via kube-authkit (OIDC, OAuth, token, kubeconfig)" "Python Module"
            kueueModule = container "common.kueue" "Kueue LocalQueue and WorkloadPriorityClass discovery and validation" "Python Module"
            certModule = container "common.utils.generate_cert" "TLS certificate generation (RSA-3072, SHA-256) for mTLS Ray connections" "Python Module"
            widgetsModule = container "common.widgets" "ipywidgets-based Jupyter notebook UI for cluster management" "Python Module"
            vendoredClient = container "vendored.python_client" "KubeRay Python client (RayClusterApi, RayjobApi)" "Vendored Library"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob custom resources, creates Pods, Services, CA Secrets" "External"
        kueueController = softwareSystem "Kueue Controller" "Queue-based scheduling and resource quota management" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD operations, Secret management, RBAC enforcement" "External"
        rayCluster = softwareSystem "Ray Cluster" "Distributed computing cluster with head node (10001/TCP, 8265/TCP) and workers" "External"
        gatewayAPI = softwareSystem "RHOAI Gateway (Gateway API)" "HTTPRoute-based ingress for Ray dashboard access (RHOAI 3.x)" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route-based ingress for Ray dashboard access (pre-3.x)" "External"
        workbench = softwareSystem "RHOAI/ODH Workbench" "Jupyter notebook environment where SDK runs" "Internal RHOAI"
        notebooksRepo = softwareSystem "odh-notebooks" "Notebook images that include the SDK as a dependency" "Internal ODH"

        # User interactions
        user -> codeflareSDK "Creates clusters, submits jobs via Python API"
        user -> workbench "Runs Jupyter notebooks"

        # SDK to external systems
        codeflareSDK -> k8sAPI "CRD CRUD, Secret R/W, Service list" "HTTPS/6443 TLS 1.2+"
        codeflareSDK -> rayCluster "Job submission, cluster connection" "Ray Client/10001 mTLS"
        codeflareSDK -> rayCluster "Dashboard readiness check, job listing" "HTTPS/8265 TLS 1.2+"

        # Platform integrations
        k8sAPI -> kuberayOperator "Watch events for RayCluster/RayJob CRs"
        k8sAPI -> kueueController "Watch events for Workloads"
        gatewayAPI -> rayCluster "Proxy dashboard traffic" "HTTPS/443"
        openshiftRoutes -> rayCluster "Proxy dashboard traffic" "HTTPS/443"
        codeflareSDK -> gatewayAPI "Discover dashboard URL via HTTPRoute" "HTTPS/6443 (via K8s API)"
        codeflareSDK -> openshiftRoutes "Discover dashboard URL via Route" "HTTPS/6443 (via K8s API)"

        # Build/distribution
        notebooksRepo -> codeflareSDK "Includes as pip dependency in workbench images"

        # Internal container relationships
        clusterModule -> authModule "authenticates"
        clusterModule -> kueueModule "discovers queues"
        clusterModule -> certModule "generates TLS certs"
        rayjobsModule -> authModule "authenticates"
        rayjobsModule -> kueueModule "validates priority"
        rayjobsModule -> vendoredClient "CRD operations"
        rayClientModule -> authModule "authenticates"
        widgetsModule -> clusterModule "manages clusters"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal ODH" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Vendored Library" {
                background #d4a574
                color #333333
            }
        }
    }
}

workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters and jobs from Jupyter notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for RayCluster and RayJob lifecycle management on Kubernetes/OpenShift" {
            clusterAPI = container "Cluster API" "High-level Python API for RayCluster lifecycle (apply, down, status, dashboard)" "Python Module"
            rayJobAPI = container "RayJob API" "High-level Python API for RayJob submission and monitoring" "Python Module"
            rayJobClient = container "RayJobClient" "Ray dashboard-based job submission client" "Python Module"
            authModule = container "Auth Module" "Kubernetes authentication via kube-authkit (auto-detect, OIDC, OAuth, token)" "Python Module"
            tlsGenerator = container "TLS Cert Generator" "Generates mTLS client certs from KubeRay CA secrets (RSA-3072, SHA-256)" "Python Module"
            kueueUtils = container "Kueue Utilities" "Queue discovery, validation, and admission status checking" "Python Module"
            jupyterWidgets = container "Jupyter Widgets" "Interactive ipywidgets for cluster management in notebooks" "Python Module"
            kuberayClient = container "Vendored KubeRay Client" "Thin wrapper around CustomObjectsApi for RayCluster/RayJob CRUD" "Python Module"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster and RayJob CRs into running Ray clusters" "Internal RHOAI"
        kueueController = softwareSystem "Kueue" "Workload queuing and admission control with priority scheduling" "Internal RHOAI"
        rhoaiGateway = softwareSystem "RHOAI Gateway" "Gateway API (HTTPRoute) for Ray dashboard URL routing" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "OpenShift Route-based ingress (fallback for dashboard access)" "Internal OpenShift"
        k8sAPIServer = softwareSystem "Kubernetes API Server" "Kubernetes control plane API for CRD and resource management" "External"
        rayHead = softwareSystem "Ray Head Service" "Ray cluster head node providing client and dashboard endpoints" "Runtime"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "Custom CA trust bundle mounted into Ray pods" "Internal RHOAI"

        # User interactions
        dataScientist -> codeflareSDK "Creates clusters, submits jobs via Python API"

        # SDK to Kubernetes API
        codeflareSDK -> k8sAPIServer "Creates/manages RayCluster, RayJob CRs; queries Kueue, Gateway, Route resources" "HTTPS/6443"

        # SDK to Ray
        codeflareSDK -> rayHead "Interactive Ray client connections" "mTLS/10001"
        codeflareSDK -> rayHead "Job submission via Ray dashboard API" "HTTP/8265"

        # SDK to dashboard via gateway
        codeflareSDK -> rhoaiGateway "Dashboard URL resolution and access" "HTTPS/443"

        # Operator interactions (via K8s API)
        kuberayOperator -> k8sAPIServer "Watches and reconciles ray.io/v1 CRs" "HTTPS/6443"
        kueueController -> k8sAPIServer "Manages workload admission" "HTTPS/6443"

        # KubeRay creates runtime resources
        kuberayOperator -> rayHead "Creates and manages Ray head/worker pods" "Internal"

        # Fallback route
        codeflareSDK -> openshiftRouter "Dashboard URL fallback (pre-3.x)" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal OpenShift" {
                background #50e3c2
                color #333333
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}

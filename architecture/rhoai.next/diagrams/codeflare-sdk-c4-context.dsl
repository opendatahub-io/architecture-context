workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed ML workloads from Jupyter notebooks or Python environments"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for requesting, managing, and monitoring Ray clusters and batch computing resources on Kubernetes/OpenShift" {
            clusterModule = container "Cluster Module" "Core Cluster object for creating, scaling, and deleting RayCluster/AppWrapper CRs" "Python (codeflare_sdk.ray.cluster)"
            rayJobClient = container "RayJobClient" "Wrapper around Ray JobSubmissionClient for job submission and monitoring" "Python (codeflare_sdk.ray.client)"
            awManager = container "AWManager" "Manages AppWrapper YAML submission and removal" "Python (codeflare_sdk.ray.appwrapper)"
            authHelpers = container "Auth Helpers" "TokenAuthentication and KubeConfigFileAuthentication for Kubernetes API access" "Python (codeflare_sdk.common.kubernetes_cluster)"
            kueueIntegration = container "Kueue Integration" "LocalQueue discovery and validation for resource quota management" "Python (codeflare_sdk.common.kueue)"
            certGenerator = container "TLS Certificate Generator" "Generates CA and client certificates for secure Ray client mTLS connections" "Python (codeflare_sdk.common.utils.generate_cert)"
            jupyterWidgets = container "Jupyter Widgets" "Interactive notebook UI widgets for cluster management via ipywidgets" "Python (codeflare_sdk.common.widgets)"
            yamlGenerator = container "YAML Generator" "Generates RayCluster CR YAML from configuration and base template" "Python (codeflare_sdk.ray.cluster.generate_yaml)"
        }

        k8sAPIServer = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD operations, authentication, and authorization" "External"
        kubeRayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into Ray head and worker pods" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator / AppWrapper Controller" "Reconciles AppWrapper CRs for Kueue-managed workloads" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Resource quota management and fair scheduling via LocalQueues" "Internal RHOAI"
        rayHeadNode = softwareSystem "Ray Head Node" "Ray cluster head providing dashboard API (8265/TCP) and client protocol (10001/TCP)" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external access to Ray dashboard via Routes" "External"
        rhoaiWorkbench = softwareSystem "RHOAI Workbench" "Notebook environment where SDK runs client-side" "Internal RHOAI"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "ConfigMap providing CA certificates for TLS trust in Ray pods" "Internal RHOAI"

        # User interactions
        dataScientist -> codeflareSDK "Creates clusters, submits jobs, monitors status via Python API"
        dataScientist -> rhoaiWorkbench "Develops in Jupyter notebooks"

        # SDK internal relationships
        clusterModule -> yamlGenerator "Generates RayCluster YAML"
        clusterModule -> awManager "Wraps in AppWrapper (optional)"
        clusterModule -> rayJobClient "Submits and monitors jobs"
        clusterModule -> authHelpers "Authenticates to Kubernetes"
        clusterModule -> kueueIntegration "Queries LocalQueues"
        clusterModule -> certGenerator "Generates TLS certs for mTLS"
        jupyterWidgets -> clusterModule "Manages clusters interactively"

        # External interactions
        codeflareSDK -> k8sAPIServer "CRD CRUD, Secret reads, Route/Ingress reads" "HTTPS/6443 Bearer Token"
        codeflareSDK -> rayHeadNode "Job submission, status monitoring" "HTTP(S)/8265"
        codeflareSDK -> rayHeadNode "Interactive Ray client sessions" "TCP/10001 mTLS"
        codeflareSDK -> openshiftRouter "Dashboard URL discovery" "HTTPS/443"

        # Operator relationships
        kubeRayOperator -> k8sAPIServer "Watches RayCluster CRs" "HTTPS/6443"
        kubeRayOperator -> rayHeadNode "Creates and manages Ray pods"
        codeflareOperator -> k8sAPIServer "Watches AppWrapper CRs" "HTTPS/6443"

        # Platform relationships
        rhoaiWorkbench -> codeflareSDK "Hosts SDK runtime (pip install codeflare-sdk)"
        odhCABundle -> rayHeadNode "Mounted as CA trust chain in Ray pods"
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
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

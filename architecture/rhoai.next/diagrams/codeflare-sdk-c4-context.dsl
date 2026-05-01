workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for ML workloads via Jupyter Notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for creating, managing, and monitoring Ray clusters on Kubernetes" {
            clusterModule = container "Cluster Module" "Core cluster lifecycle management — create, apply, monitor, delete RayCluster/AppWrapper CRs" "Python Module"
            appwrapperModule = container "AppWrapper Module" "AppWrapper submission/deletion via AWManager, status tracking" "Python Module"
            clientModule = container "Ray Client Module" "Wrapper around Ray JobSubmissionClient for job submission and monitoring" "Python Module"
            k8sAuth = container "Kubernetes Auth" "Token and KubeConfig authentication, API error handling" "Python Module"
            kueueModule = container "Kueue Module" "LocalQueue discovery, default queue resolution, queue label injection" "Python Module"
            certGen = container "Certificate Generator" "TLS CA and client certificate generation for Ray cluster mTLS connections" "Python Module"
            widgets = container "Jupyter Widgets" "ipywidgets-based UI for interactive cluster management in notebooks" "Python Module"
            baseTemplate = container "Base Template" "RayCluster CR YAML template used as basis for generation" "YAML Template"
        }

        kubeRay = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into head/worker pods and services" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Reconciles AppWrapper CRs for gang scheduling of RayCluster resources" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Resource quota management and fair scheduling via LocalQueues" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Routes external traffic to internal services via Routes" "OpenShift Platform"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane API for all resource CRUD operations" "OpenShift Platform"
        rhoaiWorkbench = softwareSystem "RHOAI Workbench" "Jupyter Notebook workbench where the SDK runs as a library dependency" "Internal RHOAI"
        trustedCABundle = softwareSystem "ODH Trusted CA Bundle" "ConfigMap with custom CA trust chain mounted into generated Ray pods" "Internal RHOAI"
        imageRegistry = softwareSystem "Container Image Registry" "quay.io/modh/ray — Ray container images referenced in generated specs" "External"

        # Relationships
        dataScientist -> codeflareSDK "Creates clusters, submits jobs via Python API"
        dataScientist -> rhoaiWorkbench "Accesses Jupyter Notebook"
        rhoaiWorkbench -> codeflareSDK "Hosts SDK as a pip dependency"

        codeflareSDK -> k8sAPI "CRUD RayCluster, AppWrapper CRs; READ LocalQueue, Route, Secret, Ingress" "HTTPS/6443 Bearer Token"
        codeflareSDK -> kubeRay "Creates RayCluster CRs that KubeRay reconciles" "via K8s API CRD"
        codeflareSDK -> codeflareOperator "Optionally creates AppWrapper CRs for gang scheduling" "via K8s API CRD"
        codeflareSDK -> kueue "Discovers LocalQueues, labels resources for queue assignment" "via K8s API CRD"
        codeflareSDK -> openshiftRouter "Reads Routes to discover Ray Dashboard endpoint URLs" "via K8s API"

        # Internal container relationships
        clusterModule -> baseTemplate "Generates YAML from template"
        clusterModule -> k8sAuth "Authenticates to cluster"
        clusterModule -> appwrapperModule "Optionally wraps RayCluster"
        clusterModule -> kueueModule "Labels for queue assignment"
        clusterModule -> certGen "TLS cert generation"
        clientModule -> clusterModule "Discovers Ray endpoint"
        widgets -> clusterModule "Manages cluster lifecycle"
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
                color #333333
            }
            element "OpenShift Platform" {
                background #ee0000
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
                color #333333
            }
        }
    }
}

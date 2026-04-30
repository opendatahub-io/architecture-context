workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters for ML workloads via Jupyter Notebooks"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for creating, managing, and monitoring Ray clusters on Kubernetes" {
            clusterModule = container "ray.cluster" "Core cluster lifecycle management - create, apply, monitor, delete RayCluster/AppWrapper CRs" "Python Module"
            appwrapperModule = container "ray.appwrapper" "AppWrapper submission/deletion via AWManager, status tracking" "Python Module"
            clientModule = container "ray.client" "Wrapper around Ray JobSubmissionClient for job submission and monitoring" "Python Module"
            kubeAuth = container "common.kubernetes_cluster" "Kubernetes authentication (Token, KubeConfig) and API error handling" "Python Module"
            kueueModule = container "common.kueue" "Kueue LocalQueue discovery, default queue resolution, queue label injection" "Python Module"
            certGen = container "common.utils.generate_cert" "TLS CA and client certificate generation for Ray cluster mTLS" "Python Module"
            widgets = container "common.widgets" "Jupyter Notebook UI widgets (ipywidgets) for interactive cluster management" "Python Module"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for CRD management" "External"
        kubeRay = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into head/worker pods" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "AppWrapper controller for gang scheduling via Kueue" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Resource quota management and workload scheduling" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing Routes to Ray dashboard" "External"
        rayCluster = softwareSystem "Ray Cluster" "Distributed compute cluster with dashboard and client endpoints" "Internal RHOAI"
        imageRegistry = softwareSystem "Container Image Registry" "quay.io/modh/ray - Ray container images" "External"
        workbench = softwareSystem "RHOAI Workbench" "Jupyter Notebook environment where SDK runs" "Internal RHOAI"

        user -> codeflareSDK "Uses SDK to create/manage Ray clusters"
        user -> workbench "Works in Jupyter Notebook"
        codeflareSDK -> k8sAPI "CRUD on CRDs, Secrets, Routes" "HTTPS/6443, Bearer Token"
        codeflareSDK -> rayCluster "Submit jobs, interactive sessions" "HTTPS/443 + gRPC/10001"
        k8sAPI -> kubeRay "RayCluster CR reconciliation" "Internal"
        k8sAPI -> codeflareOperator "AppWrapper CR reconciliation" "Internal"
        k8sAPI -> kueue "LocalQueue/Workload management" "Internal"
        kubeRay -> rayCluster "Creates head/worker pods" "Internal"
        openshiftRouter -> rayCluster "Routes traffic to Ray dashboard" "HTTPS/443 -> HTTP/8265"
        rayCluster -> imageRegistry "Pulls Ray container images" "HTTPS/443"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5ba0f2
                color #ffffff
            }
        }
    }
}

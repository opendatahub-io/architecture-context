workspace {
    model {
        user = person "Data Scientist" "Creates distributed ML training workloads (RayClusters, PyTorchJobs, AppWrappers)"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Kubernetes operator managing AppWrapper CRs and RayCluster lifecycle with admission webhooks, Kueue quota integration, and multi-framework distributed workload orchestration" {
            manager = container "codeflare-operator-manager" "Main operator deployment running controllers and webhooks" "Go Operator (controller-runtime 0.20.3)"
            rayClusterReconciler = container "RayCluster Reconciler" "Watches RayClusters, owns Services/SAs/Ingresses/NetworkPolicies/Routes" "Go Controller"
            appWrapperController = container "AppWrapper Controller" "Manages AppWrapper CRD lifecycle with Kueue quota integration" "Go Controller"
            webhookServer = container "Webhook Server" "Mutating and validating admission webhooks for AppWrapper and RayCluster" "HTTPS/9443 TLS"
            metricsEndpoint = container "Metrics Endpoint" "Prometheus metrics" "TCP/8080"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        kueue = softwareSystem "Kueue" "Quota management and workload admission" "External"
        kubeRay = softwareSystem "KubeRay" "RayCluster and RayJob CRD provider" "External"
        kubeflow = softwareSystem "Kubeflow Training Operator" "PyTorchJob CRD provider" "External"
        dsci = softwareSystem "DSCInitialization" "RHOAI platform initialization state" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "RHOAI platform operator (Go library)" "Internal RHOAI"
        openShift = softwareSystem "OpenShift" "Routes and ingress configuration" "External"

        user -> codeflareOperator "Creates AppWrapper/RayCluster CRs via kubectl"
        codeflareOperator -> kubernetesAPI "CRUD on cluster resources (HTTPS/6443, ServiceAccount token)" "HTTPS/6443"
        codeflareOperator -> kueue "PodSetInfos quota integration (labels, annotations, nodeSelectors, tolerations, schedulingGates)"
        codeflareOperator -> kubeRay "Manages RayClusters and RayJobs" "Kubernetes API"
        codeflareOperator -> kubeflow "Manages PyTorchJobs" "Kubernetes API"
        codeflareOperator -> dsci "Reads platform initialization state" "Kubernetes API"
        codeflareOperator -> odhOperator "Uses runtime packages" "Go library"
        codeflareOperator -> openShift "Creates Routes, reads ingress config" "Kubernetes API"
        kubernetesAPI -> codeflareOperator "Admission webhook calls (HTTPS/9443, TLS)" "HTTPS/9443"
    }

    views {
        systemContext codeflareOperator "SystemContext" {
            include *
            autoLayout
        }

        container codeflareOperator "Containers" {
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

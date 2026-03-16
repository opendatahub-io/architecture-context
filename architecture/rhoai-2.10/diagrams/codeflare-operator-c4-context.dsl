workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed AI/ML workloads using Ray and Kueue"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster and AppWrapper lifecycle for distributed AI/ML workloads" {
            manager = container "Operator Manager" "Reconciles RayCluster and AppWrapper resources, manages OAuth, mTLS, network policies" "Go Operator" {
                rayController = component "RayCluster Controller" "Watches RayCluster CRs, creates NetworkPolicies, Routes/Ingress, Services, Secrets" "Go Controller"
                appWrapperController = component "AppWrapper Controller" "Manages AppWrapper CRs, integrates with Kueue for workload scheduling" "Go Controller"
            }
            webhookServer = container "Webhook Server" "Validates and mutates AppWrapper and RayCluster resources" "Go Admission Webhook"
            metricsServer = container "Metrics Server" "Exposes Prometheus metrics for operator monitoring" "Go HTTP Service"
        }

        kubeRayOperator = softwareSystem "KubeRay Operator" "Provides RayCluster CRD and base Ray cluster management" "External - Ray Community"
        kueue = softwareSystem "Kueue" "Provides workload scheduling and resource quota management" "External - Kubernetes SIG"
        certController = softwareSystem "cert-controller" "Manages webhook TLS certificate rotation" "External - Red Hat"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Platform"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        oauthProxy = softwareSystem "OAuth Proxy" "OpenShift OAuth authentication for Ray dashboards" "Platform - OpenShift Only"

        odhDashboard = softwareSystem "ODH Dashboard" "OpenDataHub/RHOAI web UI for data science workflows" "Internal ODH/RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "OpenDataHub platform operator" "Internal ODH/RHOAI"
        dataSciencePipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflow orchestration" "Internal ODH/RHOAI"

        rayCluster = softwareSystem "Ray Cluster" "Distributed computing framework for ML/AI workloads" "User Workload"

        // User interactions
        dataScientist -> codeflareOperator "Creates RayCluster and AppWrapper resources via kubectl/SDK"
        dataScientist -> rayCluster "Submits distributed ML/AI jobs" "Ray Python SDK"
        dataScientist -> odhDashboard "Manages data science projects and workloads" "HTTPS/443"

        // Operator dependencies
        codeflareOperator -> kubernetesAPI "Watches CRDs, creates resources (Pods, Services, NetworkPolicies, Routes/Ingress)" "HTTPS/443, ServiceAccount Token"
        codeflareOperator -> kubeRayOperator "Uses RayCluster CRD and relies on base Ray lifecycle management" "CRD Dependency"
        codeflareOperator -> kueue "Creates Workload CRs for AppWrapper scheduling and quota management" "HTTPS/443, ServiceAccount Token"
        codeflareOperator -> certController "Uses for webhook certificate rotation" "Certificate Management"
        codeflareOperator -> oauthProxy "Injects as sidecar for Ray dashboard authentication (OpenShift)" "Sidecar Injection"
        codeflareOperator -> odhOperator "Reads DSCInitialization for platform configuration" "HTTPS/443, CRD Watch"

        // Monitoring
        prometheus -> codeflareOperator "Scrapes operator metrics" "HTTP/8080, Bearer Token"

        // Integration points
        odhDashboard -> codeflareOperator "Triggers RayCluster creation for distributed workloads" "Kubernetes API"
        dataSciencePipelines -> codeflareOperator "Auto-deploys RayCluster for distributed training pipelines" "Kubernetes API"

        // Operator creates Ray clusters
        codeflareOperator -> rayCluster "Creates and manages Ray Head and Worker Pods with mTLS, OAuth, NetworkPolicies" "HTTPS/443"
        kubeRayOperator -> rayCluster "Deploys base Ray cluster infrastructure" "HTTPS/443"
        kueue -> codeflareOperator "Updates Workload admission status for AppWrapper scheduling" "HTTPS/443"
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

        component manager "Components" {
            include *
            autoLayout
        }

        styles {
            element "External - Ray Community" {
                background #999999
                color #ffffff
            }
            element "External - Kubernetes SIG" {
                background #999999
                color #ffffff
            }
            element "External - Red Hat" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #cccccc
                color #000000
            }
            element "Platform - OpenShift Only" {
                background #cccccc
                color #000000
            }
            element "Internal ODH/RHOAI" {
                background #7ed321
                color #000000
            }
            element "User Workload" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Component" {
                shape Component
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
